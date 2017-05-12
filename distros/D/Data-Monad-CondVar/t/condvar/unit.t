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

# naturality
my $f = sub { map {$_ * 2} @_ };
is_deeply [cv_unit(2, 1, 3)->map($f)->recv], [4, 2, 6];
is_deeply [cv_unit($f->(2, 1, 3))->recv], [4, 2, 6];

# unit
is_deeply [cv_unit($cv213)->flatten->recv], [2, 1, 3];
is_deeply [$cv213->map(sub {
    cv_unit(@_);
})->flatten->recv], [2, 1, 3];

done_testing;
