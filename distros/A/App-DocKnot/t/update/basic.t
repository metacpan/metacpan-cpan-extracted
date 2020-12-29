#!/usr/bin/perl
#
# Tests for the App::DocKnot::Update module API.
#
# Copyright 2020 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use File::Temp;
use File::Spec;
use Perl6::Slurp qw(slurp);
use Test::RRA qw(is_file_contents);

use Test::More;

# Load the module.
BEGIN { use_ok('App::DocKnot::Update') }

# We have a set of test cases in the data directory.  Each of them contains
# an old directory for the old files and a docknot.yaml file for the results.
my $dataroot = File::Spec->catfile('t', 'data', 'update');
opendir(my $tests, $dataroot);
my @tests = File::Spec->no_upwards(readdir($tests));
closedir($tests);

# For each of those cases, initialize an object, generate the updated
# configuration, and compare it with the test output file.
my $tempdir = File::Temp->newdir();
for my $test (@tests) {
    my $metadata_path = File::Spec->catfile($dataroot, $test, 'old');
    my $expected_path = File::Spec->catfile($dataroot, $test, 'docknot.yaml');
    my $output_path   = File::Spec->catfile($tempdir,  "$test.yaml");
    my $docknot       = App::DocKnot::Update->new(
        {
            metadata => $metadata_path,
            output   => $output_path,
        },
    );
    isa_ok($docknot, 'App::DocKnot::Update', "for $test");
    $docknot->update();
    my $got = slurp($output_path);
    is_file_contents($got, $expected_path, "output for $test");
}

# Check that we ran the correct number of tests.
done_testing(1 + scalar(@tests) * 2);
