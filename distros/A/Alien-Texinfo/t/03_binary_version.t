use strict;
use warnings;
our $VERSION = 0.004_000;

use Test::More tests => 6;
use File::Spec;
use Capture::Tiny qw( capture_merged );
use Env qw( @PATH );
use IPC::Cmd qw(can_run);
use English qw(-no_match_vars);  # for $OSNAME

use_ok('Alien::Texinfo');
unshift @PATH, Alien::Texinfo->bin_dir;

# check if `makeinfo` can be run, if so get path to binary executable
my $makeinfo_path = undef;
#if ($OSNAME eq 'MSWin32') {
#    $makeinfo_path = can_run('makeinfo.exe');
#}
#else {
    $makeinfo_path = can_run('makeinfo');
#}
ok(defined $makeinfo_path, '`makeinfo` binary path is defined');
isnt($makeinfo_path, q{}, '`makeinfo` binary path is not empty');

# run `makeinfo --version`, check for valid output
my $version = [ split /\r?\n/, capture_merged { system "$makeinfo_path --version"; }];
cmp_ok((scalar @{$version}), '>=', 1, '`makeinfo --version` executes with at least 1 line of output');

# EXAMPLE: texi2any (GNU texinfo) 6.1
# EXAMPLE: makeinfo (GNU texinfo) 5.2
my $version_0 = $version->[0];
#print {*STDERR} 'in 03_binary_version.t, have $version_0 = ', "\n", '[[[', $version_0, ']]]', "\n";
ok($version_0 =~ m/^\w+\ \(GNU\ texinfo\)\ ([0-9\.]+)$/xms, '`makeinfo --version` 1 line of output is correct');

# DEV NOTE, CORRELATION #at000: require Texinfo v4.x or newer, as of 20171216 Candl uses Texinfo v4.11 & at least 10% of CPAN Testers has Texinfo v4.x
my $version_split = [split /[.]/, $1];
my $version_split_0 = $version_split->[0] + 0;
cmp_ok($version_split_0, '>=', 4, '`makeinfo --version` returns major version 4 or newer');
