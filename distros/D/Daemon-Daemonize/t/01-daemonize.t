#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Path::Class;
use Daemon::Daemonize;
use File::Temp qw/ tempdir /;

my $tmpdir = tempdir( CLEANUP => 1 );

my $shibboleth = $$ + substr int( rand time ), 6;
my $dollar_0 = "d-d-test-$shibboleth";

my $shb_file = file( $tmpdir, $shibboleth )->absolute;

Daemon::Daemonize->daemonize ( run => sub {
    $0 = $dollar_0;
    Daemon::Daemonize->write_pidfile( $shb_file );
    sleep 16;
} );

sleep 1;

ok( -d $tmpdir );
ok( -e $shb_file );
ok( my $pid = Daemon::Daemonize->check_pidfile( $shb_file ) );
diag( "pid is $pid" );
