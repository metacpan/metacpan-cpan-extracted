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
	$mock->mock( "post" , sub { return HTTP::Response->new( "200" , "missing a real post" ,  [] , "missing a real post");} );
	
	use_ok( "Business::UTV" );
}

my $rc;

warning_is 
		{
			$rc = Business::UTV->login( 1 , "not real" , {"name" => "tester"} ); 
		} 
		"Login failed : your name 'tester' not matched",
		"Make sure logging in with mock lwp set to succeed but not return expected username fails with name related warning";
		
is( $rc , undef , "Make sure rc is undef" );
is( $Business::UTV::errstr  , "Login failed : your name 'tester' not matched" , "Make sure errstr contains name related error message" );


