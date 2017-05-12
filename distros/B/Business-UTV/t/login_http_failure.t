#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Warn;
use Test::NoWarnings;
use Test::MockObject;
use HTTP::Response;

use Test::More tests => 5;


BEGIN
{ 
	my $mock = Test::MockObject->new();
	$mock->fake_module( "LWP::UserAgent" );
	$mock->fake_new( "LWP::UserAgent" );
	$mock->mock( "post" , sub { return HTTP::Response->new( "404" , "missing a real post" ,  [] , "missing a real post");} );
	
	use_ok( "Business::UTV" );
}

my $rc;

warning_is 
		{
			$rc = Business::UTV->login( 1 , "not real" , {"name" => "tester"} ); 
		} 
		"Login failed : http problem" , 
		"Make sure logging in with mock lwp set to fail with http 404 fails with http related error message";
		
is( $rc , undef , "Checking rc to make sure login failed" );
is( $Business::UTV::errstr  , "Login failed : http problem" , "Making sure errstr contains http related error message" );


