use strict;
use warnings;
our $VERSION = 0.003_000;

use Test::More tests => 8;
use File::Spec;
use Capture::Tiny qw( capture_merged );
use Env qw( @PATH );
use IPC::Cmd qw(can_run);
use English qw(-no_match_vars);  # for $OSNAME

use_ok('Alien::astyle');
unshift @PATH, Alien::astyle->bin_dir;

# check if `astyle` can be run, if so get path to binary executable
my $astyle_path = undef;
if ($OSNAME eq 'MSWin32') {
    $astyle_path = can_run('AStyle.exe');
}
else {
    $astyle_path = can_run('astyle');
}
ok(defined $astyle_path, '`astyle` binary path is defined');
isnt($astyle_path, q{}, '`astyle` binary path is not empty');

# run `astyle --version`, check for valid output
my $version = [ split /\r?\n/, capture_merged { system "$astyle_path --version"; }];
cmp_ok((scalar @{$version}), '==', 1, '`astyle --version` executes with 1 line of output');

my $version_0 = $version->[0];
ok(defined $version_0, '`astyle --version` 1 line of output is defined');
is((substr $version_0, 0, 22), 'Artistic Style Version', '`astyle --version` 1 line of output starts correctly');
ok($version_0 =~ m/([\d\.]+)$/xms, '`astyle --version` 1 line of output ends correctly');

my $version_split = [split /[.]/, $1];
my $version_split_0 = $version_split->[0] + 0;
cmp_ok($version_split_0, '==', 2, '`astyle --version` returns major version 2 or newer');
