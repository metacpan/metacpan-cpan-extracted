use Test::Most 'die', tests => 2;

use ful;

use_ok('Proof01');

eval {
    require Proof02;
};

ok $@;

done_testing;