#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use App::ProcTrends::Cron;

exit( main() );

sub main {
    my $ref = {};

    GetOptions(
        $ref,
        "rrd_dir=s",
        "timeout=i",
        "ps_cmd=s",
        "cpu_cores=i",
        "cpu_threshold=i",
        "rss_threshold=i",
        "rss_unit=s",
        "rrd_ds=s",
        "debug",
    );

    my $obj = App::ProcTrends::Cron->new( $ref );
    my $result = $obj->run_ps();
    return $obj->store_rrd( $result );
}