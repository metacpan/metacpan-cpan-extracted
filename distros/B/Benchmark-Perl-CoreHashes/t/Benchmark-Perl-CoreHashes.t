use strict;
use warnings;

use Time::HiRes qw( time );
use Test::More tests => 1;
use List::Util qw(shuffle);
BEGIN { use_ok('Benchmark::Perl::CoreHashes') };

#########################

my ($t1beg, $t1end);
my @subnames =  qw|
    PERL_HASH_FUNC_SIPHASH
    PERL_HASH_FUNC_SDBM
    PERL_HASH_FUNC_DJB2
    PERL_HASH_FUNC_SUPERFAST
    PERL_HASH_FUNC_MURMUR3
    PERL_HASH_FUNC_ONE_AT_A_TIME
    PERL_HASH_FUNC_ONE_AT_A_TIME_HARD
    PERL_HASH_FUNC_ONE_AT_A_TIME_OLD
|;
#disabled to make results easier to read for now
#@subnames = shuffle @subnames;
foreach (@subnames) {
    no strict 'refs';
    my $sub = \&{'run_'.$_};
    $t1beg = time;
    for(0..5) {
        $sub->();
    }
    $t1end = time;
    diag("time for $_ is ".($t1end-$t1beg)."\n");
}
