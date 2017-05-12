package CPAN::Mirror::Finder;
use strict;
use warnings;
use Moo;
use URI;
use URI::file;
our $VERSION = '0.01';

=head1 NAME

CPAN::Mirror::Finder - Find a locally-configured CPAN mirror

=head1 SYNOPSIS

  use CPAN::Mirror::Finder;
  my $finder = CPAN::Mirror::Finder->new;
  my @mirrors = $finder->find_all_mirrors;

  my @cpanmini_mirrors = $finder->find_cpanmini_mirrors;
  my @cpan_mirrors = $finder->find_cpan_mirrors;
  my @cpanplus_mirrors = $finder->find_cpanplus_mirrors;

=head1 DESCRIPTION

This modules makes it easy to find a locally-configured CPAN mirror.
There are many ways to have a CPAN mirror. The most explicit is to
use CPAN::Mini with a configuration file to have an entirely local
CPAN mirror.

Also CPAN.pm can be configured with details of CPAN mirrors.

Also CPANPLUS can be configured with details of CPAN mirrors.
This also contains sensible defaults if the user has not configured
anything.

All methods return URI objects.

=head1 METHODS

=head2 find_all_mirrors

Returns a combination of all the ways of finding locally-configured
CPAN mirror:

  my @mirrors = $finder->find_mirror; # returns all the following

=cut

sub find_all_mirrors {
    my $self = shift;
    return ( grep {defined} $self->find_cpanmini_mirrors,
        $self->find_cpan_mirrors, $self->find_cpanplus_mirrors );
}

=head2 find_cpanmini_mirrors

Returns a local CPAN::Mini mirror, if any:

  my @cpanmini_mirrors = $finder->find_cpanmini_mirrors;

=cut

sub find_cpanmini_mirrors {
    my $self = shift;
    eval { require CPAN::Mini; };
    return if $@;
    my %config = CPAN::Mini->read_config;
    my ($directory) = glob $config{local};
    return URI::file->new($directory);
}

=head2 find_cpan_mirrors

Returns the mirrors configured by CPAN.pm:

  my @cpan_mirrors = $finder->find_cpan_mirrors;

=cut

sub find_cpan_mirrors {
    my $self = shift;
    eval { require CPAN::Config; };
    return if $@;
    return map { URI->new($_) } @{ $CPAN::Config->{urllist} || [] };
}

=head2 find_cpanplus_mirrors

Returns the mirrors configured by CPANPLUS:

  my @cpanplus_mirrors = $finder->find_cpanplus_mirrors;

=cut

sub find_cpanplus_mirrors {
    my $self = shift;
    eval { require CPANPLUS::Configure; };
    return if $@;
    my $conf = CPANPLUS::Configure->new;
    my @hosts = @{ $conf->get_conf('hosts') || [] };
    return map {
        my $uri = URI->new;
        $uri->scheme( $_->{scheme} );
        $uri->host( $_->{host} );
        $uri->path( $_->{path} );
        $uri;
    } @hosts;
}

1;

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2011, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
