use strict;
use warnings;
use Test::More;
use Test::Fatal;

BEGIN { use_ok 'Algorithm::Kelly' }

is optimal_f(0, 1), -1, 'Zero chance has optimal f of minus one';
is optimal_f(0.5, 2), 0.25, 'Fifty-fifty chance with net odds of two is a quarter of bankroll';
is optimal_f(1, 2), 1, 'One hundred percent chance has an optimal f of one';

ok exception { optimal_f(0) };
ok exception { optimal_f(-0.1, 50) };
ok exception { optimal_f(1.1, 4) };
ok exception { optimal_f(0.5, -50) };
ok exception { optimal_f(0.5, undef) };
ok exception { optimal_f(undef, undef) };

done_testing;
