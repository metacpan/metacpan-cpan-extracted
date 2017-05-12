#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use t::Test;
use Daemon::Daemonize qw/ :all /;
use Path::Class;

my ( $tmpdir, $shibboleth, $dollar_0, $shb_file ) = t::Test->shb_setup;

my $stdout = file( $tmpdir, 'stdout' );
my $stderr = file( $tmpdir, 'stderr' );

$ENV{DAEMON_DAEMONIZE_STDOUT} = "$stdout";
$ENV{DAEMON_DAEMONIZE_STDERR} = "$stderr";

daemonize (
    run => sub {
        $0 = $dollar_0;
        write_pidfile( $shb_file );
        print STDOUT "Stdout!\n";
        print STDERR "Stderr!\n";
        sleep 8;
} );

sleep 1;

ok( -d $tmpdir );
ok( -e $shb_file );
ok( my $pid = check_pidfile( $shb_file ) );
diag( "pid is $pid" );

is( scalar $stdout->slurp, "Stdout!\n" );
is( scalar $stderr->slurp, "Stderr!\n" );
