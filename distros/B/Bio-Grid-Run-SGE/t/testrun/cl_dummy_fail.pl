#!/usr/bin/env perl
#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

use warnings;
use strict;

use Carp;

use Bio::Grid::Run::SGE;

run_job(
    {
        config => {
            idx_format => 'General',
            record_sep => '^>',
        },

        task => \&do_worker_stuff
    }
);

sub do_worker_stuff {
    my ( $c, $result_prefix, $seq_file ) = @_;

    INFO "Running $seq_file -> $result_prefix";

    my ( $real_job_id, $task_id ) = split( /\./, $c->{job_id}, 2 );
    sleep 7;
    open my $seq_fh, '<', $seq_file      or confess "Can't open filehandle: $!";
    open my $res_fh, '>', $result_prefix or confess "Can't open filehandle: $!";
    while (<$seq_fh>) {
        chomp;
        if (/^>/) {
            print $res_fh uc($_) . " job_id_" . $c->{job_id} . "\n";
        } else {
            print $res_fh uc($_) . " AGCTNNN\n";
        }
    }
    $res_fh->close;
    $seq_fh->close;
    if ( $task_id % 2 == 0 ) {
        return my_sys_non_fatal("cp $seq_file $result_prefix.orig");
    } else {
        return my_sys_non_fatal("cp");
    }
}
