#!/usr/bin/env perl

use warnings;
use strict;
use Carp;

use Bio::Grid::Run::SGE;
use Bio::Grid::Run::SGE::Master;
use Data::Dumper;

run_job(
    {
        task => sub {
            my ( $c, $result_prefix, $in_file ) = @_;

            my $filtered_file = "$result_prefix.filt";
            INFO("in: $in_file filt: $filtered_file");

            my $success = 1;
            #filter sequence for low complexity
            $success &&= my_sys_non_fatal("$ENV{HOME}/usr/src/psipred/bin/pfilt $in_file >$filtered_file");
            $success &&= my_sys_non_fatal("$ENV{HOME}/usr/src/psipred/runpsipred $filtered_file");

            return $success;
        },
    }
);

1;
