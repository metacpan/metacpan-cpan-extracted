package Data::Consumer::Dir;

use warnings;
use strict;
use DBI;
use Carp qw(confess);
use warnings FATAL => 'all';
use base 'Data::Consumer';
use File::Spec;
use File::Path;
use Fcntl;
use Fcntl ':flock';
use vars qw/$Debug $VERSION $Cmd $Fail/;

# This code was formatted with the following perltidy options:
# -ple -ce -bbb -bbc -bbs -nolq -l=100 -noll -nola -nwls='=' -isbc -nolc -otr -kis
# If you patch it please use the same options for your patch.

*Debug= *Data::Consumer::Debug;
*Cmd= *Data::Consumer::Cmd;
*Fail= *Data::Consumer::Fail;

BEGIN {
    __PACKAGE__->register();
}

=head1 NAME

Data::Consumer::Dir - Data::Consumer implementation for a directory of files resource

=head1 VERSION

Version 0.16

=cut

$VERSION= '0.16';

=head1 SYNOPSIS

    use Data::Consumer::Dir;

    my $consumer = Data::Consumer::Dir->new(
        root      => '/some/dir',
        create    => 1,
        open_mode => '+<',
    );

    $consumer->consume( sub {
        my $id = shift;
        print "processed $id\n";
    } );


=head1 FUNCTIONS

=head2 CLASS->new(%opts)

Constructor for a L<Data::Consumer::Dir> instance.

Either the C<root> option must be provided or both C<unprocessed> and
C<processed> arguments must be defined. Will die if the directories do
not exist unless the C<create> option is set to a true value.

=over 4

=item unprocessed => $path_spec

Directory within which unprocessed files will be found.

May also be a callback which is responsible for marking the item as
unprocessed.  This will be called with the arguments C<($consumer,
'unprocessed', $spec, $fh, $name)>.

=item working => $path_spec

Files will be moved to this directory prior to be processed.

May also be a callback which is responsible for marking the item as
working.  This will be called with the arguments C<($consumer,
'working', $spec, $fh, $name)>.

=item processed => $path_spec

Once successfully processed the files will be moved to this directory.

May also be a callback which is responsible for marking the item as
processed.  This will be called with the arguments C<($consumer,
'processed', $spec, $fh, $name)>.

=item failed => $path_spec

If processing fails then the files will be moved to this directory.

May also be a callback which is responsible for marking the item as
failed.  This will be called with the arguments C<($consumer, 'failed',
$spec, $fh, $name)>.

=item root => $path_spec

Automatically creates any of the C<unprocessed>, C<working>,
C<processed>, or C<failed> directories below a specified C<root>. Only
those directories not explicitly defined will be automatically created
so this can be used in conjunction with the other options.

=item create => $bool

=item create_mode => $mode_flags

If true then directories specified by not existing will be created.
If C<create_mode> is specified then the directories will be created with that mode.

=item open_mode => $mode_str

In order to lock a file a filehandle must be opened, normally in
read-only mode (C<< < >>), however it may be useful to open with other
modes.

=back

=cut

BEGIN {
    my @keys= qw(unprocessed working processed failed);
    my %m= (
        '<'   => O_RDONLY,
        '+<'  => O_RDWR,
        '>>'  => O_APPEND | O_WRONLY,
        '+>>' => O_APPEND | O_RDWR,
    );
    $_= $_ | O_NONBLOCK for values %m;

    sub new {
        my ( $class, %opts )= @_;
        my $self= $class->SUPER::new();    # let Data::Consumer bless the hash

        if ( $opts{root} ) {
            my ( $v, $p )= File::Spec->splitpath( $opts{root}, 'nofile' );
            for my $type (@keys) {
                $opts{$type} ||= File::Spec->catpath( $v, File::Spec->catdir( $p, $type ), '' );
            }
        }
        ( $opts{unprocessed} and $opts{processed} )
          or confess "Arguments 'unprocessed' and 'processed' are mandatory";

        if ( $opts{create} ) {
            for (@keys) {
                next unless exists $opts{$_};
                next if -d $opts{$_};
                mkpath( $opts{$_}, $Debug, $opts{create_mode} || () );
            }
        }
        if ( $opts{open_mode} ) {
            exists $m{ $opts{open_mode} }
              or confess "Illegal open mode '$opts{open_mode}' legal options are "
              . join( ',', map { "'$_'" } sort keys %m ) . "\n";
            $opts{open_mode}= $m{ $opts{open_mode} };
        } else {
            $opts{open_mode}= O_RDONLY | O_NONBLOCK;
        }

        %$self= %opts;
        return $self;
    }
}

