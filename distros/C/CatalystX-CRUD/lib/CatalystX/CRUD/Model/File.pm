package CatalystX::CRUD::Model::File;
use strict;
use warnings;
use base qw( CatalystX::CRUD::Model );
use File::Find;
use Carp;
use Data::Dump qw( dump );
use Path::Class;
use mro 'c3';

__PACKAGE__->mk_accessors(qw( inc_path ));

our $VERSION = '0.57';

# test whether symlink() works at compile time
my $SYMLINK_SUPPORTED = eval { symlink( "", "" ); 1 };

=head1 NAME

CatalystX::CRUD::Model::File - filesystem CRUD model

=head1 SYNOPSIS

 package MyApp::Model::Foo;
 use base qw( CatalystX::CRUD::Model::File );
 __PACKAGE__->config( 
    object_class    => 'MyApp::File',
    delegate_class  => 'Path::Class::File', # optional
    inc_path        => [ '/some/path', '/other/path' ],
 );
 
 1;
 
=head1 DESCRIPTION

CatalystX::CRUD::Model::File is an example implementation 
of CatalystX::CRUD::Model.

=head1 METHODS

Only new or overridden methods are documented here.

=cut

=head2 Xsetup

Implements the CXC::Model API. 
Sets the inc_path() (if not already set)
to the C<root> config value.

=cut

sub Xsetup {
    my ( $self, $c ) = @_;
    $self->{inc_path} ||= [ $c->config->{root} ];
    if ( $self->config->{delegate_class} ) {
        $self->object_class->delegate_class(
            $self->config->{delegate_class} );
    }
    $self->next::method($c);
}

=head2 new_object( file => I<path/to/file> )

Return a new CatalystX::CRUD::Object::File object.

=cut

=head2 fetch( file => I<path/to/file> )

Read I<path/to/file> from disk and return a CXCO::File object.

I<path/to/file> is assumed to be in C<inc_path>

If I<path/to/file> is empty, the
CatalystX::CRUD::Object::File object is returned but its content()
will be undef. If its parent dir is '.', its dir() 
will be set to the first item in inc_path().

If I<path/to/file> is not found, undef is returned.

=cut

sub fetch {
    my $self = shift;
    my $file = $self->new_object(@_);
    $file = $self->prep_new_object($file);
    return defined -s $file ? $file : undef;
}

=head2 prep_new_object( I<file> )

Searches inc_path() and calls I<file> read() method
if file is found.

Also verifies that the delegate() has an absolute path set.

Called internally by fetch().

Returns I<file>.

=cut

sub prep_new_object {
    my $self = shift;
    my $file = shift or croak "file required";

    # look through inc_path
    for my $dir ( @{ $self->inc_path } ) {
        my $test = $self->object_class->delegate_class->new( $dir, $file );

        if ( -s $test ) {
            $file->{delegate} = $test;
            $file->read;
            last;
        }
    }

    #carp dump $file;

    # make sure delegate() has absolute path
    # while file() is relative to inc_path.
    if ( $file->dir eq '.' or !$file->dir->is_absolute ) {
        $file->{delegate}
            = $self->object_class->delegate_class->new( $self->inc_path->[0],
            $file );
    }

    #carp dump $file;
    return $file;
}

=head2 inc_path

Returns the include path from config(). The include path is searched
by search(), count() and iterator().

=cut

=head2 make_query

Returns a I<wanted> subroutine suitable for File::Find.

 # TODO regex vs exact match
 
=cut

sub make_query {
    my ($self) = @_;
    return sub {
        my ( $root, $dir, $f ) = @_;
        return 0
            if $dir and $dir =~ m!/\.(svn|git)!;
        return 1;
    };
}

=head2 search( I<filter_CODE> )

Uses File::Find to search through inc_path() for files.
I<filter_CODE> should be a CODE ref matching format returned by make_query().
If not set, make_query() is called by default.

Returns an array ref of CXCO::File objects.

=cut

sub _find {
    my ( $self, $filter_sub, $root ) = @_;
    my %files;
    my $del_class = $self->object_class->delegate_class;
    my $find_sub  = sub {

        #warn "File::Find::Dir = $File::Find::dir";
        #warn "file = $_";
        #warn "name = $File::Find::name";

        my $dir = Path::Class::dir($File::Find::dir);
        my $f   = Path::Class::file($File::Find::name);
        return if $dir eq $f;

        return unless $filter_sub->( $root, $dir, $f );

        # we want the file path relative to $root
        # since that is the PK
        my $rel = $dir->relative($root);
        $rel =~ s!^\./!!;
        my $key = $del_class->new( $rel, $_ );

        #warn "$key => $f";

        $files{$key} = $f if -f $f;
    };
    find(
        {   follow => 1,
            wanted => $find_sub,
        },
        $root
    );
    return \%files;
}

