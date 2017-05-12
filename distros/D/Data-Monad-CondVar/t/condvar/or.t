use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent;
use Test::More;

sub filtered_cv($) {
    my $v = shift;

    my $cv = AE::cv;
    my $t; $t = AE::timer 0, 0, sub { $cv->($v); undef $t; };
    return $cv->filter(sub { $_[0] > 2});
}

is +(filtered_cv 3)->or(filtered_cv 1)->recv, 3;
is +(filtered_cv 1)->or(filtered_cv 3)->recv, 3;
is +(filtered_cv 10)->or(filtered_cv 5)->recv, 10;
eval { (filtered_cv 1)->or(filtered_cv 1)->recv };
ok $@;

done_testing;
