#!perl
use strict;
use warnings;
use lib 'lib';
use blib;

use List::Util 1.33 'any';
use Test::More;

use Archive::SCS::GameDir;

my $gamedir = Archive::SCS::GameDir->new;
$gamedir->path or plan skip_all => 'ATS or ETS2 not found';

my @files = $gamedir->archives;
my @archives = qw( core.scs def.scs dlc_dragon.scs );
for my $archive (@archives) {
  ok !!( any { $archive eq $_ } @files ), "found $archive";
}

my $scs = $gamedir->mounted(@archives);
is $scs->entry_mounts(''), 3, 'mounts'; # root dir

ok $scs->list_dirs > 1000, 'dirs';

my $version = $gamedir->version;
like $version, qr/^(?:\d+\.){3}\d/, 'version';
diag sprintf "%s %s", $gamedir->game_short, $version;

done_testing;