=head2  $object->reset()

Reset the state of the object.

=head2 $object->acquire()

Acquire an item to be processed.

Returns an identifier to be used to identify the item acquired.

=head2 $object->release()

Release any locks on the currently held item.

Normally there is no need to call this directly.

=cut

sub reset {
    my $self= shift;
    $self->debug_warn( 5, "reset (scanning $self->{unprocessed})" );
    $self->release();
    opendir my $dh, $self->{unprocessed}
      or die "Failed to opendir '$self->{unprocessed}': $!";
    my @files= map { /(.*)/s && $1 } readdir($dh);

    #print for @files;
    @files= sort grep { -f _cf( $self->{unprocessed}, $_ ) } @files;
    $self->{files}= \@files;
    return $self;
}

sub _cf {    # cat file
    my ( $r, $f )= @_;

    my ( $v, $p )= File::Spec->splitpath( $r, 'nofile' );
    return File::Spec->catpath( $v, $p, $f );
}

sub _do_callback {
    my ( $self, $callback )= @_;
    local $Fail;
    if ( eval { $callback->( $self, @{$self}{qw(lock_spec lock_fh last_id)} ); 1; } ) {
        if ($Fail) {
            return "Callback reports an error: $Fail";
        }
        return;
    } else {
        return "Callback failed: $@";
    }
}

sub acquire {
    my $self= shift;
    my $dbh= $self->{dbh};

    $self->reset if !@{ $self->{files} || [] };

    my $files= $self->{files};
    while (@$files) {
        my $file= shift @$files;
        next if $self->is_ignored($file);
        my $spec= _cf( $self->{unprocessed}, $file );
        my $fh;
        if ( sysopen $fh, $spec, $self->{open_mode} and flock( $fh, LOCK_EX | LOCK_NB ) ) {
            $self->{lock_fh}= $fh;
            $self->{lock_spec}= $spec;
            $self->debug_warn( 5, "acquired '$file': $spec" );
            $self->{last_id}= $file;
            return $file;
        }
    }
    $self->debug_warn( 5, "acquire failed -- resource has been exhausted" );
    return;
}

sub release {
    my $self= shift;

    flock( $self->{lock_fh}, LOCK_UN ) if $self->{lock_fh};
    delete $self->{lock_fh};
    delete $self->{lock_spec};
    delete $self->{last_id};
    return 1;
}

=head2 $object->fh()

Return a filehandle to the currently acquired item. See the C<open_mode>
argument in C<new()> for details on how to control the mode that the
filehandle is opened with.

=head2 $object->spec()

Return the full filespec for the currently acquired item. 

=head2 $object->file()

Return the filename (without path) of the currently acquired item. 

Note that this is an alias for C<< $object->last_id() >>.

=cut

sub fh   { $_[0]->{lock_fh} }
sub spec { $_[0]->{lock_spec} }
sub file { $_[0]->{last_id} }

sub _mark_as {
    my ( $self, $key, $id )= @_;

    if ( $self->{$key} ) {
        if ( ref $self->{$key} ) {

            # assume it must be a callback
            $self->debug_warn( 5, "executing mark_as callback for '$key'" );
            $self->{$key}->( $self, $key, $self->{lock_spec}, $self->{lock_fh}, $self->{last_id} );
            return;
        }
        my $spec= _cf( $self->{$key}, $self->{last_id} );
        rename $self->{lock_spec}, $spec
          or confess "$$: Failed to rename '$self->{lock_spec}' to '$spec':$!";
        $self->{lock_spec}= $spec;
    }
}

sub DESTROY {
    my $self= shift;
    $self->release() if $self;
}

=head1 AUTHOR

Yves Orton, C<< <YVES at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-consumer at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Consumer>.

I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Igor Sutton <IZUT@cpan.org> for ideas, testing and support

=head1 COPYRIGHT & LICENSE

Copyright 2008 Yves Orton, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Data::Consumer::Dir

