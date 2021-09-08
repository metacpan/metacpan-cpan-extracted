use strict;
use warnings;
use utf8;

use Acme::CoC::Util;

use Test2::V0;

subtest 'eq_any' => sub {
    ok eq_any('test', [1, 2, 'test']);
    ok !eq_any('test', [1, 2]);
};

subtest 'is_ccb' => sub {
    ok is_ccb('skill');
    ok is_ccb('cc');
    ok is_ccb('ccb');
    ok !is_ccb('test');
};

subtest 'get_target' => sub {
    ok !get_target('skill');
    ok !get_target('1d100');
    is get_target('cc 100'), 100;
    is get_target('ccb 55'), 55;
};

subtest 'is_extream' => sub {
    ok is_extream(1, 60);
    ok is_extream(12, 60);
    ok !is_extream(12, 59);
};

subtest 'is_hard' => sub {
    ok is_hard(24, 50);
    ok is_hard(12, 24);
    ok !is_hard(12, 23);
};

subtest 'is_failed' => sub {
    ok is_failed(100, 50);
    ok is_failed(51, 50);
    ok !is_failed(50, 50);
};

done_testing;
