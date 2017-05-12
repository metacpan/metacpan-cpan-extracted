#!/usr/bin/perl
use Test::More;

use strict;
use warnings;

eval "use Digest::MD5";
plan skip_all => "Digest::MD5 required for this test" if $@;

plan tests => 17;

use_ok('CGI::Application::Plugin::Authentication::Driver::Filter::md5');
my $class = 'CGI::Application::Plugin::Authentication::Driver::Filter::md5';

# Test binary
my $binary = Digest::MD5::md5('123');
is( $class->filter( 'binary', '123' ), $binary, "filter" );
ok( $class->check( 'binary',  '123', $binary ), "check passes" );
ok( !$class->check( 'binary', 'xxx', $binary ), "check fails" );
ok( $class->check( undef,     '123', $binary ), "check passes" );
ok( !$class->check( undef,    'xxx', $binary ), "check fails" );

# Test base64
is( $class->filter( 'base64', '123' ), 'ICy5YqxZB1uWSwcVLSNLcA', "filter" );
ok( $class->check( 'base64', '123', 'ICy5YqxZB1uWSwcVLSNLcA' ),
  "check passes" );
ok( !$class->check( 'base64', 'xxx', 'ICy5YqxZB1uWSwcVLSNLcA' ),
  "check fails" );
ok( $class->check( undef, '123', 'ICy5YqxZB1uWSwcVLSNLcA' ), "check passes" );
ok( !$class->check( undef, 'xxx', 'ICy5YqxZB1uWSwcVLSNLcA' ), "check fails" );

# Test hex
is( $class->filter( 'hex', '123' ),
  '202cb962ac59075b964b07152d234b70', "filter" );
ok( $class->check( 'hex', '123', '202cb962ac59075b964b07152d234b70' ),
  "check passes" );
ok( !$class->check( 'hex', 'xxx', '202cb962ac59075b964b07152d234b70' ),
  "check fails" );
is( $class->filter( undef, '123' ),
  '202cb962ac59075b964b07152d234b70', "filter" );
ok( $class->check( undef, '123', '202cb962ac59075b964b07152d234b70' ),
  "check passes" );
ok( !$class->check( undef, 'xxx', '202cb962ac59075b964b07152d234b70' ),
  "check fails" );

