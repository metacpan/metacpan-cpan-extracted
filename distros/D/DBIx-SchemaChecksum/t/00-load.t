#!/usr/bin/perl
use Test::More;
use lib 'lib';
use Module::Pluggable search_path => [ 'DBIx::SchemaChecksum' ];

require_ok( $_ ) for sort 'DBIx::SchemaChecksum', __PACKAGE__->plugins;

done_testing();

