use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent;
use Test::More;

eval { call_cc { cv_fail "FAIL" }->recv };
like $@, qr/FAIL/;

done_testing;
