use strict;
use warnings;
our $VERSION = 0.020_000;

use Test2::V0;
use Test::Alien;
use Alien::PCRE2;
use English qw(-no_match_vars);  # for $OSNAME
use Data::Dumper;  # DEBUG

plan(10);

# load alien
alien_ok('Alien::PCRE2', 'Alien::PCRE2 loads successfully and conforms to Alien::Base specifications');

# test version flag
my $run_object = run_ok([ 'pcre2grep', '--version' ], 'Command `pcre2grep --version` runs');
print {*STDERR} "\n", q{<<< DEBUG >>> in t/03_pcre2grep.t, have $run_object->out() = }, Dumper($run_object->out()), "\n";
print {*STDERR} "\n", q{<<< DEBUG >>> in t/03_pcre2grep.t, have $run_object->err() = }, Dumper($run_object->err()), "\n";
$run_object->success('Command `pcre2grep --version` runs successfully');
is((substr $run_object->out(), 0, 18), 'pcre2grep version ', 'Command `pcre2grep --version` output starts correctly');
# DEV NOTE: can't use out_like() on the next line because it does not properly capture to $1, as used in the following split
ok($run_object->out() =~ m/([\d\.]+)(?:-DEV)?[\d\.\-\s]*$/xms, 'Command `pcre2grep --version` runs with valid output');

# test actual version numbers
my $version_split = [split /[.]/, $1];
print {*STDERR} "\n", q{<<< DEBUG >>> in t/03_pcre2grep.t, have $version_split = }, Dumper($version_split), "\n";
my $version_split_0 = $version_split->[0] + 0;
print {*STDERR} "\n", q{<<< DEBUG >>> in t/03_pcre2grep.t, have $version_split_0 = '}, $version_split_0, q{'}, "\n";
cmp_ok($version_split_0, '>=', 10, 'Command `pcre2grep --version` returns major version 10 or newer');
if ($version_split_0 == 10) {
    my $version_split_1 = $version_split->[1] + 0;
    cmp_ok($version_split_1, '>=', 23, 'Command `pcre2grep --version` returns minor version 23 or newer');
}

# run `pcre2grep Thursday t/_DaysOfWeek.txt`, check for valid output
$run_object = run_ok([ 'pcre2grep', 'Thursday', 't/_DaysOfTheWeek.txt' ], 'Command `pcre2grep Thursday t/_DaysOfTheWeek.txt` runs');
print {*STDERR} "\n", q{<<< DEBUG >>> in t/03_pcre2grep.t, have $run_object->out() = }, Dumper($run_object->out()), "\n";
print {*STDERR} "\n", q{<<< DEBUG >>> in t/03_pcre2grep.t, have $run_object->err() = }, Dumper($run_object->err()), "\n";
$run_object->success('Command `pcre2grep Thursday t/_DaysOfTheWeek.txt` runs successfully');
is($run_object->out(), q{Thursday, Thor's (Jupiter's) Day} . "\n", '`pcre2grep Thursday t/_DaysOfWeek.txt` 1 line of output is valid');

done_testing;
