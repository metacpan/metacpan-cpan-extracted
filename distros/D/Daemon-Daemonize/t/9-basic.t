#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

plan skip_all => 'No pgrep available' unless
    eval { system( 'pgrep >/dev/null 2>&1' ) and die; 1 };

plan qw/no_plan/;

use Daemon::Daemonize;

my $shibboleth = $$ + substr int( rand time ), 6;
my $dollar_0 = "d-d-test-$shibboleth";

Daemon::Daemonize->daemonize ( run => sub {
    $0 = $dollar_0;
    for( 0 .. 7 ) {
        print "Hello, World.\n";
        sleep 8;
    }
} );

sleep 4;

if ( my $pid = `pgrep -f $dollar_0` ) {

    ok( $pid );
    diag( "Found $pid" );
#    kill INT => $pid;
#    sleep 1;
#    $pid = `pgrep -f $dollar_0`;
#    ok( ! $pid );
}

1;
