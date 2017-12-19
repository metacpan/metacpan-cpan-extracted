use strict;
use warnings;
our $VERSION = 0.001_000;

use Test::More tests => 8;
use File::Spec;
use Capture::Tiny qw( capture_merged );
use Env qw( @PATH );
use IPC::Cmd qw(can_run);
use English qw(-no_match_vars);  # for $OSNAME

use_ok('Alien::Pluto');
unshift @PATH, Alien::Pluto->bin_dir;

# check if `pluto` can be run, if so get path to binary executable
my $pluto_path = undef;
#if ($OSNAME eq 'MSWin32') {
#    $pluto_path = can_run('pluto.exe');
#}
#else {
    $pluto_path = can_run('pluto');
#}
ok(defined $pluto_path, '`pluto` binary path is defined');
isnt($pluto_path, q{}, '`pluto` binary path is not empty');

# run `pluto --version`, check for valid output
my $version = [ split /\r?\n/, capture_merged { system "$pluto_path --version"; }];
cmp_ok((scalar @{$version}), '>=', 1, '`pluto --version` executes with at least 1 line of output');

# EXAMPLE: PLUTO 0.11.4 - An automatic parallelizer and locality optimizer
my $version_0 = $version->[0];
#print {*STDERR} 'in 03_binary_version.t, have $version_0 = ', "\n", '[[[', $version_0, ']]]', "\n";
ok($version_0 =~ m/^PLUTO\ ([0-9\.]+)\ -\ An\ automatic\ parallelizer\ and\ locality\ optimizer$/xms, '`pluto --version` 1 line of output is correct');

my $version_split = [split /[.]/, $1];
my $version_split_0 = $version_split->[0] + 0;
cmp_ok($version_split_0, '>=', 0, '`pluto --version` returns major version 0 or newer');
if ($version_split_0 == 0) {
    my $version_split_1 = $version_split->[1] + 0;
    cmp_ok($version_split_1, '>=', 11, 'Command `pluto --version` returns sub-major version 11 or newer');
    if ($version_split_1 == 11) {
        my $version_split_2 = $version_split->[2] + 0;
        cmp_ok($version_split_2, '>=', 4, 'Command `pluto --version` returns minor version 4 or newer');
    }
}
