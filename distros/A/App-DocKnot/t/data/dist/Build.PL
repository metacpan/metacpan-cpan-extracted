#!/usr/bin/perl
#
# Build script for an empty module.
#
# Used to test constructing distributions for Perl modules.  This is a minimum
# build script, just enough to support the dist action and let tests run.
#
# Copyright 2018-2019 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    dist_abstract        => 'Empty test module',
    dist_author          => 'Russ Allbery <rra@cpan.org>',
    license              => 'mit',
    module_name          => 'Empty',
    recursive_test_files => 1,
    add_to_cleanup       => [qw(MANIFEST.bak MYMETA.json.lock cover_db)],
    configure_requires   => { 'Module::Build' => 0.36 },
);
$build->create_build_script;
