use strict;
use warnings;
our $VERSION = 0.001_000;

use Test2::V0;
use Test::Alien;
use Alien::Pluto;
use English qw(-no_match_vars);  # for $OSNAME
use Data::Dumper;  # DEBUG

plan(8);

# load alien
alien_ok('Alien::Pluto', 'Alien::Pluto loads successfully and conforms to Alien::Base specifications');

# test version flag
my $run_object = run_ok([ 'pluto', '--version' ], 'Command `pluto --version` runs');
#print {*STDERR} "\n", q{<<< DEBUG >>> in t/04_binary_version_test2.t, have $run_object->out() = }, Dumper($run_object->out()), "\n";
#print {*STDERR} "\n", q{<<< DEBUG >>> in t/04_binary_version_test2.t, have $run_object->err() = }, Dumper($run_object->err()), "\n";
#$run_object->success('Command `pluto --version` runs successfully');  # DEV NOTE: does not work, pluto has weird exit values
$run_object->exit_is(3, 'Command `pluto --version` runs successfully');

# EXAMPLE: PLUTO 0.11.4 - An automatic parallelizer and locality optimizer
is((substr $run_object->out(), 0, 6), 'PLUTO ', 'Command `pluto --version` output starts correctly');
# DEV NOTE: can't use out_like() on the next line because it does not properly capture to $1, as used in the following split
ok($run_object->out() =~ m/^PLUTO\ ([0-9\.]+)\ -\ An\ automatic\ parallelizer\ and\ locality\ optimizer$/xms, 'Command `pluto --version` runs with valid output');

# test actual version numbers
my $version_split = [split /[.]/, $1];
#print {*STDERR} "\n", q{<<< DEBUG >>> in t/04_binary_version_test2.t, have $version_split = }, Dumper($version_split), "\n";
my $version_split_0 = $version_split->[0] + 0;
#print {*STDERR} "\n", q{<<< DEBUG >>> in t/04_binary_version_test2.t, have $version_split_0 = '}, $version_split_0, q{'}, "\n";
cmp_ok($version_split_0, '>=', 0, 'Command `pluto --version` returns major version 0 or newer');
if ($version_split_0 == 0) {
    my $version_split_1 = $version_split->[1] + 0;
    cmp_ok($version_split_1, '>=', 11, 'Command `pluto --version` returns sub-major version 11 or newer');
    if ($version_split_1 == 11) {
        my $version_split_2 = $version_split->[2] + 0;
        cmp_ok($version_split_2, '>=', 4, 'Command `pluto --version` returns minor version 4 or newer');
    }
}

done_testing;
