#!/usr/bin/perl

# Tests that the version of the script is the same as the one of the module.

use strict;
use warnings;

use Test2::V0;

use App::UpdateConfig;
use FindBin;
use lib "${FindBin::Bin}/lib";
use UpdateConfigTest;

our $VERSION = 0.01;

my $script = UpdateConfigTest::read_file("${FindBin::Bin}/../script/update_config");
my ($script_version) = $script =~ m/^our[ ]\$VERSION[ ]=[ ]'([^']+)';$/mx;
is($script_version, $App::UpdateConfig::VERSION, 'script and module have the same version');

done_testing;
