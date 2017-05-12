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

eval {
    diag join ': ', $smb->get( 'server' ), scalar $smb->release();
    1;
} or do {
    my $err = $@;
    diag join ': ', $smb->get( 'server' ), $err;
};

done_testing;

1;
