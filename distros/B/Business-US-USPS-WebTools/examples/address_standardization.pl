#!/usr/bin/perl

use Business::US::USPS::WebTools::AddressStandardization;

my $verifier = Business::US::USPS::WebTools::AddressStandardization->new( {
	UserID   => $ENV{USPS_WEBTOOLS_USERID},
	Password => $ENV{USPS_WEBTOOLS_PASSWORD},
#	Testing  => 1,
	} );

my $address1 = prompt( "Address1" );
my $address2 = prompt( "Address2" );
my $city     = prompt( "City" );
my $state    = prompt( "State" );
my $zip5     = prompt( "Zip Code" );

my $hash = $verifier->verify_address(
	FirmName => '',
	Address1 => $address1,
	Address2 => $address2,
	City     => $city,  
	State    => $state,
	Zip5     => $zip5,
	Zip4     => '',
	);

if( $verifier->is_error )
	{
	warn "Oops!\n";
	print $verifier->response;
	print "\n";
	}
else
	{
	print <<"HERE";
$hash->{FirmName}
$hash->{Address1}
$hash->{Address2}
$hash->{City}   
$hash->{State}  
$hash->{Zip5}   
$hash->{Zip4}  
HERE
	}

sub prompt
	{
	my $prompt = shift;
	
	print "$prompt > ";
	
	my $line = <STDIN>;
	chomp( $line );
	
	$line;
	}