use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent;
use Test::More;

sub cv($) {
    my @v = @_;
    my $cv = AE::cv;
    my $t; $t = AE::timer .002, 0, sub {
        $cv->(@v);
        undef $t;
    };
    return $cv;
}

is cv(sub { $_[0] * 2 })->ap(cv 3)->recv, 6;
is_deeply
    [cv(sub { $_[0] + $_[1], $_[0] * $_[1] })->ap(cv 3, cv 5)->recv], 
    [8, 15];

done_testing;
