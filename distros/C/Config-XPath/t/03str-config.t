#!/usr/bin/perl -w

use strict;

use Test::More tests => 25;
use Test::Exception;
use Test::Refcount;
use Test::Warn;

use Config::XPath;

dies_ok( sub { Config::XPath->new( ) },
         'no filename throws exception' );

my $c;

$c = Config::XPath->new( xml => <<EOXML );
<data>
  <string>Value</string>
  <other attr="one">Two</other>
</data>
EOXML

ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath", 'ref $c' );

my $s;

$s = $c->get_string( "/data/string" );
is( $s, "Value", 'content from inline XML' );

$s = $c->get_string( "/data/string/text()" );
is( $s, "Value", 'content from inline XML by text() node' );

$s = $c->get_string( "/data/other/text()" );
is( $s, "Two", 'content from inline XML by text() node with attrs' );

$s = $c->get_string( "/data/other" );
is( $s, "Two", 'content from inline XML node with attrs' );

$c = Config::XPath->new( filename => "t/data.xml" );
ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath", 'ref $c' );

is_oneref( $c, '$c has one reference' );

$s = $c->get_string( "/data/aaa/bbb" );
is( $s, "Content", 'content' );

$s = $c->get_string( "/data/aaa/\@str" );
is( $s, "hello", 'attribute' );

$s = $c->get_string( "/data/eee/ff[\@name=\"one\"]" );
is( $s, "1", 'content by selector' );

$s = $c->get_string( "/data/ccc/dd[\@name=\"one\"]/\@value" );
is( $s, "1", 'attribute by selector' );

$s = $c->get_string( "name(/data/aaa)" );
is( $s, "aaa", 'function' );

dies_ok( sub { $s = $c->get_string( "/data/nonexistent" ) },
         'nonexistent throws exception' );

lives_and( sub {
              $s = $c->get_string( "/data/nonexistent", default => "somevalue" );
              is( $s, "somevalue" );
           },
           'nonexistent with default' );

dies_ok( sub { $s = $c->get_string( "/data/eee/ff" ) },
         'multiple nodes throws exception' );

dies_ok( sub { $s = $c->get_string( "/data/eee" ) },
         'multiple children throws exception' );

dies_ok( sub { $s = $c->get_string( "/data/ggg" ) },
         'unrepresentable throws exception' );

dies_ok( sub { $s = $c->get_string( "/data/comment()" ) },
         'comment throws exception' );

$s = $c->get_string( "/data/empty" );
is( $s, "", 'empty' );

warning_is( sub { $s = $c->get_config_string( "/data/aaa/bbb" ) },
            "Using static function 'get_config_string' as a method is deprecated",
            'using static function as method gives warning' );

is( $s, "Content", 'content from static function' );

is_oneref( $c, '$c has one reference at EOF' );
