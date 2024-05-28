#!perl
use strict;
use warnings;
use lib 'lib', 't/lib';
use Feature::Compat::Defer;

use Path::Tiny 0.119;
use Test::More;
use TestArchiveSCS;

# Create test dir structure

my $tempdir = Path::Tiny->tempdir('Archive-SCS-test-XXXXXX');
defer { $tempdir->remove_tree; }

my $ATS = 'American Truck Simulator';
my $ETS2 = 'Euro Truck Simulator 2';

$tempdir->child("steamapps/common/$_")->mkdir for $ATS, $ETS2;
create_hashfs1 $tempdir->child("steamapps/common/$ATS/base.scs"), sample_base;
create_hashfs1 $tempdir->child("steamapps/common/$ETS2/base.scs"), sample_base;

# --game short name / long name

$ENV{STEAM_LIBRARY} = $tempdir;

my $game_version_re = qr/version (?:\d+\.){3}\d/;

like scs_archive(qw[ --version --game ats ]),
  qr/$ATS $game_version_re/, 'ats version';
like scs_archive(qw[ --version -g ets2 ]),
  qr/$ETS2 $game_version_re/, 'ets2 version abbr';

like scs_archive('--version', -g => $ATS),
  qr/$ATS $game_version_re/, 'full name';

# --game file system path

$ENV{STEAM_LIBRARY} = undef;

my $game_dir = $tempdir->child("steamapps/common/$ATS");
like scs_archive('--version', -g => $game_dir),
  qr/$ATS version 0\.0\.0\.0/, 'path';

done_testing;
