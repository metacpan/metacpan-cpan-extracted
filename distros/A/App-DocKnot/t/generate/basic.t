#!/usr/bin/perl
#
# Tests for the App::DocKnot::Generate module API.
#
# Copyright 2013, 2016-2020 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use Encode qw(encode);
use File::Spec;
use Test::RRA qw(is_file_contents);

use Test::More;

# Load the module.
BEGIN { use_ok('App::DocKnot::Generate') }

# We have a set of test cases in the data directory.  Each of them contains
# metadata and output directories.
my $dataroot = File::Spec->catfile('t', 'data', 'generate');
opendir(my $tests, $dataroot);
my @tests = File::Spec->no_upwards(readdir($tests));
closedir($tests);
@tests = grep { -e File::Spec->catfile($dataroot, $_, 'docknot.yaml') } @tests;

# For each of those cases, initialize an object from the metadata directory,
# generate file from known templates, and compare that with the corresponding
# output file.
for my $test (@tests) {
    my $metadata_path = File::Spec->catfile($dataroot, $test, 'docknot.yaml');
    my $docknot = App::DocKnot::Generate->new({ metadata => $metadata_path });
    isa_ok($docknot, 'App::DocKnot::Generate', "for $test");

    # Loop through the possible templates.
    for my $template (qw(readme readme-md thread)) {
        my $got  = encode('utf-8', $docknot->generate($template));
        my $path = File::Spec->catfile($dataroot, $test, 'output', $template);
        is_file_contents($got, $path, "$template for $test");
    }
}

# Check that we ran the correct number of tests.
done_testing(1 + scalar(@tests) * 4);
