package CPAN::Local::Plugin::DistroList;
{
  $CPAN::Local::Plugin::DistroList::VERSION = '0.003';
}

# ABSTRACT: Populate a mirror with a list of distributions

use strict;
use warnings;

use Path::Class qw(file dir);
use File::Temp;
use URI;
use Try::Tiny;
use LWP::Simple;
use CPAN::DistnameInfo;

use Moose;
extends 'CPAN::Local::Plugin';
with 'CPAN::Local::Role::Gather';
use namespace::clean -except => 'meta';

has list =>
(
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_list',
);

has prefix =>
(
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

has uris =>
(
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
    traits     => ['Array'],
    handles    => { uri_list => 'elements' },
);

has cache =>
(
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

has authorid =>
(
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_authorid',
);

has local =>
(
    is         => 'ro',
    isa        => 'Bool',
);

sub _build_uris
{
    my $self = shift;

    my $prefix = $self->prefix;

    my @uris;

    if ( $self->has_list )
    {
        foreach my $line ( file( $self->list )->slurp )
        {
            chomp $line;
            push @uris, $prefix . $line;
        }
    }

    return \@uris;
}

sub _build_cache
{
    return File::Temp::tempdir( CLEANUP => 1 );
}

sub gather
{
    my $self = shift;

    my @distros;

    foreach my $uri ( $self->uri_list )
    {
        my %args = $self->local
            ? ( filename => $uri )
            : ( uri => $uri, cache => $self->cache );

        $args{authorid} = $self->authorid if $self->has_authorid;
        my $distro =
            try   { $self->create_distribution(%args) }
            catch { $self->log($_) };

        push @distros, $distro if $distro;
    }

    return @distros;
}

sub requires_distribution_roles { 'FromURI' }

__PACKAGE__->meta->make_immutable;


__END__
=pod

=head1 NAME

CPAN::Local::Plugin::DistroList - Populate a mirror with a list of distributions

=head1 VERSION

version 0.003

=head1 SYNOPSIS

In C<cpanlocal.ini>:

  ; Add distros from backan
  [DistroList / Backpan]
  list   = backpan.distrolist
  prefix = http://backpan.perl.org/authors/id/
  cache  = /home/user/backpan/cache

  ; Add distros from filesystem
  [DistroList / Local]
  list     = local.distrolist
  prefix   = /home/user/distros/
  local    = 1
  authorid = MYCOMPANY

In C<backpan.distrolist>:

  A/AB/ABH/Apache-DBI-0.94.tar.gz
  A/AB/ABIGAIL/Regexp-Common-1.30.tar.gz
  A/AB/ABW/Class-Base-0.03.tar.gz
  ...

In C<local.distrolist>:

  My-Great-App-001.tar.gz
  My-Great-App-002.tar.gz
  ...

Then simply update the repo from the command line:

  % lpan update

=head1 DESCRIPTION

This plugin allows you to add distributions from a list of filenames or uris.
The list is read from a configuration file containing one distribution name
per line.

=head1 IMPLEMENTS

=over

=item L<CPAN::Local::Role::Gather>

=back

=head1 ATTRIBUTES

=head2 list

Required. Path to the configuration file that contains the list of
distributions. The configuration file must contain absolute paths or uris,
unless L</prefix> is specified.

=head2 prefix

Optional. String to prepend to each line in the configuration file. This is
commonly the base uri of a CPAN mirror or the path to a local folder containing
distributions. Note that the prefix is simply concatenated with each line in
the configuration file, so be careful not to omit the trailing slash where
needed.

=head2 cache

Optional. Directory where to download a remote distribution before adding it
to the mirror. If a distribtuion from the configuartion file is already in the
cache, it will not be downloaded again. Ignored when L</local> is used.

=head2 local

Optional. Instructs the plugin that the distributions live in the local
filesystem, so no attempt will be made to download or cache them.

=head2 authorid

Optional. Author id to use when injecting distributions from this list.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

