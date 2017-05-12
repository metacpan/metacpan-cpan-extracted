#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok "Catalyst::Plugin::Cache";
use_ok "Catalyst::Plugin::Cache::Choose::KeyRegexes";

use Catalyst::Plugin::Cache::Backend::Memory;

{
    package MockApp;
    use base qw/Catalyst::Plugin::Cache Catalyst::Plugin::Cache::Choose::KeyRegexes/;

    our %config = (
        'Plugin::Cache' => {
            key_regexes => [
                qr/^foo/ => "foo_store",
                qr/^bar/ => "bar_store",
            ],
            ### as of 0.06, you must specify a backend
            backend => { 
                class   => 'Catalyst::Plugin::Cache::Backend::Memory',
            }
        },
    );
    sub config { \%config }
}


MockApp->setup;
my $c = bless {}, "MockApp";

MockApp->register_cache_backend( default => Catalyst::Plugin::Cache::Backend::Memory->new );
MockApp->register_cache_backend( foo_store => Catalyst::Plugin::Cache::Backend::Memory->new );
MockApp->register_cache_backend( bar_store => Catalyst::Plugin::Cache::Backend::Memory->new );

is( $c->choose_cache_backend_wrapper( key => "baz" ), $c->default_cache_backend, "chose default" );
is( $c->choose_cache_backend_wrapper( key => "foo" ), $c->get_cache_backend("foo_store"), "chose foo" );
is( $c->choose_cache_backend_wrapper( key => "bar" ), $c->get_cache_backend("bar_store"), "chose bar" );

$c->cache_set( foo_laa => "laa" );
$c->cache_set( bar_laa => "laa" );
$c->cache_set( baz_laa => "laa" );

is( $c->default_cache_backend->get("baz_laa"), "laa", "non match stored in default" );
is( $c->default_cache_backend->get("foo_laa"), undef, "no foo key" );
is( $c->default_cache_backend->get("bar_laa"), undef, "no bar key" );


is( $c->get_cache_backend("foo_store")->get("baz_laa"), undef, "no non match in foo store" );
is( $c->get_cache_backend("foo_store")->get("foo_laa"), "laa", "has foo key" );
is( $c->get_cache_backend("foo_store")->get("bar_laa"), undef, "no bar key" );


is( $c->get_cache_backend("bar_store")->get("baz_laa"), undef, "no non match in bar store" );
is( $c->get_cache_backend("bar_store")->get("foo_laa"), undef, "no foo key" );
is( $c->get_cache_backend("bar_store")->get("bar_laa"), "laa", "has bar key" );

done_testing;

