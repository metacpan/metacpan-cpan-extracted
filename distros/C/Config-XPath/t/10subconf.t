#!/usr/bin/perl -w

use strict;

use Test::More tests => 23;
use Test::Refcount;
use Test::Warn;

use Config::XPath;

my $c;

$c = Config::XPath->new( filename => "t/data.xml" );
ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath", 'ref $c' );

is_oneref( $c, '$c has one reference' );

my $sub = $c->get_sub( "/data/ccc" );
ok( defined $sub, 'defined $sub' );
is( ref $sub, "Config::XPath", 'ref $sub' );

my ( $s, $aref, @l );

$s = $sub->get_string( "dd[\@name=\"one\"]/\@value" );
is( $s, "1", 'sub get_config_string' );

$aref = $sub->get_attrs( "dd[\@name=\"one\"]" );
is_deeply( $aref, { '+' => "dd", name => "one", value => "1" }, 'sub get_config_attrs' );

@l = $sub->get_list( "dd/\@name" );
is_deeply( \@l, [ qw( one two ) ], 'sub get_config_list' );

my @subs = $c->get_sub_list( "/data/ccc/dd" );
is( scalar @subs, 2, 'get_sub_list count' );
is( ref $subs[0], "Config::XPath", 'subconfig[0] ref type' );
is( ref $subs[1], "Config::XPath", 'subconfig[1] ref type' );

is_oneref( $subs[$_], "\$subs[$_] has one reference" ) for 0 .. 1;

$sub = $subs[0];

$s = $sub->get_string( "\@name" );
is( $s, "one", 'subs[0] get_config_string' );

$aref = $sub->get_attrs( "i" );
is_deeply( $aref, { '+' => "i", ord => "first" }, 'subs[0] get_config_attrs' );

@l = $sub->get_list( "i" );
is_deeply( \@l, [ { '+' => "i", ord => "first" } ], 'subs[0] get_config_list' );

warning_is( sub { $sub = $c->get_sub_config( "/data/ccc" ) },
            "Using static function 'get_sub_config' as a method is deprecated",
            'using static function as method gives warning' );

is( ref $sub, "Config::XPath", 'result from static function' );

warning_is( sub { @subs = $c->get_sub_config_list( "/data/ccc/dd" ) },
            "Using static function 'get_sub_config_list' as a method is deprecated",
            'using static function as method gives warning' );

is( scalar @subs, 2, 'result from static list function' );
is( ref $subs[0], "Config::XPath", 'subconfig[0] ref type' );
is( ref $subs[1], "Config::XPath", 'subconfig[1] ref type' );

is_oneref( $c, '$c has one reference at EOF' );
