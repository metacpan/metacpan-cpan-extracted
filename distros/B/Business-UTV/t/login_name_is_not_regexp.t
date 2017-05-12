#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Warn;
use Test::NoWarnings;
use Test::MockObject;
use HTTP::Response;

use Test::More tests => 7;


BEGIN
{ 
	my $mock = Test::MockObject->new();
	$mock->fake_module( "LWP::UserAgent" );
	$mock->fake_new( "LWP::UserAgent" );
	$mock->mock( "post" , sub { return HTTP::Response->new( "200" , "missing a real post" ,  [] , "missing a real post");} );
	
	use_ok( "Business::UTV" );
}

warning_is { Business::UTV::errstr( "foo" ) } "foo" , "Making sure calling errstr creates a warning";
is( $Business::UTV::errstr , "foo" , "Making sure calling errstr set errstr variable to foo" );

my $rc;

warning_is 
		{ 
			$rc = Business::UTV->login( 1 , "not real" , {"name" => "."} );
		} 
		"Login failed : your name '.' not matched" , 
		"Making sure login with name . issues warning that name is not found"; 
	
is( $rc , undef , "Making sure login fails as name is not a reg exp it is a string" );
is( $Business::UTV::errstr  , "Login failed : your name '.' not matched" , "Making sure errstr is set to indicate name not found" );


