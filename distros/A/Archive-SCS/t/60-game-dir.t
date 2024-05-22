#!perl
use strict;
use warnings;
use lib 'lib';

use Feature::Compat::Defer;
use Path::Tiny 0.119;
use Test::More;

use Archive::SCS::GameDir;

my $tempdir = Path::Tiny->tempdir('Archive-SCS-test-XXXXXX');
defer { $tempdir->remove_tree; }

# Create test dir structure

my $ATS = 'American Truck Simulator';
my $ETS2 = 'Euro Truck Simulator 2';

my $ats = $tempdir->child('ats');
my $both = $tempdir->child('both');
$ats->child("steamapps/common/$ATS/base.scs")->touchpath;
$both->child("steamapps/common/$_/base.scs")->touchpath for $ATS, $ETS2;

# Can we control the search paths?

@Archive::SCS::GameDir::LIBRARY_PATHS = ();
my $gd = Archive::SCS::GameDir->new;
is_deeply [$gd->library_paths], [], 'paths init from vars';

$gd->set_library_paths( my @paths = ($both, $ats) );
is_deeply [$gd->library_paths], [@paths], 'set paths';

# Does the search find what we want?

ok $both->subsumes( $gd->find->path ), 'find any';
is $gd->game, $ATS, 'found any alphabetically';
ok $both->subsumes( $gd->find('ats')->path ), 'find ATS in both';
is $gd->game, $ATS, 'found is ATS';
is $gd->game_short, 'ATS', 'abbr is ATS';
ok $both->subsumes( $gd->find('ETS2')->path ), 'find ETS2 in both';
is $gd->game, $ETS2, 'found is ETS2';
is $gd->game_short, 'ETS2', 'abbr is ETS2';

$gd->set_library_paths($ats, $both);
ok $ats->subsumes( $gd->find('ATS')->path ), 'find ATS in ats';
ok $both->subsumes( $gd->find('ets2')->path ), 'find ETS2, ats first';

$gd->set_library_paths($ats);
ok $ats->subsumes( $gd->find('ATS')->path ), 'find ATS, ats only ';
ok ! defined $gd->find('ETS2')->path, 'no find ETS2, ats only';
ok ! defined $gd->find('LiS')->path, 'no find LiS';
ok ! defined $gd->game, 'LiS game undef';
ok ! defined $gd->game_short, 'LiS abbr undef';

# Does adjust do what we ask?

@Archive::SCS::GameDir::LIBRARY_PATHS = ($ats);

$gd = Archive::SCS::GameDir->new;
is $gd->path, $ats->child("steamapps/common/$ATS"), 'new any path';
is $gd->game, $ATS, 'new any game';

$gd = Archive::SCS::GameDir->new(game => 'ATS');
is $gd->path, $ats->child("steamapps/common/$ATS"), 'new ATS path';
is $gd->game, $ATS, 'new ATS game';

$gd = Archive::SCS::GameDir->new(game => 'ETS2');
ok ! defined $gd->path, 'new ETS2 path';
ok ! defined $gd->game, 'new ETS2 game';

done_testing;
