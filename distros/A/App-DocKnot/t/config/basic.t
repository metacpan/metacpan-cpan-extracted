#!/usr/bin/perl
#
# Tests for the App::DocKnot::Config module API.
#
# Copyright 2019-2021 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use File::ShareDir qw(module_file);
use File::Spec;
use YAML::XS ();

use Test::More tests => 5;

# Isolate from the environment.
local $ENV{XDG_CONFIG_HOME} = '/nonexistent';
local $ENV{XDG_CONFIG_DIRS} = '/nonexistent';

# Load the modules.
BEGIN { use_ok('App::DocKnot::Config') }

# Root of the test data.
my $dataroot = File::Spec->catfile('t', 'data', 'generate');

# Load a test configuration and check a few inobvious pieces of it.
my $metadata_path
  = File::Spec->catfile($dataroot, 'ansicolor', 'docknot.yaml');
my $config = App::DocKnot::Config->new({ metadata => $metadata_path });
isa_ok($config, 'App::DocKnot::Config');
my $data_ref = $config->config();
ok($data_ref->{build}{install}, 'build/install defaults to true');

# Check that the license data is expanded correctly.
my $licenses_path = module_file('App::DocKnot', 'licenses.yaml');
my $licenses_ref = YAML::XS::LoadFile($licenses_path);
my $perl_license_ref = $licenses_ref->{Perl};
is($data_ref->{license}{summary}, $perl_license_ref->{summary}, 'summary');
is($data_ref->{license}{text}, $perl_license_ref->{text}, 'text');
