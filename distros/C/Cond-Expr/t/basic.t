use strict;
use warnings;
use Test::More 0.88;

use Cond::Expr;

sub cond_list {
    my ($answer) = @_;

    return (
        foo => 'bar',
        (cond ($answer) { has_answer => 1 }),
        (cond
            ($answer == 42) { answer => $answer }
            ($answer)       { wrong_answer => 1 }
            otherwise       { no_answer    => 1 }
        ),
    );
}

sub cond_scalar {
    my ($answer) = @_;

    return cond
        ($answer == 42) { $answer        }
        ($answer)       { 'wrong_answer' }
        otherwise       { 'no_answer'    };
}

is_deeply
    { cond_list(0) },
    { foo => 'bar', no_answer => 1 };

is_deeply
    { cond_list(1) },
    { foo => 'bar', has_answer => 1, wrong_answer => 1 };

is_deeply
    { cond_list(42) },
    { foo => 'bar', has_answer => 1, answer => 42 };

is cond_list(0), 1;
is cond_list(1), 1;
is cond_list(42), 42;

is cond_scalar(0), 'no_answer';
is cond_scalar(1), 'wrong_answer';
is cond_scalar(42), 42;

is_deeply [cond_scalar(0)], ['no_answer'];
is_deeply [cond_scalar(1)], ['wrong_answer'];
is_deeply [cond_scalar(42)], [42];

is cond, undef;
is_deeply [cond], [];

done_testing;
