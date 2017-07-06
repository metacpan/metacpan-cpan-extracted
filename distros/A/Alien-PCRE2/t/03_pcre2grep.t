use strict;
use warnings;
our $VERSION = 0.011_000;

use Test::More tests => 12;
use File::Spec;
use Capture::Tiny qw( capture_merged );
use Env qw( @PATH );
use IPC::Cmd qw(can_run);
use English qw(-no_match_vars);  # for $OSNAME
#use Data::Dumper;  # DEBUG

use_ok('Alien::PCRE2');
my $pcre2_bin_dir = Alien::PCRE2->bin_dir();
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/03_pcre2grep.t, have $pcre2_bin_dir = '}, $pcre2_bin_dir, q{'}, "\n\n";
#unshift @PATH, Alien::PCRE2->bin_dir;
unshift @PATH, $pcre2_bin_dir;

# check if `pcre2grep` can be run, if so get path to binary executable
my $pcre2_path = undef;
if ($OSNAME eq 'MSWin32') {
#    $pcre2_path = can_run('pcre2grep.exe');  # NEED ANSWER: is this correct???
    $pcre2_path = can_run('pcre2grep');  # NEED ANSWER: is this correct???
}
else {
    $pcre2_path = can_run('pcre2grep');
}
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/03_pcre2grep.t, have $pcre2_path = '}, $pcre2_path, q{'}, "\n\n";
ok(defined $pcre2_path, '`pcre2grep` binary path is defined');
isnt($pcre2_path, q{}, '`pcre2grep` binary path is not empty');

# run `pcre2grep --version`, check for valid output
my $version = [ split /\r?\n/, capture_merged { system $pcre2_path . ' --version'; }];
#print {*STDERR} "\n\n", '<<< DEBUG >>> in t/03_pcre2grep.t, have $version =', Dumper($version), "\n\n";
cmp_ok((scalar @{$version}), '==', 1, '`pcre2grep --version` executes with 1 line of output');

my $version_0 = $version->[0];
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/03_pcre2grep.t, have $version_0 = '}, $version_0, q{'}, "\n\n";
ok(defined $version_0, '`pcre2grep --version` 1 line of output is defined');
is((substr $version_0, 0, 18), 'pcre2grep version ', '`pcre2grep --version` 1 line of output starts correctly');
#ok($version_0 =~ m/([\d\.]+)[\d\.\-\s]*$/xms, '`pcre2grep --version` 1 line of output ends correctly');  # NEED ENABLE: stable releases only
ok($version_0 =~ m/([\d\.]+)-DEV[\d\.\-\s]*$/xms, '`pcre2grep --version` 1 line of output ends correctly');  # NEED DISABLE: unstable pre-release '-DEV' only

my $version_split = [split /[.]/, $1];
#print {*STDERR} "\n\n", '<<< DEBUG >>> in t/03_pcre2grep.t, have $version_split =', Dumper($version_split), "\n\n";
my $version_split_0 = $version_split->[0] + 0;
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/03_pcre2grep.t, have $version_split_0 = '}, $version_split_0, q{'}, "\n\n";
cmp_ok($version_split_0, '>=', 10, '`pcre2grep --version` returns major version 10 or newer');
if ($version_split_0 == 10) {
    my $version_split_1 = $version_split->[1] + 0;
    cmp_ok($version_split_1, '>=', 23, '`pcre2grep --version` returns minor version 23 or newer');
}

# run `pcre2grep Thursday t/_DaysOfWeek.txt`, check for valid output
my $thursday = [ split /\r?\n/, capture_merged { system $pcre2_path . ' Thursday t/_DaysOfTheWeek.txt'; }];
#print {*STDERR} "\n\n", '<<< DEBUG >>> in t/03_pcre2grep.t, have $thursday =', Dumper($thursday), "\n\n";
cmp_ok((scalar @{$thursday}), '==', 1, '`pcre2grep Thursday t/_DaysOfWeek.txt` executes with 1 line of output');

my $thursday_0 = $thursday->[0];
#print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/03_pcre2grep.t, have $thursday_0 = '}, $thursday_0, q{'}, "\n\n";
ok(defined $thursday_0, '`pcre2grep Thursday t/_DaysOfWeek.txt` 1 line of output is defined');
is($thursday_0, q{Thursday, Thor's (Jupiter's) Day}, '`pcre2grep Thursday t/_DaysOfWeek.txt` 1 line of output is valid');
