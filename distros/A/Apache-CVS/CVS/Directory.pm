# $Id: Directory.pm,v 1.3 2002/11/14 07:25:26 barbee Exp $

=head1 NAME

Apache::CVS::Directory - class that implements a directory in CVS

=head1 SYNOPSIS

 use Apache::CVS::RcsConfig();
 use Apache::CVS::Directory();

 $directory = Apache::CVS::Directory->new($path, $rcs_config);

 $sub_directory = $directory->directories();
 $version_files = $directory->files();
 $other_files   = $directory->plain_files();

=head1 DESCRIPTION

The C<Apache::CVS::Directory> class implements a directory in a CVS repository.

=over 4

=cut

package Apache::CVS::Directory;
use strict;

use Apache::CVS::PlainFile();
use Apache::CVS::File();
@Apache::CVS::Directory::ISA = ('Apache::CVS::PlainFile');

$Apache::CVS::Directory::VERSION = $Apache::CVS::VERSION;;

=item $directory = Apache::CVS::Directory($path, $rcs_config)

Construct a new C<Apache::CVS::Directory> object. The first argument is the
full path of the directory. The second argument is an C<Apache::CVS::RcsConfig>
object.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(shift);

    $self->{plain_files} = [];
    $self->{files} = [];
    $self->{directories} = [];
    $self->{loaded} = 0;
    $self->{rcs_config} = shift;

    bless ($self, $class);
    return $self;
}

sub rcs_config {
    my $self = shift;
    $self->{rcs_config} = shift if scalar @_;
    return $self->{rcs_config};
}

sub loaded {
    my $self = shift;
    $self->{loaded} = shift if scalar @_;
    return $self->{loaded};
}

sub push {
    my $self = shift;
    my ($type, $object) = @_;
    if ($type eq 'directory') {
        push @{ $self->{directories} }, $object;
    } elsif ($type eq 'file') {
        push @{ $self->{files} }, $object;
    } elsif ($type eq 'plain_file') {
        push @{ $self->{plain_files} }, $object;
    }
}

sub load {
    my $self = shift;
    opendir DIR, $self->path();
    my @contents= grep { m#^[^\.]{1,2}# } readdir DIR;

    my @directories = grep { -d $self->path() . "/$_" &&
                             -X $self->path() . "/$_" && $_ } @contents;
    foreach my $path ( @directories ) {
        $self->push('directory',
                    Apache::CVS::Directory->new($self->path() . "/$path",
                                                $self->rcs_config()));
    }

    my @files = grep { -f $self->path() . "/$_" &&
                       -r $self->path() . "/$_" && $_ } @contents;
    foreach my $path ( @files ) {
        if ( $path =~ /,v$/ ) {
            $self->push('file',
                        Apache::CVS::File->new($self->path() . "/$path",
                                                      $self->rcs_config()));
        } else {
            $self->push('plain_file',
                        Apache::CVS::PlainFile->new($self->path() . "/$path"));
        }
    }

    $self->loaded(1);
    return $self->loaded();
}

=item $directory->directories()

Returns a reference to an array of C<Apache::CVS::Directory> objects which
represent subdirectories of this directory.

=cut

sub directories {
    my $self = shift;
    $self->load() unless $self->loaded();
    return $self->{directories};
}

=item $directory->files()

Returns a reference to an array of C<Apache::CVS:File> object which
represent versioned files in this directory.

=cut

sub files {
    my $self = shift;
    $self->load() unless $self->loaded();
    return $self->{files};
}

=item $directory->plain_files()

Returns a reference to an array of C<Apache::CVS:PlainFile> object which
represent files in this directory that are not versioned.

=cut

sub plain_files {
    my $self = shift;
    $self->load() unless $self->loaded();
    return $self->{plain_files};
}

=back

=head1 SEE ALSO

L<Apache::CVS>, L<Apache::CVS::File>, L<Apache::CVS::PlainFile>,
L<Apache::CVS::RcsConfig>

=head1 AUTHOR

John Barbee <F<barbee@veribox.net>>

=head1 COPYRIGHT

Copyright 2001-2002 John Barbee

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
