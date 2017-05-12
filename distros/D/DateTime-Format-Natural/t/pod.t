#!/usr/bin/perl

use strict;
use warnings;

use Cwd qw(realpath);
use DateTime::Format::Natural::Test qw(_find_files);
use File::Spec::Functions qw(abs2rel catfile updir);
use FindBin qw($Bin);
use Test::More;

plan skip_all => 'tests for release testing' unless $ENV{RELEASE_TESTING};
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;

my @exclude = qw(Duration::Checks);
my @files;
_find_files(realpath(catfile($Bin, updir, 'lib')), \@files, \@exclude);
@files = sort map abs2rel($_), @files;
plan tests => scalar @files;
pod_file_ok($_) foreach @files;
