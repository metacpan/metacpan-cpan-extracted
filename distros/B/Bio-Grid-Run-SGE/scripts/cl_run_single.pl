#!/usr/bin/env perl

use warnings;
use strict;

use Carp;

use Bio::Grid::Run::SGE;
use Bio::Grid::Run::SGE::Master;
use Data::Dumper;
use Bio::Gonzales::Util::File qw/slurpc/;

run_job(
    {
        task => sub {
            my ( $c, $result_prefix, $cmd_in_file ) = @_;

            my $cmd = (slurpc($cmd_in_file))[0];
            job->log->info("running $cmd");
            my $success = job->sys($cmd);

            return $success;
        },
    }
);

1;

