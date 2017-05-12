#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok "Catalyst::Plugin::Cache";

{
    package MockApp;
    use base qw/Catalyst::Plugin::Cache/;

    package MyCache;
    sub new {
        my ( $class, $p ) = @_;
        die unless ref $p;
        bless { %$p }, $class;
    }
    sub get {}
    sub set {}
    sub remove {}
}

MockApp->_cache_backends({});

MockApp->setup_generic_cache_backend( "foo", {
    class => "MyCache",
    param => "foo",
});

my $registered = MockApp->get_cache_backend( "foo" );

ok( $registered, "registered a backend" );

is_deeply( $registered, MyCache->new({ param => "foo" }), "params sent correctly" );

done_testing;

