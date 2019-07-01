#!/usr/bin/perl
#
# Test generated files against the files included in the package.
#
# Copyright 2016, 2018-2019 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use lib 't/lib';

use File::Spec;
use Test::RRA qw(is_file_contents);

use Test::More tests => 5;

# Load the module.
BEGIN { use_ok('App::DocKnot::Generate') }

# Initialize the App::DocKnot object using the default metadata path.
my $docknot = App::DocKnot::Generate->new();
isa_ok($docknot, 'App::DocKnot::Generate');

# Test each of the possible templates.
my $output = $docknot->generate('readme');
is_file_contents($output, 'README', 'README in package');
$output = $docknot->generate('readme-md');
is_file_contents($output, 'README.md', 'README.md in package');
$output = $docknot->generate('thread');
my $dataroot = File::Spec->catfile('t', 'data', 'generate');
my $expected = File::Spec->catfile($dataroot, 'docknot', 'output', 'thread');
is_file_contents($output, $expected, 'Thread output for package');
