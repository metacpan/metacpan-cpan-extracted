#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use File::RandomGenerator;

use constant DATA_DIR => '/tmp/backup_ez_testdata';

my $data_dir = shift @ARGV;
if (!$data_dir) {
    $data_dir = DATA_DIR;
}

system("mkdir -p $data_dir/dir1");

my $frg = File::RandomGenerator->new(
    root_dir => "$data_dir/dir1",
    unlink   => 0,
);
$frg->generate;

system("mkdir -p $data_dir/dir2");

$frg->root_dir("$data_dir/dir2");
$frg->generate;
