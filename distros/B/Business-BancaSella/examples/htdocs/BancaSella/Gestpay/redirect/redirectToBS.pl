#!/usr/bin/perl

use CGI;
use URI::BancaSella::Encode;

my $cgi = new CGI();

my $YOUR_SERVER_WEB	= 'pc100.it';

my $bs 		= new URI::BancaSella::Encode(	type		=> $cgi->param('type'),
						shopping	=> $cgi->param('shopping'),
						amount		=> $cgi->param('amount'),
						language	=> 'italian',
						currency	=> 'itl',
						otp		=> 'another_otp',
						id		=> 'internal_id'
						);

# this is only for test...remove if using bancaSella true gateway
$bs->base_url("http://$YOUR_SERVER_WEB/BancaSella/Gestpay/bsSimul/bsSimul.pl");
my $bsUrl 	= $bs->uri;	

print $cgi->redirect($bsUrl);
