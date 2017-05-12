#!perl

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

use Class::Agreement;

# precondition VARIABLE, BLOCK
#
# Specify that, when called, the subroutine reference pointed to by the
# lvalue VARIABLE must meet the precondition as specified in BLOCK.
# ...
# Say that you have a function "g()" that accepts another function, "f()", as
# its argument. However, the argument given to "f()" must be greater than zero:

sub g1 {
    my ( $f, $value ) = @_;
    precondition $f => sub { shift > 0 };
    $f->($value);
}

lives_ok {
    g1( sub { }, 1 );
    }
    "function simple success";
dies_ok {
    g1( sub { }, -1 );
    }
    "function simple failure";

# In BLOCK, the variable @_ will be the argument list of the subroutine.
# Modifying @_ will SHOULD NOT MODIFY the arguments passed to the subroutine.

sub g2 {
    my ($f) = @_;
    precondition $f => sub { @_ = ( 4, 5, 6 ) };
    $f->( 1, 2, 3 );
}

g2( sub { is_deeply \@_, [ 1, 2, 3 ], "no function argument modification" } );

# If called in void context this function will modify VARIABLE to point to a new
# subroutine reference with the precondition.

{
    my $f = sub { };

    precondition $f => sub { shift > 0 };

    lives_ok { $f->(1) } "function void context success";
    dies_ok  { $f->(-1) } "function void context failure";
}

# If called in scalar or list context, this function will return a new function
# with the attached precondition.

{
    my $f = sub { };

    my $g = precondition $f => sub { shift > 0 };

    lives_ok { $f->(1) } "function scalar context original success";
    lives_ok { $f->(-1) } "function scalar context original still success";

    lives_ok { $g->(1) } "function scalar context wrapped success";
    dies_ok  { $g->(-1) } "function scalar context wrapped failure";
}

# You can use this keyword multiple times to declare multiple preconditions on
# the given function.

{
    my $multiple = sub { };

    precondition $multiple => sub { $_[0] > 0 };
    precondition $multiple => sub { not $_[0] % 2 };

    lives_ok { $multiple->(4) } "method multiple success";
    dies_ok  { $multiple->(-4) } "method multiple failure first";
    dies_ok  { $multiple->(3) } "method multiple failure second";
    dies_ok  { $multiple->(-3) } "method multiple failure both";
}

# line numbers

{
    my $f = sub { };

    precondition $f => sub {0};
    my $line = __LINE__ - 1;
    my $file = __FILE__;

    eval { $f->() };

    like $@, qr/line \s+ $line/x, "line number of failure is correct";
    like $@, qr/$file/x,          "filename of failure is correct";
}

# do multiple contracts pass return values through?

{
    my $f = sub {41};

    precondition $f => sub {1};
    precondition $f => sub {1};
    precondition $f => sub {1};

    is $f->(), 41, "multiple return value passthrough";
}

