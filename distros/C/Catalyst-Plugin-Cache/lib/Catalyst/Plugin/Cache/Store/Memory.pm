#!/usr/bin/perl

package Catalyst::Plugin::Cache::Store::Memory;

use strict;
use warnings;

use Catalyst::Plugin::Cache::Backend::Memory;

sub setup_memory_cache_backend {
    my ( $app, $name ) = @_;
    $app->register_cache_backend( $name => Catalyst::Plugin::Cache::Backend::Memory->new );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Cache::Store::Memory - Stupid memory based cache store plugin.

=head1 SYNOPSIS

	use Catalyst::Plugin::Cache::Store::Memory;

=head1 DESCRIPTION

=cut


