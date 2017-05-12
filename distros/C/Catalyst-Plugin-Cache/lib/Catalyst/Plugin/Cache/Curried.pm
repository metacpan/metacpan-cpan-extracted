#!/usr/bin/perl

package Catalyst::Plugin::Cache::Curried;

use strict;
use warnings;

use base qw/Class::Accessor::Fast/;

use Scalar::Util ();

__PACKAGE__->mk_accessors(qw/c meta/);

sub new {
    my ( $class, $c, @meta ) = @_;

    my $self = $class->SUPER::new({
        c    => $c,
        meta => \@meta,
    });

    Scalar::Util::weaken( $self->{c} )
        if ref( $self->{c} );

    return $self;
}

sub backend {
    my ( $self, @meta ) = @_;
    $self->c->choose_cache_backend( @{ $self->meta }, @meta )
}

sub set {
    my ( $self, $key, $value, @meta ) = @_;
    @meta = ( expires => $meta[0] ) if @meta == 1;
    $self->c->cache_set( $key, $value, @{ $self->meta }, @meta );
}

sub get {
    my ( $self, $key ) = @_;
    $self->c->cache_get( $key, @{ $self->meta } );
}

sub remove {
    my ( $self, $key ) = @_;
    $self->c->cache_remove( $key, @{ $self->meta } );
}

sub compute {
    my ($self, $key, $code, @meta) = @_;
    @meta = ( expires => $meta[0] ) if @meta == 1;
    $self->c->cache_compute( $key, $code, @{ $self->meta }, @meta );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Cache::Curried - Curried versions of C<cache_set>,
C<cache_get> and C<cache_remove> that look more like a backend.

=head1 SYNOPSIS

    my $curried = $c->cache( %meta );

    $curried->get( $key, $value ); # no need to specify %meta

=head1 DESCRIPTION

See L<Catalyst::Plugin::Cache/META DATA> for details.

=head1 METHODS

=over 4

=item new %meta

Create a new curried cache, that captures C<%meta>.

=item backend %additional_meta

This calls C<choose_cache_backend> on the $c object with the captured meta and
the additional meta.

=item set $key, $value, %additional_meta

=item get $key, %additional_meta

=item remove $key, %additional_meta

=item compute $key, $code, %additional_meta

Dellegate to the C<c> object's C<cache_set>, C<cache_get>, C<cache_remove>
or C<cache_compute> with the arguments, then the captured meta from C<meta>,
and then the additional meta.

=item meta

Returns the array ref that captured %meta from C<new>.

=item c

The captured $c object to delegate to.

=back

=cut


