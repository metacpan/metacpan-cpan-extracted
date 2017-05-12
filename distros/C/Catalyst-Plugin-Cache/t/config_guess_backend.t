#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

{
    package ManyStores;
    use base qw/Catalyst::Plugin::Cache/;

    sub registered_plugins {
        qw/
            Bar
            Cache
            Cache::Store::Foo
            Cache::Store::Bar
            MyApp::Plugin::Cache::Store::Moose
            Cheese
        /;
    }

    package OneStore;
    use base qw/Catalyst::Plugin::Cache/;

    sub registered_plugins {
        qw/
            Aplugin
            Cache
            Cache::Store::Foo
        /
    }

    package NoStores;
    use base qw/Catalyst::Plugin::Cache/;

    sub registered_plugins {
        qw/
            Bar
            Cache
            Lala
        /
    }
}

# store guessing

lives_ok { OneStore->guess_default_cache_store } "can guess if only one plugin";
is( OneStore->guess_default_cache_store, "Foo", "guess is right" );

dies_ok { ManyStores->guess_default_cache_store } "can't guess if many";
dies_ok { NoStores->guess_default_cache_store } "can't guess if none";


