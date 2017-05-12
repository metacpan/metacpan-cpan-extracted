#!/usr/bin/perl

package Catalyst::Plugin::Cache::Choose::KeyRegexes;

use strict;
use warnings;
use MRO::Compat;

sub setup {
    my $app = shift;
    my $ret = $app->maybe::next::method( @_ );

    my $regexes = $app->_get_cache_plugin_config->{key_regexes} ||= [];

    die "the regex list must be an array containing regexex/backend pairs" unless ref $regexes eq "ARRAY";

    $ret;
}

sub get_cache_key_regexes {
    my ( $c, %meta ) = @_;
    @{ $c->_get_cache_plugin_config->{key_regexes} };
}

sub choose_cache_backend {
    my ( $c, %meta ) = @_;

    my @regexes = $c->get_cache_key_regexes( %meta );

    while ( @regexes and my ( $re, $backend ) = splice( @regexes, 0, 2 ) ) {
        return $backend if $meta{key} =~ $re;
    }

    $c->maybe::next::method( %meta );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Cache::Choose::KeyRegex - Choose a cache backend based on key regexes.

=head1 SYNOPSIS

	use Catalyst::Plugin::Cache::Choose::KeyRegex;

=head1 DESCRIPTION

=cut


