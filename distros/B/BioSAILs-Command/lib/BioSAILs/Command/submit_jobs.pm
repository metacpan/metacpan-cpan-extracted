package BioSAILs::Command::submit_jobs;

use v5.10;
use strict;
use warnings FATAL => 'all';
use MooseX::App::Command;
use namespace::autoclean;

extends 'HPC::Runner::Command::submit_jobs';

command_short_description 'Submit jobs to the HPC system';
command_long_description 'This job parses your input file and writes out one or
more templates to submit to the scheduler of your choice (SLURM, PBS, etc)';

__PACKAGE__->meta->make_immutable;

1;
