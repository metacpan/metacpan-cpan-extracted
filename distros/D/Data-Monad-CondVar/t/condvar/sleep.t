use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent;
use Test::More;

is +cv_unit('X')->sleep(.06)->recv, 'X';

done_testing;
