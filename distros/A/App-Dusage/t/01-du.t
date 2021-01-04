#!perl

use Test::More tests => 2;

chdir('..') if -d '../t';

my @du = qw ( du -a -- blib );
my $ret = open( my $fh, "-|", @du );
ok( $ret, "get input from -| @du" );
my $ok = 1;
my $tally;
while ( <$fh> ) {
    $ok = 0 unless /^\d+\s+.+$/;
    $tally++;
}
ok( $ok && $tally, "$tally sensible results from @du" );
