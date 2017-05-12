#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Carp;

use Bio::Gonzales::Util::Cerial;

use File::Spec;

yspew(File::Spec->catfile($ENV{BIO_GRID_RUN_SGE_TESTDIR}, 'master.qsub.cmd'), \@ARGV);
