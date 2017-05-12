#!/usr/bin/perl -w

use strict;

use Test::More tests => 16;
use Test::Exception;
use Test::Refcount;
use Test::Warn;

use Config::XPath;

my $c;

$c = Config::XPath->new( filename => "t/data.xml" );
ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath", 'ref $c' );

is_oneref( $c, '$c has one reference' );

my $mref;

$mref = $c->get_map( "/data/eee/ff", '@name', '.' );
ok( defined $mref, 'map defined $mref' );
is_deeply( $mref, { one => 1, two => 2 }, 'map value' );

$mref = $c->get_map( "/data/ccc/dd", '@value', 'i/@ord' );
ok( defined $mref, 'map defined $mref' );
is_deeply( $mref, { 1 => "first", 2 => "second" }, 'map value' );

$mref = $c->get_map( "/data/nonodeshere", '@name', '@value' );
ok( defined $mref, 'map defined $mref for no nodes' );
is_deeply( $mref, {}, 'map value for no nodes' );

dies_ok( sub { $mref = $c->get_map( "/data/aaa/bbb", '@name', '.' ) },
         'get_config_map missing key throws exception' );

dies_ok( sub { $mref = $c->get_map( "/data/eee/ff", '@name', '@value' ) },
         'get_config_map missing value throws exception' );

$mref = $c->get_map( "/data/ccc/dd", '@name', [ '@value', 'i/@ord' ] );
is_deeply( $mref, { one => [ 1, 'first' ], two => [ 2, 'second' ] }, 'map value with HASH valuepaths' );

$mref = $c->get_map( "/data/jj", '@o', { first => '@first' }, default => { first => 0 } );
is_deeply( $mref, { 1 => { first => 1 }, 2 => { first => 0 } } );

warning_is( sub { $mref = $c->get_config_map( "/data/eee/ff", '@name', '.' ) },
            "Using static function 'get_config_map' as a method is deprecated",
            'using static function as method gives warning' );

is_deeply( $mref, { one => 1, two => 2 }, 'map value from static function' );

is_oneref( $c, '$c has one reference at EOF' );
