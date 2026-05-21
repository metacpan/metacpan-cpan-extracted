#!perl

use v5.42.0;

use strict;
use warnings;

use Test2::Require::Module qw< Test::Pod >;
use Test::Pod;

my $EXE = 'bin';

my @DIRS = (
    qw<
        lib
    >
);

push @DIRS, $EXE if -e $EXE && -d $EXE;

all_pod_files_ok( all_pod_files(@DIRS) );
