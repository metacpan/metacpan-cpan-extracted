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
            job->log->info("in: $in_file filt: $filtered_file");

            my $success = 1;
            #filter sequence for low complexity
            $success &&= job->sys("$ENV{HOME}/usr/src/psipred/bin/pfilt $in_file >$filtered_file");
            $success &&= job->sys("$ENV{HOME}/usr/src/psipred/runpsipred $filtered_file");

            return $success;
        },
    }
);

1;
