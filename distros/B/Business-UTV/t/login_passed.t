#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Warn;
use Test::NoWarnings;
use Test::MockObject;
use HTTP::Response;

use Test::More tests => 6;


BEGIN
{ 
	my $mock = Test::MockObject->new();
	$mock->fake_module( "LWP::UserAgent" );
	$mock->fake_new( "LWP::UserAgent" );
	$mock->mock( "post" , sub { return HTTP::Response->new( "200" , "missing a real post" ,  [] , "missing a real post");} );
	
	use_ok( "Business::UTV" );
}

warning_is { Business::UTV::errstr( "foo" ) } "foo" , "Make sure calling errstr creates a warning";
is( $Business::UTV::errstr , "foo" , "Make sure calling errstr set errstr variable to foo" );

my $rc = Business::UTV->login( 1 , "not real" , {"name" => "a real post"} ); 
	
isa_ok( $rc , "Business::UTV" , "Make sure login succeeds and returns a Business::UTV object" );
is( $Business::UTV::errstr  , undef , "Make sure errstr is undef after sucessful login" );


