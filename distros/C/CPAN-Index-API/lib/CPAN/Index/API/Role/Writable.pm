package CPAN::Index::API::Role::Writable;

our $VERSION = '0.008';

use strict;
use warnings;

use File::Basename qw(fileparse);
use Path::Class    qw(file dir);
use Path::Tiny     qw(path);
use Text::Template qw(fill_in_string);
use Symbol         qw(qualify_to_ref);
use Scalar::Util   qw(blessed);
use Carp           qw(croak);
use Compress::Zlib qw(gzopen $gzerrno);
use namespace::autoclean;
use Moose::Role;

requires 'default_location';

has tarball_is_default => (
    is         => 'ro',
    isa        => 'Bool',
    lazy_build => 1,
);

has repo_path => (
    is  => 'ro',
    isa => 'Str',
);

has template => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
);

has content => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
);

sub _build_template {
    my $self = shift;
    my $data;
    my $error;
    { # catch block
        local $@;
        $error = $@ || 'Error' unless eval { # try block
            my $data_glob = qualify_to_ref("DATA", blessed $self);
            # find the current location before reading
            my $tell = tell($data_glob);
            local $/;
            $data = <$data_glob>;
            # put the location back so we can read again
            # SEEK_SET is 0
            seek($data_glob, $tell, 0);
            1;
        };
    }
    if ($error) {
        warn $error;
        return;
    }
    return $data;
}

sub _build_content {
    my $self = shift;
    my $content = fill_in_string(
        $self->template,
        DELIMITERS => [ '[%', '%]' ],
        HASH       => { self  => \$self },
    );
    chomp $content;
    return $content;
}

sub _build_tarball_is_default {
    my $self = shift;
    return $self->default_location =~ /\.gz$/ ? 1 : 0;
}

sub rebuild_content {
    my $self  = shift;
    my $meta  = (blessed $self)->meta;
    $meta->get_attribute('content')->set_value($self, $self->_build_content);
}

sub write_to_tarball {
    my ($self, $filename)  = @_;
    my $file = $self->_prepare_file($filename, 1);
    my $gz = gzopen($file->stringify, 'wb') or croak "Cannot open $file: $gzerrno";
    $gz->gzwrite($self->content);
    $gz->gzclose and croak "Error closing $file";
}

sub write_to_file {
    my ($self, $filename) = @_;
    path($self->_prepare_file($filename))->spew_utf8($self->content);
}

sub write_to_default_location {
    my ($self) = @_;
    $self->tarball_is_default
        ? $self->write_to_tarball
        : $self->write_to_file;
}

sub _prepare_file {
    my ( $self, $file, $is_tarball ) = @_;

    if ( defined $file ) {
        $file = file($file);
    } elsif ( not defined $file and $self->repo_path ) {
        my $location = $self->default_location;

        # first normalize the extension
        $location =~ s/\.gz$//;
        # then  make sure we have it if we need a tarball
        $location .= '.gz' if $is_tarball;

        $file = file( $self->repo_path, $location);
    } else {
        croak "Unable to write to file without a filename or repo path";
    }

    $file->dir->mkpath unless -e $file->dir;

    return $file;
}

1;

=pod

=encoding UTF-8

=head1 NAME

CPAN::Index::Role::Writable - Writes index files

=head1 DESCRIPTION

This role provides attributes and methods shared between classes that write
index files.

=head1 REQUIRES

=head2 default_location

Class method that returns a string specifying the path to the default location
of this file relative to the repository root.

=head2 C<__DATA__>

Consuming packages are expected to have a C<DATA> section that contains the
template to use for generating the file contents.

=head1 PROVIDES

=head2 tarball_is_default

Required attribute. Boolean - indicates whether the file should be compressed
by default. Automatically set to true if the file path in C<default_location>
ends in C<.gz>.

=head2 repo_path

Optional attribute. Path to the repository root.

=head2 template

Optional attribute. The template to use for generating the index files. The
default is fetched from the C<DATA> section of the consuming package.

=head2 content

Optional attribute. The index file content. Built by default from the
provided L</template>.

=head2 rebuild_content

C<content> is a lazy read-only attribute which normally is built only once.
Use C<rebuild_content> to generate a new value for C<content> if you've made
changes to the list of packages.

=head2 write_to_file

This method builds the file content if necessary and writes it to a file. A
path to a file to write to can be passed as an argument, otherwise the default
location will be used (a C<.gz> suffix, if it exists, will be removed).

=head2 write_to_tarball

This method builds the file content if necessary and writes it to a tarball. A
path to a file to write to can be passed as an argument, otherwise the default
location will be used.

=head2 write_to_default_location

This method builds the file content if necessary and writes it to the default
location.

=cut
