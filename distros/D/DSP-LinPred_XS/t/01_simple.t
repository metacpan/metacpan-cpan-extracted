use strict;
use Test::More;

use DSP::LinPred_XS;

my $input_len = 1000;
my $x = [(-2,-1,0,1,2) x $input_len];

my ($sum,$mean,$variance,$stddev) = DSP::LinPred_XS::get_stat($x);
is($sum,0);
is($mean,0);
is($variance,2);
my $lp = DSP::LinPred_XS->new;
$lp->set_filter({mu => 0.001, filter_length => 100, est_mode => 1});

$lp->update($x);

my $estimated = $lp->predict(5);

is(int($estimated->[0] - 0.5),-2);
is(int($estimated->[1] - 0.5),-1);
is(int($estimated->[2] + 0.5),0);
is(int($estimated->[3] + 0.5),1);
is(int($estimated->[4] + 0.5),2);

done_testing;

