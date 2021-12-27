#!/usr/bin/perl
#
# Tests for license metadata.
#
# Copyright 2017-2018, 2020-2021 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use File::ShareDir qw(module_file);
use Kwalify qw(validate);
use Test::More tests => 2;
use YAML::XS ();

# Isolate from the environment.
local $ENV{XDG_CONFIG_HOME} = '/nonexistent';
local $ENV{XDG_CONFIG_DIRS} = '/nonexistent';

# Load the module.
BEGIN { use_ok('App::DocKnot') }

# Check the schema of the licenses.yaml file.
my $licenses_path = module_file('App::DocKnot', 'licenses.yaml');
my $licenses_ref = YAML::XS::LoadFile($licenses_path);
my $schema_path = module_file('App::DocKnot', 'schema/licenses.yaml');
my $schema_ref = YAML::XS::LoadFile($schema_path);
eval { validate($schema_ref, $licenses_ref) };
is($@, q{}, 'licenses.yaml fails schema validation');
