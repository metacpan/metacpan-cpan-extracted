use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent;
use Test::More;

sub async_add {
    my $cb = pop;
    my ($x, $y) = @_;
    $cb->($x + $y);
}

is as_cv { async_add 3, 2 => $_[0] }->recv, 5;

eval { cv_unit->flat_map(sub {})->recv };
like $@, qr/use condvar object/i, "Auto check of types.";

eval { cv_fail->catch(sub {})->recv };
like $@, qr/use condvar object/i, "Auto check of types.";

done_testing;
