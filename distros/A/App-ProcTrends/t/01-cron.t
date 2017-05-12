#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::Exception;
use Data::Dumper;

BEGIN {
    use_ok( 'App::ProcTrends::Cron' ) || print "Bail out!\n";
}

diag( "Testing App::ProcTrends::Cron $App::ProcTrends::Cron::VERSION, Perl $], $^X" );

my $obj;
lives_ok { $obj = App::ProcTrends::Cron->new(); } "constructor test without params";

is( $obj->rrd_dir, "/tmp", "checking default RRD directory" );

my $ref = {
    rrd_dir => "$Bin/test_data",
    timeout => 30, # need to halt operations safely
    rss_unit => 'mb',
};

# requires a new obj because calling new() on the previous object triggers
# DESTROY(), clearing alarm and somehow not reinstalling alarm()
my $obj2 = App::ProcTrends::Cron->new( $ref );

test_attributes( $obj2 );
test_sanitize_cmd( $obj2 );

my $result = $obj2->run_ps();
is( ref( $result ), "HASH", "checking if hashref is returned" );

my @keys = sort keys %{ $result };
is_deeply( \@keys, ['cpu', 'rss'], "checking keys in the result" );

my $rc = $obj2->store_rrd( $result );
is( $rc, 1, "checking return code of store_rrd" );
my @dirs = ( "$Bin/test_data/cpu", "$Bin/test_data/rss" );

for my $dir ( @dirs ) {
    is( -d $dir, 1, "checking if $dir exists" );
}

system( "rm", "-rf", @dirs );
$rc = $? >> 8;

is( $rc, 0, "checking if dir cleaning ended okay" );

done_testing();

sub test_sanitize_cmd {
    my $obj = shift;
    
    my %data = (
        '/usr/libexec/gvfsd-metadata' => 'gvfsd_metadata',
        '/usr/libexec/gvfsd-trash --spawner :1.3 /org/gtk/gvfs/exec_spaw/0' => 'gvfsd_trash_13_0',
        '/usr/bin/ps axo pcpu,rss,args' => 'ps_axo_pcpurssargs',
        '/usr/sbin/abrtd -d -s' => 'abrtd',
        '/sbin/rsyslogd -n -c 7' => 'rsyslogd_7',
        '/usr/bin/ibus-daemon -r --xim' => 'ibus_daemon',
    );
    
    for my $key ( keys %data ) {
        my $val = $data{ $key };

        is( $obj->sanitize_cmd( $key ), $val, "testing for $val" );
    }
}

sub test_attributes {
    my $obj = shift;
    
    isa_ok( $obj, "App::ProcTrends::Cron", "checking object with params" );
    is( $obj->rrd_dir, "$Bin/test_data", "checking RRD directory" );
    is( $obj->timeout, 30, "checking timeout value" );
    like( $obj->ps_cmd, qr/axo pcpu,rss,args/, "checking ps command" );
    like( $obj->cpu_cores, qr/^\d+$/, "checking number of cores" );
    like( $obj->cpu_threshold, qr/^\d+$/, "checking cpu threshold" );
    like( $obj->rss_threshold, qr/^\d+$/, "checking rss threshold" );
    like( $obj->rss_unit, qr/^mb$/i, "checking default unit for RSS" );
    is_deeply( $obj->rrd_rra, [ qw/
        --step=60
        RRA:AVERAGE:0.5:1:23040
        RRA:AVERAGE:0.5:10:9216
        RRA:AVERAGE:0.5:60:18432/ ], "checking rrd create params");
}
