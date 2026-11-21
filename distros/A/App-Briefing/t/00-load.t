#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use Test::More;

use lib $FindBin::Bin.'/../lib';

my $app_loaded = use_ok('App::Briefing');
my $filesystem_loaded = use_ok('App::Briefing::Filesystem');
my $cli_loaded = use_ok('App::Briefing::CLI');

SKIP: {
  skip 'version checks need all App::Briefing modules to load', 5
    unless $app_loaded && $filesystem_loaded && $cli_loaded;

  my $distribution_version = $App::Briefing::VERSION;
  ok(defined $distribution_version, 'App::Briefing declares a distribution version');
  ok(
    defined $App::Briefing::Filesystem::VERSION,
    'App::Briefing::Filesystem declares its own version',
  );
  is(
    $App::Briefing::Filesystem::VERSION,
    $distribution_version,
    'App::Briefing::Filesystem matches the distribution version',
  );
  ok(
    defined $App::Briefing::CLI::VERSION,
    'App::Briefing::CLI declares its own version',
  );
  is(
    $App::Briefing::CLI::VERSION,
    $distribution_version,
    'App::Briefing::CLI matches the distribution version',
  );
}

done_testing;
