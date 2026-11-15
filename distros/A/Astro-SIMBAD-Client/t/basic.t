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
    delete local $ENV{ASTRO_SIMBAD_CLIENT_SCHEME};
    my $scheme = $smb->get( 'scheme' );
    is $scheme, 'https', 'Default scheme is https:';
    ok ! Astro::SIMBAD::Client::_is_scheme_valid( $scheme ),
	'Default scheme is valid';
}

done_testing;

1;
