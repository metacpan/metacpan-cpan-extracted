#!/usr/bin/perl
#
# Tests for the App::DocKnot module API.
#
# Copyright 2013, 2016-2018 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use File::Spec;
use Test::RRA qw(is_file_contents);

use Test::More;

# Load the module.
BEGIN { use_ok('App::DocKnot') }

# We have a set of test cases in the data directory.  Each of them contains
# metadata and output directories.
my $dataroot = File::Spec->catfile('t', 'data');
opendir(my $tests, File::Spec->catfile('t', 'data'));
my @tests = File::Spec->no_upwards(readdir($tests));
closedir($tests);
@tests = grep { -d File::Spec->catfile($dataroot, $_, 'metadata') } @tests;

# For each of those cases, initialize an object from the metadata directory,
# generate file from known templates, and compare that with the corresponding
# output file.
for my $test (@tests) {
    my $metadata_path = File::Spec->catfile($dataroot, $test, 'metadata');
    my $docknot = App::DocKnot->new({ metadata => $metadata_path });
    isa_ok($docknot, 'App::DocKnot', "for $test");

    # Loop through the possible templates.
    for my $template (qw(readme readme-md thread)) {
        my $got = $docknot->generate($template);
        my $path = File::Spec->catfile($dataroot, $test, 'output', $template);
        is_file_contents($got, $path, "$template for $test");
    }
}

# Check that we ran the correct number of tests.
done_testing(1 + scalar(@tests) * 4);
