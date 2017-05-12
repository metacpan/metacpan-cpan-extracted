#!/usr/bin/perl -w

use strict;

use Test::More tests => 14;
use Test::Exception;
use Test::Refcount;
use Test::Warn;

use Config::XPath;

my $c;

$c = Config::XPath->new( filename => "t/data.xml" );
ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath", 'ref $c' );

is_oneref( $c, '$c has one reference' );

my @l;

@l = $c->get_list( "/data/ccc/dd/\@name" );
is_deeply( \@l, [ qw( one two ) ], 'list values' );

@l = $c->get_list( "/data/eee/ff/text()" );
is_deeply( \@l, [ qw( 1 2 ) ], 'list of text() values' );

@l = $c->get_list( "/data/eee/ff" );
is_deeply( \@l, [ { name => 'one', '+' => 'ff' }, { name => 'two', '+' => 'ff' } ], 'list node attribute values' );

@l = $c->get_list( "/data/nonexistent" );
is_deeply( \@l, [], 'list missing' );

dies_ok( sub { @l = $c->get_list( "/data/comment()" ) },
         'get_config_list unrepresentable throws exception' );

@l = $c->get_list( "/data/eee/ff", '@name' );
is_deeply( \@l, [ qw( one two ) ], 'list values using value paths' );

@l = $c->get_list( "/data/eee/ff", { name => '@name', value => '.' } );
is_deeply( \@l, [ { name => 'one', value => 1 }, { name => 'two', value => 2 } ], 'list values using HASH value paths' );

@l = $c->get_list( "/data/jj", { o => '@o', first => '@first' }, default => { first => 0 } );
is_deeply( \@l, [ { o => 1, first => 1 }, { o => 2, first => 0 } ] );

warning_is( sub { @l = $c->get_config_list( "/data/ccc/dd/\@name" ) },
            "Using static function 'get_config_list' as a method is deprecated",
            'using static function as method gives warning' );

is_deeply( \@l, [ qw( one two ) ], 'list values from static function' );

is_oneref( $c, '$c has one reference at EOF' );
