#!/usr/bin/env perl

use warnings;
use strict;

use Carp;

use Bio::Grid::Run::SGE;

my @ARGSAV = @ARGV;
for ( my $job_id = 1; $job_id < 100; $job_id++ ) {
    $ENV{JOB_ID} = $job_id;
    for ( my $i = 1; $i <= 15; $i++ ) {
        $ENV{SGE_TASK_ID} = $i;
        @ARGV = @ARGSAV;
        run_job( { task => \&do_worker_stuff } );
    }
}

sub do_worker_stuff {
    my ( $c, $result_prefix, $seq_file ) = @_;

    INFO "Running $seq_file -> $result_prefix";
    open my $seq_file_fh, '<', $seq_file or confess "Can't open filehandle: $!";

    open my $result_fh, '>', $result_prefix or confess "Can't open filehandle: $!";
    while (<$seq_file_fh>) {
        print $result_fh lc($_)

    }
    $result_fh->close;
    $seq_file_fh->close;
}

