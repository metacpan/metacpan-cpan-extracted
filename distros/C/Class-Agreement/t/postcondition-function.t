#!perl

use strict;
use warnings;

use Test::More tests => 20;
use Test::Exception;

use Class::Agreement;

# postcondition VARIABLE, BLOCK
#
# Specify that, when called, the subroutine reference pointed to by the lvalue
# VARIABLE must meet the postcondition as specified in BLOCK.
# ...
# Say that you have a function "g()" that accepts another function, "f()", as
# its argument. "f()", however, must return a number that is divisible by two.

sub g1 {
    my ( $f, $value ) = @_;
    postcondition $f => sub { result > 0 };
    $f->($value);
}

lives_ok {
    g1( sub {shift}, 8 );
    }
    "function simple success";
dies_ok {
    g1( sub {shift}, -5 );
    }
    "function simple failure";

# In BLOCK, the variable @_ will be the argument list of the subroutine.

sub g2 {
    my ($f) = @_;
    postcondition $f => sub { @_ = ( 4, 5, 6 ) };
    $f->( 1, 2, 3 );
}

g2( sub { is_deeply \@_, [ 1, 2, 3 ], "no function argument modification" } );

# If the method returns a list, calling "result" in array context will return
# all of return values, and calling "result" in scalar context will return only
# the first item of that list.

{
    my $r1 = sub { ( 2, 3, 4 ) };

    postcondition $r1 => sub {
        is_deeply( [result], [ 2, 3, 4 ], "return array, array" );
        is( result, 2, "return array, scalar" );
    };

    $r1->();
}

# If the method returns a scalar, "result" called in scalar context will be
# that scalar, and "result" in array context will return a list with one
# element.

{
    my $r2 = sub {9};

    postcondition $r2 => sub {
        is_deeply( [result], [9], "return scalar, array" );
        is( result, 9, "return scalar, scalar" );
    };

    $r2->();
}

# If called in void context this function will modify VARIABLE to point to a new
# subroutine reference with the precondition.

{
    my $f = sub {shift};

    postcondition $f => sub { result > 0 };

    lives_ok { $f->(1) } "function void context success";
    dies_ok  { $f->(-1) } "function void context failure";
}

# If called in scalar context, this function will return a new function with
# the attached postcondition.

{
    my $f = sub {shift};

    my $g = postcondition $f => sub { result > 0 };

    lives_ok { $f->(1) } "function scalar context original success";
    lives_ok { $f->(-1) } "function scalar context original still success";

    lives_ok { $g->(1) } "function scalar context wrapped success";
    dies_ok  { $g->(-1) } "function scalar context wrapped failure";
}

# You can use this keyword multiple times to declare multiple postconditions on
# the given function.

{
    my $multiple = sub {shift};

    postcondition $multiple => sub { result > 0 };
    postcondition $multiple => sub { not result % 2 };

    lives_ok { $multiple->(4) } "method multiple success";
    dies_ok  { $multiple->(-4) } "method multiple failure first";
    dies_ok  { $multiple->(3) } "method multiple failure second";
    dies_ok  { $multiple->(-3) } "method multiple failure both";
}

# line numbers

{
    my $f = sub {shift};

    postcondition $f => sub {0};
    my $line = __LINE__ - 1;
    my $file = __FILE__;

    eval { $f->() };

    like $@, qr/line \s+ $line/x, "line number of failure is correct";
    like $@, qr/$file/x,          "filename of failure is correct";
}

# do multiple contracts pass return values through?

{
    my $f = sub {41};

    postcondition $f => sub {1};
    postcondition $f => sub {1};
    postcondition $f => sub {1};

    is $f->(), 41, "multiple return value passthrough";
}

