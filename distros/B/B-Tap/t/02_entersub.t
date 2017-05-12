use strict;
use warnings;
use utf8;
use Test::More;
use B::Tap ':all';
use B;
use B::Tools;

{
    sub foo { 63 }
    sub bar { 444 }
    sub baz { (5,9,6,3) }

    my $code = sub {
        my $x = foo() + 5900;
        my $y = bar() + 888;
        my @a = baz();
    };
    my $cv = B::svref_2object($code);

    my @entersub = op_grep { $_->name eq 'entersub' } $cv->ROOT;
    is 0+@entersub, 3;
    my @buf;
    for my $op (@entersub) {
        tap($op, $cv->ROOT, \@buf);
    }

    $code->();

    is_deeply(
        \@buf,
        [
            [G_SCALAR, 63],
            [G_SCALAR, 444],
            [G_ARRAY,  [5,9,6,3]],
        ]
    );

    if (1) {
        require B::Concise;
        my $walker = B::Concise::compile('', '', $code);
        B::Concise::walk_output(\my $buf);
        $walker->();
        ::diag($buf);
    }

}

done_testing;

