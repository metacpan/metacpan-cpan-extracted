use strict;
use warnings;

package Dancer2::Session::Memcached;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Dancer 2 session storage with Cache::Memcached
$Dancer2::Session::Memcached::VERSION = '0.007';
use Moo;
use Cache::Memcached;
use Carp qw/ croak /;

use Types::Standard qw/ Str ArrayRef InstanceOf /;

use Type::Tiny;

my $Server = Type::Tiny->new(
    name       => 'MemcachedServer',
    parent     => Str,
    constraint => sub { ! /^\d+\.\d+\.\d+\.\d+$/ },
    message    => sub {
        "server `$_' is invalid; port is missing, use `server:port'"
    },

);

my $Servers = Type::Tiny->new(
    name     => 'MemcachedServers',
    parent   => ArrayRef[$Server],
    coercion => Type::Coercion->new( type_coercion_map => [
        Str ,=> sub { [ split ',', $_ ] },
    ]),
);


#--------------------------------------------------------------------------#
# Public attributes
#--------------------------------------------------------------------------#


has memcached_servers => (
    is       => 'ro',
    isa      => $Servers,
    required => 1,
    coerce   => $Servers->coercion,
);

has fatal_cluster_unreachable => (
    is       => 'ro',
    required => 0,
    default  => sub { 0 },
);

#--------------------------------------------------------------------------#
# Private attributes
#--------------------------------------------------------------------------#

has _memcached => (
    is  => 'lazy',
    isa => InstanceOf ['Cache::Memcached'],
    handles => {
        _destroy  => 'delete',
    },
);

sub _retrieve {
    my ($self) = shift;

    croak "Memcache cluster unreachable _retrieve"
        if $self->fatal_cluster_unreachable && not keys %{$self->_memcached->stats(['misc'])};

    return $self->_memcached->get( @_ );
}

sub _flush {
    my ($self) = shift;

    croak "Memcache cluster unreachable _flush"
        if $self->fatal_cluster_unreachable && not keys %{$self->_memcached->stats(['misc'])};

    return $self->_memcached->set( @_ );
}

# Adapted from Dancer::Session::Memcached
sub _build__memcached {
    my ($self) = @_;

    return Cache::Memcached->new( servers => $self->memcached_servers );
}

#--------------------------------------------------------------------------#
# Role composition
#--------------------------------------------------------------------------#

with 'Dancer2::Core::Role::SessionFactory';

# _retrieve, _flush, _destroy handled by _memcached object

# memcached doesn't have any easy way to list keys it knows about
# so we cheat and return an empty array ref
sub _sessions { [] }

sub _change_id {
    my ( $self, $old_id, $new_id ) = @_;
    $self->_flush( $new_id, $self->_retrieve( $old_id ) );
    $self->_destroy( $old_id );
}

# reject anything where the first two bytes are below \x20 once
# Base64 decoded, ensuring Storable doesnt attempt to thaw such cruft.
sub validate_id {
    $_[1] =~ m/^[I-Za-z0-9_\-~][A-Za-z0-9_\-~]+$/;
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Session::Memcached - Dancer 2 session storage with Cache::Memcached

=head1 VERSION

version 0.007

=head1 SYNOPSIS

  # In Dancer 2 config.yml file

  session: Memcached
  engines:
    session:
      Memcached:
        memcached_servers: 
          - 10.0.1.31:11211
          - 10.0.1.32:11211
          - /var/sock/memcached
        fatal_cluster_unreachable: 0

=head1 DESCRIPTION

This module implements a session factory for L<Dancer2> that stores session
state within Memcached using L<Cache::Memcached>.

=head1 ATTRIBUTES

=head2 memcached_servers (required)

An array (or a comma-separated list) of reachable memcached 
servers (can be either address:port or socket paths).

=for Pod::Coverage method_names_here

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018, 2016 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
