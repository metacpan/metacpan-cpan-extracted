#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 16;
BEGIN { use_ok( 'Apache::Sling::URL' ); }

ok( ! defined Apache::Sling::URL::add_leading_slash(), 'Check add_leading_slash function' );
ok( Apache::Sling::URL::add_leading_slash( 'value' ) eq '/value', 'Check add_leading_slash function' );
ok( Apache::Sling::URL::add_leading_slash( '/value' ) eq '/value', 'Check add_leading_slash function' );
ok( ! defined Apache::Sling::URL::strip_leading_slash(), 'Check add_leading_slash function' );
ok( Apache::Sling::URL::strip_leading_slash( 'value' ) eq 'value', 'Check add_leading_slash function' );
ok( Apache::Sling::URL::strip_leading_slash( '/value' ) eq 'value', 'Check add_leading_slash function' );
my @properties;
ok( Apache::Sling::URL::properties_array_to_string( \@properties ) eq '', 'Check properties_array_to_string function empty array' );
@properties = ('a=');
ok( Apache::Sling::URL::properties_array_to_string( \@properties ) eq "'a',''", 'Check properties_array_to_string function 1 blank item' );
@properties = ('a=b');
ok( Apache::Sling::URL::properties_array_to_string( \@properties ) eq "'a','b'", 'Check properties_array_to_string function 1 item' );
push @properties, "c\'=d";
ok( Apache::Sling::URL::properties_array_to_string( \@properties ) eq "'a','b','c\\'','d'", 'Check properties_array_to_string function 2 items' );
ok( Apache::Sling::URL::urlencode( "'%^&*" ) eq '%27%25%5E%26%2A', 'Check urlencode function' );
ok( Apache::Sling::URL::url_input_sanitize() eq 'http://localhost:8080', 'Check url_input_sanitize function undefined' );
ok( Apache::Sling::URL::url_input_sanitize('') eq 'http://localhost:8080', 'Check url_input_sanitize function empty' );
ok( Apache::Sling::URL::url_input_sanitize('http://localhost:8080/') eq 'http://localhost:8080', 'Check url_input_sanitize function trailing slash' );
ok( Apache::Sling::URL::url_input_sanitize('localhost:8080/') eq 'http://localhost:8080', 'Check url_input_sanitize function trailing slash and http' );
