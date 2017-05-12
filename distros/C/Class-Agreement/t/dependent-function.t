#!perl

use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;

use Class::Agreement;

# dependent VARIABLE, BLOCK
#
# Specify that the subroutine reference pointed to by the lvalue VARIABLE will
# use the subroutine reference returned by BLOCK as a postcondition.
# ...
# Say that you have a function "g()" that accepts another function, "f()" as
# its argument. You want to make sure that "f()", as a side effect, adds to the
# global variable $count:

my $count = 0;

sub g {
    my ($f) = @_;
    dependent $f => sub {
        my $old_count = $count;
        return sub { $count > $old_count };
    };
    $f->();
}

lives_ok {
    g( sub { $count += 4 } );
    }
    "proof of concept success";
dies_ok {
    g( sub { $count -= 4 } );
    }
    "proof of concept failure";

# If BLOCK returns undefined, no postcondition will be added.

{
    my $f = sub { };

    dependent $f => sub {undef};

    lives_ok { $f->(5) } "no reason this should fail, one";
    lives_ok { $f->(-1) } "no reason this should fail, two";
}

# Identical to the previous usage, BLOCK is run at the same time as
# preconditions, thus the @_ variable works in the same manner as in
# preconditions.

{

    my $f = sub { };

    dependent $f => sub {
        Test::More::is_deeply( \@_, [ 1, 2, 3 ], "method arguments outside" );
        return;
    };

    $f->( 1, 2, 3 );
}

# However, the subroutine reference that BLOCK returns will be invoked as
# a postcondition, thus it may use @_, $r and @r.

{
    my $f = sub { };

    dependent $f => sub {
        sub {
            is_deeply( \@_, [ 1, 2, 3 ], "method arguments inside" );
            }
    };

    $f->( 1, 2, 3 );

}

{

    my $f = sub { ( 6, 5, 4 ) };

    dependent $f => sub {
        sub {
            is_deeply( [result], [ 6, 5, 4 ], "return list, array" );
            is( result, 6, "return list, scalar" );
            }
    };

    $f->();

}

{

    my $f = sub {7};

    dependent $f => sub {
        sub {
            is_deeply( [result], [7], "return scalar, array" );
            is( result, 7, "return scalar, scalar" );
            }
    };

    $f->();
}

# You can use this keyword multiple times to declare multiple dependent
# contracts on the given function.

{
    my $f = sub { $_[0] };

    dependent $f => sub {
        sub { result > 0 }
    };
    dependent $f => sub {
        sub { not result % 2 }
    };

    lives_ok { $f->(4) } "method multiple success";
    dies_ok  { $f->(-4) } "method multiple failure first";
    dies_ok  { $f->(3) } "method multiple failure second";
    dies_ok  { $f->(-3) } "method multiple failure both";

}
