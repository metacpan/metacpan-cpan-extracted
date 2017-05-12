#!/usr/bin/perl -w

use strict;

use Test::More tests => 9;
use Test::Exception;
use Test::Refcount;

use Config::XPath;

my $c = Config::XPath->new( filename => "t/data.xml" );

ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath", 'ref $c' );

is_oneref( $c, '$c has one reference' );

my $v;

$v = $c->get( "/data/aaa/bbb" );
is( $v, "Content", 'content (plain string)' );

$v = $c->get( [ '/data/aaa/@str', '/data/aaa/bbb' ] );
is_deeply( $v, [ 'hello', 'Content' ], 'content (ARRAY ref)' );

$v = $c->get( { one => '/data/ccc/dd[@value="1"]/@name', two => '/data/ccc/dd[@value="2"]/@name' } );
is_deeply( $v, { one => 'one', two => 'two' }, 'content (HASH ref)' );

$v = $c->get( [ { name => '/data/eee/ff[1]/@name', value => '/data/eee/ff[1]' },
                { name => '/data/eee/ff[2]/@name', value => '/data/eee/ff[2]' } ] );
is_deeply( $v, [ { name => "one", value => 1 }, { name => "two", value => 2 } ], 'content (ARRAY of HASH ref)' );

dies_ok( sub { $c->get( \"scalar" ) },
         'get on SCALAR ref fails' );

is_oneref( $c, '$c has one reference at EOF' );
