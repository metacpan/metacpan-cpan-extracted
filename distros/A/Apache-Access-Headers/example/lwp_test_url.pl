#!/usr/bin/perl

# $Id$

use LWP::UserAgent ;

use HTTP::Request ;
use HTTP::Headers ;

my $BASE_URL = 'http://perl.rulez.com' ; 

my @tests = ( 
	{ url => '/one/', header => 'X-One', value => '1' },
	{ url => '/two/', header => 'X-Two', value => '1' },
	{ url => '/three/', header => 'X-Three', value => '1' },
	{ url => '/one/', header => 'X-Two', value => '1' },
	{ url => '/two/', header => 'X-Three', value => '1' },
	{ url => '/three/', header => 'X-One', value => '1' },
	{ url => '/referer/', header => 'X-Zero', value => '1', 'referer' => 'http://volcano.rulez.com' },
) ;

foreach my $t ( @tests )
{
	print "Requesting URL: ", $t->{'url'}, " --> " ;
	
	my $headers = HTTP::Headers->new() ;
	$headers->header( $t->{'header'} => $t->{'value'} ) ;
	
	$headers->referer( $t->{'referer'} ) if ( $t->{'referer'} ) ;
	
	my $request = HTTP::Request->new( 'GET', $BASE_URL . $t->{'url'}, $headers ) ;
	
	my $ua = LWP::UserAgent->new() ;
	my $response = $ua->request( $request ) ;
	
	if ( $response->is_success() )
	{
		print "Success\n" ;
	}
	else
	{
		print "Error ", $response->code(), "\n" ;
	}
}

exit ;

