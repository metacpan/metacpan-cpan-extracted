#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Warn;
use Test::NoWarnings;
use Test::MockObject;
use HTTP::Response;

use Test::More tests => 42;


BEGIN
{
	my $mock = Test::MockObject->new();
	$mock->fake_module( "LWP::UserAgent" );
	$mock->fake_new( "LWP::UserAgent" );
	$mock->set_series( "post" , 
				HTTP::Response->new( "200" , "missing a real post" ,  [] , "missing a real post" )
			);
	$mock->set_series( "get" , 
				HTTP::Response->new( "500" , "missing a real post" ,  [] , "server error" ),
				HTTP::Response->new( "200" , "missing a real post" ,  [] , "nothing to see" ),
				HTTP::Response->new( "200" , "missing a real post" ,  [] , 
						"Incoming: 12.1MB" ),
				HTTP::Response->new( "200" , "missing a real post" ,  [] ,
						"Outgoing: 21.0MB" ),
				HTTP::Response->new( "200" , "missing a real post" ,  [] ,
						"Incoming:131.12MB Outgoing:  124.230MB" ),
				HTTP::Response->new( "200" , "missing a real post" ,  [] ,
						"Incoming: 12MB Outgoing: 630.00MB" ),
				HTTP::Response->new( "200" , "missing a real post" ,  [] ,
						"Incoming:12.01MB) Outgoing: 98MB" ),
				HTTP::Response->new( "200" , "missing a real post" ,  [] ,
						"Incoming:0MB Outgoing: 0MB" )
			);

	use_ok( "Business::UTV" );
}

warning_is { Business::UTV::errstr( "foo" ) } "foo" , "Make sure calling errstr create a warning";
is( $Business::UTV::errstr , "foo" , "Make sure calling errstr set errstr variable to foo" );

my $rc = Business::UTV->login( 1 , "not real" , {"name" => "a real post"} ); 
	
isa_ok( $rc , "Business::UTV" , "Make sure login succeeds and returns a Business::UTV object" );
is( $Business::UTV::errstr  , undef , "Make sure errstr is undef after sucessful login" );


warning_is { $rc->usage() } "Usage failed : http problem" , "Make sure first usage fails as this returns http 500";
is( $Business::UTV::errstr  , "Usage failed : http problem"  , "Make sure usage failure is recorded in errstr" );

test_failure( "Make sure usage fails as nothing is available" );
test_failure( "Make sure usage fails as only upload is available" );
test_failure( "Make sure usage fails as only download is available" );

test_success( "131.12" , "124.230" , "Make sure spaces are optional and more than one is allowed" );
test_success( "12" , "630.00" , "Make sure integer upload is allowed and trailing 0 is preserved" );
test_success( "12.01" , "98" , "Make sure integer download is allowed" );

test_success( "0" , "0" , "Make sure zero upload and download is allowed" );

sub test_failure
{
	my ( $test ) = @_;
	
	warning_is { $rc->usage() } "Could not retrieve upload and download usage" , $test;
	is( $Business::UTV::errstr  , "Could not retrieve upload and download usage" , "Making sure usage failure is recorded in errstr" );
}

sub test_success
{
	my ( $upload , $download ) = @_;
	
	my $usage = $rc->usage();
	isnt( $usage , undef , "Make sure successful return from usage is not undef" );
	is( ref( $usage ) , "HASH" , "Make sure successful return from usage is a hash" );
	ok( $usage->{"upload"} == $upload , "Make sure upload is == $upload" );
	ok( $usage->{"upload"} eq $upload , "Make sure upload is eq $upload" );
	ok( $usage->{"download"} == $download , "Make sure download == $download" );
	ok( $usage->{"download"} eq $download , "Make sure download eq $download" );
	is( $Business::UTV::errstr , undef  , "Make sure errstr is reset on success" );
}
