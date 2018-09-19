package main;

use strict;
use warnings;

use Test::More 0.88;

require_ok 'Astro::SIMBAD::Client'
    or BAIL_OUT q{Can't do much testing if can't load module};


my $smb = Astro::SIMBAD::Client->new ();

ok $smb, 'Instantiate Astro::SIMBAD::Client'
    or BAIL_OUT "Test aborted: $@";

is $smb->get( 'debug' ), 0, 'Initial debug setting is 0';

$smb->set( debug => 1 );

is $smb->get( 'debug' ), 1, 'Able to set debug to 1';

$smb->set( debug => 0 );

{
    my $scheme = Astro::SIMBAD::Client::_is_scheme_valid(
	$ENV{ASTRO_SIMBAD_CLIENT_SCHEME} ) ?
	    'http' :
	    lc $ENV{ASTRO_SIMBAD_CLIENT_SCHEME};
    is $smb->get( 'scheme' ), $scheme, "Default scheme is '$scheme'";
}


eval {
    diag join ': ', $smb->__build_url(), scalar $smb->release();
    1;
} or do {
    my $err = $@;
    diag join ': ', $smb->__build_url(), $err;
};

done_testing;

1;
