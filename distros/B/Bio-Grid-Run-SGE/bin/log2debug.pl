#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Carp;

use Bio::Grid::Run::SGE::Log::Worker;

my $file = shift;
my $log = Bio::Grid::Run::SGE::Log::Worker->new(log_file => $file);
$log->to_script(\*STDOUT);