sub search {
    my $self = shift;
    my $filter_sub = shift || $self->make_query;
    my @objects;
    for my $root ( @{ $self->inc_path } ) {
        my $files = $self->_find( $filter_sub, $root );
        for my $relative ( sort keys %$files ) {
            my $obj = $self->new_object(
                file     => $relative,
                delegate => $files->{$relative}
            );
            $obj->read;    # just like fetch()
            push @objects, $obj;
        }
    }
    return \@objects;
}

=head2 count( I<filter_CODE> )

Returns number of files matching I<filter_CODE>. See search for a description
of I<filter_CODE>.

=cut

sub count {
    my $self       = shift;
    my $filter_sub = shift || $self->make_query;
    my $count      = 0;
    for my $root ( @{ $self->inc_path } ) {
        my $files = $self->_find( $filter_sub, $root );
        $count += scalar keys %$files;
    }

    return $count;
}

=head2 iterator( I<filter_CODE> )

Acts same as search() but returns a CatalystX::CRUD::Iterator::File
object instead of a simple array ref.

=cut

sub iterator {
    my $self  = shift;
    my $files = $self->search(@_);
    return CatalystX::CRUD::Iterator::File->new($files);
}

=head2 iterator_related( I<file>, I<rel_name> )

Required method. Acts like iterator() for I<rel_name>.

=cut

sub iterator_related {
    my $self     = shift;
    my $file     = shift or $self->throw_error('file required');
    my $rel_name = shift or $self->throw_error('rel_name required');
    if ( $rel_name eq 'dir' ) {
        my $files = $self->search(@_);
        return CatalystX::CRUD::Iterator::File->new($files);
    }
    else {
        $self->throw_error("unsupported relationship name: $rel_name");
    }
}

=head2 add_related( I<file>, I<rel_name>, I<other_file_name>, I<overwrite> )

For I<rel_name> of "dir" will create a symlink for I<other_file_name>'s
basename to I<file> in the same directory as I<file>.

If a file already exists for I<other_file_name> in the same
dir as I<file> will throw an error indicating the relationship
already exists. To stop the error being thrown, pass a true
value for the I<overwrite> param.

If the symlink fails, will throw_error().

If symlink() is not supported on your system, will print an error
to the Catalyst log.

=cut

sub add_related {
    my ( $self, $file, $rel_name, $other_file_name, $overwrite ) = @_;

    if ( !$SYMLINK_SUPPORTED ) {
        $self->context->log->error(
            "symlink() is not supported on this system");
        return;
    }

    my $other_file = $self->fetch( file => $other_file_name );

    unless ( -r $other_file ) {
        $self->throw_error("no such file $other_file");
    }

    if ( $rel_name eq 'dir' ) {

        # if in the same dir, already related.
        if ( $other_file->dir eq $file->dir ) {
            if ($overwrite) {
                return 1;    # nothing to do
            }
            $self->throw_error("relationship already exists");
        }

        # if not, create symlink
        my $link = $self->object_class->delegate_class->new( $file->dir,
            $other_file->basename );
        if ( !symlink( "$file", "$link" ) ) {
            $self->throw_error("failed to symlink $link => $file: $@");
        }

    }
    else {
        $self->throw_error("unsupported relationship name: $rel_name");
    }

    return $other_file;
}

=head2 put_related( I<file>, I<rel_name>, I<other_file_name> )

Calls add_related() with overwrite option.

=cut

sub put_related {
    my $self = shift;
    return $self->add_related( @_, 1 );    # overwrite
}

=head2 rm_related( I<file>, I<rel_name>, I<other_file_name> )

For I<rel_name> of "dir" will create a symlink for I<other_file_name>'s
basename to I<file> in the same directory as I<file>.

If the symlink() function is not supported, will log an error and return
without doing anything.

If the symlink represented by I<other_file_name> does not exist
or is not a symlink, will throw an error.

If the unlink fails will also throw an error.

=cut

sub rm_related {
    my ( $self, $file, $rel_name, $other_file_name ) = @_;

    if ( !$SYMLINK_SUPPORTED ) {
        $self->context->log->error(
            "symlink() is not supported on this system");
        return;
    }

    my $other_file = $self->fetch( file => $other_file_name );

    unless ( -r $other_file ) {
        $self->throw_error("no such file $other_file : $!");
    }

    if ( $rel_name eq 'dir' ) {
        my $link = $self->object_class->delegate_class->new( $file->dir,
            $other_file->basename );

        unless ( -l $link ) {
            $self->throw_error("$other_file is not a symlink");
        }

        unlink($link) or $self->throw_error("unlink for $link failed: $!");

        return 1;

    }
    else {
        $self->throw_error("unsupported relationship name: $rel_name");
    }

}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <perl at peknet.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-CRUD>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::CRUD

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
