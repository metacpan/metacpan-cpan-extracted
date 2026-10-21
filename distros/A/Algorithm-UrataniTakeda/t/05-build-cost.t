#!perl

use v5.26;

use Test2::V0 -no_srand => 1;
use Test2::Tools::Exception qw( lives );

use Algorithm::UrataniTakeda;

# Building the shift2 table once took a full pass over the trie per pattern,
# so construction cost grew with (patterns x states).  Six thousand random
# eight-character patterns took tens of seconds; a single pass takes well
# under a second.  The alarm is generous so a slow host still passes with the
# fix, while the per-pattern pass needs a several-fold faster machine than
# the one this was measured on to slip under it.

srand(20261020);
my %seen;
my @patterns;
while ( @patterns < 6000 ) {
    my $p = join '', map { chr( 97 + int rand 26 ) } 1 .. 8;
    push @patterns, $p unless $seen{$p}++;
}

my $m;
ok( lives {
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm 10;
    $m = Algorithm::UrataniTakeda->new( patterns => \@patterns );
    alarm 0;
}, "constructing a large pattern set does not take a pass per pattern" ) or note $@;
alarm 0;

ok $m, "matcher was built";
is [ $m->matches( "zz$patterns[17]zz" ) ], [ $patterns[17] ], "and it still matches" if $m;

done_testing;
