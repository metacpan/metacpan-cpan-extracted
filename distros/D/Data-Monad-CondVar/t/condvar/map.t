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

# preserve identity
my $id = sub { @_ };
is_deeply [$cv213->map($id)->recv], [2, 1, 3];

# preserve associative
my $f = sub { reverse @_ };
my $g = sub { sort @_ };
is_deeply [$cv213->map(sub { $g->($f->(@_)) })->recv], [1, 2, 3];
is_deeply [$cv213->map($f)->map($g)->recv], [1, 2, 3];

done_testing;
