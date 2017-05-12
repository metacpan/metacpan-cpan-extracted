use Test::More 'no_plan';
use Contextual::Return;

sub scalar_only {
    return (
        SCALAR { "scalar" }
    );
}

is join(q{ }, qw(It got a), scalar_only()), "It got a scalar" => 'Fell back to scalar';

sub str_num {
    return (
        STR { "scalar" }
        NUM { 1        }
    );
}

is join(q{ }, qw(It got a), str_num()), "It got a scalar" => 'Fell back to str';
is join(q{ }, qw(It got a), 0+str_num()), "It got a 1" => 'Fell back to num';

sub num_only {
    return (
        NUM { 1        }
    );
}

is join(q{ }, qw(It got a), num_only()), "It got a 1" => 'Fell back to num';

sub listy {
    return (
       LIST { qw(list of strings) }
        STR { "scalar" }
        NUM { 1        }
    );
}

is join(q{ }, qw(It got a), listy()), "It got a list of strings"
                                                       => 'List not preempted';
