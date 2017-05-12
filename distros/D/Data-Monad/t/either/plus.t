use strict;
use warnings;
use Test::More;

use Data::Monad::Either qw(right left);

subtest 'fold' => sub {
    is left('failure')->fold(
        sub { $_[0] . '!' },
        sub { $_[0] * 2 },
    ), 'failure!';
    is right(10)->fold(
        sub { $_[0] . '!' },
        sub { $_[0] * 2 },
    ), 20;
};

subtest 'or_else' => sub {
    is_deeply left('failure')->or_else(right('else')), right('else');
    is_deeply right(10)->or_else(right('else')), right(10);
};

subtest 'get_or_else' => sub {
    is left('failure')->get_or_else('else'), 'else';
    is right(10)->get_or_else('else'), 10;
    is_deeply [ right(10, 20, 30)->get_or_else('else') ], [ 10, 20, 30 ];
};

subtest 'or_else_multi' => sub {
    is_deeply left('failure')->or_else(right('else1', 'else2')), right('else1', 'else2');
    is_deeply right(10)->or_else(right('else1', 'else2')), right(10);
};

subtest 'get_or_else_multi' => sub {
    is_deeply [left('failure')->get_or_else('else1', 'else2')], [qw(else1 else2)];
    is right(10)->get_or_else('else1', 'else2'), 10;
    is_deeply [ right(10, 20, 30)->get_or_else('else1', 'else2') ], [ 10, 20, 30 ];
};

subtest 'value_or' => sub {
    is left('failure')->value_or(sub {
        $_[0] . '!';
    }), 'failure!';
    is right(10)->value_or(sub {
        $_[0] . '!';
    }), 10;
    is_deeply [ right(10, 20, 30)->value_or(sub { $_[0] . '!' }) ], [ 10, 20, 30 ];
};

subtest 'swap' => sub {
    is_deeply left('failure')->swap, right('failure');
    is_deeply right(10)->swap, left(10);
};

subtest 'left_map' => sub {
    is_deeply left('failure')->left_map(sub { { error => $_[0] } }), left({ error => 'failure' });
    is_deeply right(10)->left_map(sub { { error => $_[0] } }), right(10);
};

done_testing;
