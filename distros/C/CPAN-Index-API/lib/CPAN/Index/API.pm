package CPAN::Index::API;

our $VERSION = '0.008';

use strict;
use warnings;

use Path::Class qw(dir);
use Carp        qw(croak);
use Class::Load qw(load_class);
use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints qw(find_type_constraint);

has files => (
    is      => 'bare',
    isa     => 'HashRef',
    traits  => ['Hash'],
    handles => { files => 'values', file => 'get', file_names => 'keys' },
);

has repo_path =>
(
    is       => 'ro',
    isa      => 'Str',
);

has repo_uri =>
(
    is       => 'ro',
    isa      => 'Str',
);

sub BUILDARGS {
    my ( $class, %args ) = @_;

    croak "Please specifiy which files to load" unless $args{files};

    my $constraint = find_type_constraint('ArrayRef[Str]');

    if ( $constraint->check($args{files}) )
    {
        my %files;

        foreach my $file ( @{ $args{files} } )
        {
            my $package_name = "CPAN::Index::API::File::$file";
            load_class $package_name;
            $files{$file} = $package_name->new(
                repo_path => $args{repo_path},
                repo_uri  => $args{repo_uri},
            );
        }

        $args{files} = \%files;
    }

    if ( $args{repo_path} and not $args{repo_uri} )
    {
        $args{repo_uri} = URI::file->new(
            dir($args{repo_path})->absolute
        )->as_string;
    }

    return \%args;
}

sub new_from_repo_path
{
    my ($class, %args) = @_;

    if ( $args{repo_path} and not $args{repo_uri} )
    {
        $args{repo_uri} = URI::file->new(
            dir($args{repo_path})->absolute
        )->as_string;
    }

    my $files = delete $args{files};
    my %files;

    croak "Please specifiy which files to load" unless $files;

    foreach my $file ( @$files )
    {
        my $package_name = "CPAN::Index::API::File::$file";
        load_class $package_name;

        $files{$file} = $package_name->read_from_repo_path(
            $args{repo_path}
        );
    }

    return $class->new( %args, files => \%files );
}

sub new_from_repo_uri
{
    my ($class, %args) = @_;

    my $files = delete $args{files};
    my %files;

    croak "Please specifiy which files to load" unless $files;

    foreach my $file ( @$files )
    {
        my $package_name = "CPAN::Index::API::File::$file";
        load_class $package_name;

        $files{$file} = $package_name->read_from_repo_uri(
            $args{repo_uri}
        );
    }

    return $class->new( %args, files => \%files );
}

sub write_all_files
{
    my $self = shift;
    $_->write_to_default_location for $self->files;
}

sub clone {
    my ($self, %args) = @_;

    my %new_files;
    foreach my $file_name ( $self->file_names )
    {
        my $new_file = $self->file($file_name)->clone(%args);
        $new_files{$file_name} = $new_file;
    }

    return (blessed $self)->meta->clone_object(
        $self, files => \%new_files, %args
    );
}

__PACKAGE__->meta->make_immutable;

=pod

=encoding UTF-8

=head1 NAME

CPAN::Index::API - Read and write CPAN index files

=head1 SYNOPSIS

    my $index = CPAN::Index::API->new_from_repo_uri(
        repo_uri => 'http://cpan.perl.org/',
        files => [qw(PackagesDetails ModList MailRc)],
    );

    my $packages = $index->file('PackagesDetails');

=head1 DESCRIPTION

C<CPAN::Index::API> is a library to read and write CPAN index files. See the
modules in the C<CPAN::Index::API::File> namespace for documentation on the
individual files supported.

This class provides a convenient interface for working with multiple files
from the same location at the same time.

=head1 CONSTRUCTION

=head2 new

Creates a new index object. Accepts the following parameters:

=over

=item files

Required. Hashrefs whose values are C<CPAN::Index::API::File> objects. The
individual objects can later be accessed by their respective hash key via the
L</file> method.

=item repo_path

Optional. Path to the root of the repository to which the index files belong.

=item repo_uri

Optional. Base uri of the repository to which the index files belong.

=back

=head2 new_from_repo_path

Creates a new index object by reading one or more index files from a local
repository. Accepts the following parameters:

=over

=item files

Required. Arrayref of names of index files to be read. Each name must be the
name of a plugin under the C<CPAN::Index::API::File::> namespace, e.g.
C<PackagesDetails>, C<ModList>, etc.

=item repo_path

Required. Path to the root of the local repository.

=back

=head2 new_from_repo_uri

Creates a new index object by reading one or more index files from a remote
repository. Accepts the following parameters:

=over

=item files

Required. Arrayref of names of index files to be read. Each name must be the
name of a plugin under the C<CPAN::Index::API::File::> namespace, e.g.
C<PackagesDetails>, C<ModList>, etc.

=item repo_uri

Required. Path to the base uri of the remote repository.

=back

=head1 METHODS

=head2 file

Given the name of a file plugin loaded within the index, returns the object
corresponding to this index file.

=head2 repo_path

Returns the path to the repository.

=head2 repo_uri

Returns the base uri of the repository.

=head2 write_all_files

Writes all index files to their default locations under C<repo_path>.

=head2 clone

Creates a new instance of this object, overloading any of the existing
attributes with any arguments passed.

=head1 AUTHOR

Peter Shangov <F<pshangov@yahoo.com>>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Venda, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
