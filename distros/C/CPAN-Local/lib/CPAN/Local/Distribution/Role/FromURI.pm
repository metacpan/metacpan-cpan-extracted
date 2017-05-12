package CPAN::Local::Distribution::Role::FromURI;
{
  $CPAN::Local::Distribution::Role::FromURI::VERSION = '0.010';
}

# ABSTRACT: Allow distributions to be fetched from remote uris

use strict;
use warnings;
use Carp        qw(croak);
use Path::Class qw(file dir);
use File::Temp  qw(tempdir);
use LWP::Simple qw(is_error getstore);
use Moose::Role;
use namespace::clean -except => 'meta';

has uri   => ( is => 'ro', isa => 'Str' );
has cache => ( is => 'ro', isa => 'Str' );

around BUILDARGS => sub
{
    my ( $orig, $class, %args ) = @_;

    return $class->$orig(%args) unless $args{uri};

    croak "Please specify either 'filename' or 'uri', not both"
        if $args{uri} and $args{filename};

    my $uri = URI->new($args{uri});
    my $fake_filename = file($uri->path_segments)->stringify;

    unless ( $args{path} and $args{authorid} )
    {
        my $fake_distro = CPAN::Local::Distribution->new(
            filename => $fake_filename,
            $args{authorid} ? ( authorid => $args{authorid} ) : (),
        );

        $args{authorid} = $fake_distro->authorid unless $args{authorid};
        $args{path} = $fake_distro->path unless $args{path};
    }

    $args{cache} = tempdir( CLEANUP => 1 ) unless $args{cache};

    my $filename = file($args{cache}, $args{path});
    $filename->dir->mkpath;

    if ( not -e $filename )
    {
        my $result = getstore( $uri->as_string, $filename->stringify );
        croak "Error fetching " . $uri->as_string if is_error $result;
    }

    $args{filename} = $filename->stringify;

    return $class->$orig(%args);
};

1;


__END__
=pod

=head1 NAME

CPAN::Local::Distribution::Role::FromURI - Allow distributions to be fetched from remote uris

=head1 VERSION

version 0.010

=head1 DESCRIPTION

This role allows a distribution object to be created from a remote URI rather
than from a local file. The URI will be fetched and saved locally, and
L<CPAN::Local::Distribution/filename> will be set to the local file's name.

  package CPAN::Local::Distribution::Custom
  {
    use Moose;
    extends 'CPAN::Local::Distribution';
    with 'CPAN::Local::Distribution::Role::FromURI';
  }

  package main
  {
    my $distro = CPAN::Local::Distribution::Custom->new(
        uri   => 'http:://www.somepan.org/authors/id/F/FO/FOOBAR/Foo-Bar-0.001.tar.gz',
        cache => '/path/to/cache'
    );

    say $distro->filename; # /path/to/cache/authors/id/F/FO/FOOBAR/Foo-Bar-0.001.tar.gz
    say $distro->authorid; # FOOBAR
  }

=head1 ATTRIBUTES

=head2 uri

The remote distribution URI. The last part of the path must be a valid
distribution name.

=head2 cache

Directory where the distribution will be downloaded to. A temporarary
directory will be used if none is specified. If the distribution already
exists in the cache, it will not be downloaded again.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

