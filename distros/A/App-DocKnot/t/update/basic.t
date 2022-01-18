#!/usr/bin/perl
#
# Tests for the App::DocKnot::Update module API.
#
# Copyright 2020-2022 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Path::Tiny qw(path);
use Test::RRA qw(is_file_contents);

use Test::More;

# Isolate from the environment.
local $ENV{XDG_CONFIG_HOME} = '/nonexistent';
local $ENV{XDG_CONFIG_DIRS} = '/nonexistent';

# Load the module.
BEGIN { use_ok('App::DocKnot::Update') }

# We have a set of test cases in the data directory.  Each of them contains
# an old directory for the old files and a docknot.yaml file for the results.
my $dataroot = path('t', 'data', 'update');
my @tests = map { $_->basename() } $dataroot->children();

# For each of those cases, initialize an object, generate the updated
# configuration, and compare it with the test output file.
my $tempdir = Path::Tiny->tempdir();
for my $test (@tests) {
    my $metadata_path = $dataroot->child($test, 'old');
    my $expected_path = $dataroot->child($test, 'docknot.yaml');
    my $output_path = $tempdir->child("$test.yaml");
    my $docknot = App::DocKnot::Update->new(
        { metadata => $metadata_path, output => $output_path },
    );
    isa_ok($docknot, 'App::DocKnot::Update', "for $test");
    $docknot->update();
    my $got = $output_path->slurp();
    is_file_contents($got, $expected_path, "output for $test");
}

# Check that we ran the correct number of tests.
done_testing(1 + scalar(@tests) * 2);
