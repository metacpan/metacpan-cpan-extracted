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
my $cvcv213 = do {
    my $cv = AE::cv;
    my $t; $t = AE::timer 0, 0, sub {
        $cv->send($cv213);
        undef $t;
    };
    $cv;
};
my $cvcvcv213 = do {
    my $cv = AE::cv;
    my $t; $t = AE::timer 0, 0, sub {
        $cv->send($cvcv213);
        undef $t;
    };
    $cv;
};

# naturality
my $f = sub { map {$_ * 2} @_ };
is_deeply [$cvcv213->flatten->map($f)->recv], [4, 2, 6];
is_deeply [$cvcv213->map(sub { $_[0]->map($f) })->flatten->recv], [4, 2, 6];

# associative law
is_deeply [$cvcvcv213->flatten->flatten->recv], [2, 1, 3];
is_deeply [$cvcvcv213->map(sub { $_[0]->flatten })->flatten->recv], [2, 1, 3];


done_testing;
