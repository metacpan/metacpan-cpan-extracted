#!/usr/bin/perl

package Catalyst::Plugin::Cache::Backend::FastMmap;
use base qw/Cache::FastMmap/;

use strict;
use warnings;

# wrap everything in a scalar ref so that we can store plain scalars as well

sub get {
    my ( $self, $key ) = @_;
    ${ $self->SUPER::get($key) || return };
}

sub set {
    my ( $self, $key, $value ) = @_;
    $self->SUPER::set( $key => \$value );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Cache::Backend::FastMmap - A thin wrapper for
L<Cache::FastMmap> that can handle non refs.

=head1 SYNOPSIS

	use Catalyst::Plugin::Cache::Backend::FastMmap;

    my $cache_obj = Catalyst::Plugin::Cache::Backend::FastMmap->new;

    $cache_obj->set( key => [qw/blah blah blah/] );

    $cache_obj->set( key => "this_works_too" ); # non references can also be stored

=head1 DESCRIPTION

=cut


