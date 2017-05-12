#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;
use Test::Refcount;

use Config::XPath;

my $c;

$c = Config::XPath->new( ioref => \*DATA );

ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath", 'ref $c' );

is_oneref( $c, '$c has one reference' );

my $s;

$s = $c->get_string( "/data/string" );
is( $s, "Value", 'content from inline XML' );

is_oneref( $c, '$c has one reference at EOF' );

__DATA__
<data>
  <string>Value</string>
</data>
