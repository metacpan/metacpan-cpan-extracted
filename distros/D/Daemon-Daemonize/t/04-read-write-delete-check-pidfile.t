#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use t::Test;
use Daemon::Daemonize;
use Path::Class;

my ( $tmpdir, $shibboleth, $dollar_0, $shb_file ) = t::Test->shb_setup;

my $shb1_file = file( $tmpdir, 'shb1' );

Daemon::Daemonize->daemonize (
    run => sub {
        $0 = $dollar_0;
        Daemon::Daemonize->write_pidfile( $shb_file );
        my $fh = $shb1_file->openw;
        $fh->print( "$$\n" );
        $fh->close;
        sleep 8;
} );

sleep 1;

ok( -d $tmpdir );
ok( -e $shb_file );
ok( my $pid = Daemon::Daemonize->check_pidfile( $shb_file ) );
ok( my $pid1 = Daemon::Daemonize->check_pidfile( $shb1_file ) );
is( $pid, $pid1 );
diag( "pid is $pid is $pid1" );

is( Daemon::Daemonize->read_pidfile( $shb_file ), $pid );
is( Daemon::Daemonize->read_pidfile( $shb1_file ), $pid );
is( Daemon::Daemonize->read_pidfile( '/root' ), undef );
is( Daemon::Daemonize->read_pidfile( '/.__non-existent-file__' ), undef );

Daemon::Daemonize->write_pidfile( $shb1_file );
is( Daemon::Daemonize->read_pidfile( $shb1_file ), $$ );
Daemon::Daemonize->write_pidfile( $shb1_file, $$ + 1 );
is( Daemon::Daemonize->read_pidfile( $shb1_file ), $$ + 1 );

is( Daemon::Daemonize->check_pidfile( $shb_file ), $pid );
is( Daemon::Daemonize->check_pidfile( '/root' ), 0 );
is( Daemon::Daemonize->check_pidfile( '/.__non-existent-file__' ), 0 );

Daemon::Daemonize->delete_pidfile( $shb1_file );
ok( ! -e $shb1_file );
is( Daemon::Daemonize->read_pidfile( $shb1_file ), undef );

kill INT => $pid;

sleep 1;

ok( -e $shb_file );
is( Daemon::Daemonize->check_pidfile( $shb_file ), 0 );
