#!/usr/bin/perl

use strict;
use warnings;

use Cwd qw(realpath);
use DateTime::Format::Natural::Test qw(_find_modules);
use File::Spec::Functions qw(catfile updir);
use FindBin qw($Bin);
use Test::More;

plan skip_all => 'tests for release testing' unless $ENV{RELEASE_TESTING};
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

my @exclude = qw(Duration::Checks);
my @modules;
_find_modules(realpath(catfile($Bin, updir, 'lib')), \@modules, \@exclude);
@modules = sort @modules;
plan tests => scalar @modules;
pod_coverage_ok($_) foreach @modules;
