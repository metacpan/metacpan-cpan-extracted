use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent;
use Test::More;

my $cv213 = do {
    my $cv = AE::cv;
    my $t; $t = AE::timer 0, 0, sub {
        $cv->send(2, 1, 3);
        undef $t;
    };
    $cv;
};

is_deeply [$cv213->flat_map(sub {
    my @values = @_;
    cv_unit(map {$_ * 2} @values);
})->flat_map(sub {
    my @values = @_;
    cv_unit(map {$_ - 1} @values);
})->recv], [3, 1, 5];

done_testing;
