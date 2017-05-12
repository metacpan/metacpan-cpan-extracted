use strict;
use warnings;
use AnyEvent;
use Data::Monad::CondVar;
use Test::More;

eval { cv_fail("FAIL")->recv };
like $@, qr/^FAIL/;

eval { cv_fail->recv };
ok $@;

done_testing;
