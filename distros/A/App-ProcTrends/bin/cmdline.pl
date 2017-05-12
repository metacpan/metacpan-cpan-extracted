#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use App::ProcTrends::Commandline;

exit( main() );

sub main {
    my $ref = {};

    GetOptions(
        $ref,
        "start=s",
        "end=s",
        "interval=i",
        "procs=s",
        "command=s",
        "rrd_dir=s",
        "out_dir=s",
        "debug",
    );

    my $obj = App::ProcTrends::Commandline->new( $ref );
    my $command = $obj->command();
    
    my $handler = "${command}_handler";
    if ( $obj->can( $handler ) ) {
        $obj->$handler();
    }
    else {
        die "command $command not supported\n";
    }
}