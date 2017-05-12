use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent;
use Test::More;

sub cv($) {
    my $v = shift;

    my $cv = AE::cv;
    my $t; $t = AE::timer 0, 0, sub { $cv->($v); undef $t; };
    return $cv;
}

is +(cv 3)->filter(sub { $_[0] > 2})->recv, 3;
eval { +(cv 1)->filter(sub { $_[0] > 2})->recv };
ok $@;

done_testing;
