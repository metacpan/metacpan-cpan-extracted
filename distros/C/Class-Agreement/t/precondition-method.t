#!perl

use strict;
use warnings;

use Test::More tests => 24;
use Test::Exception;

use Class::Agreement;

my $file = __FILE__;

# precondition NAME, BLOCK
#
# Specify that the method NAME must meet the precondition as specified in
# BLOCK.

{
    my $line;
    {

        package Camel;
        use Class::Agreement;
        precondition simple => sub { $_[1] > 0 };
        $line = __LINE__ - 1;
        sub simple { }
    }

    lives_ok { Camel->simple(5) } "method simple success";
    dies_ok  { Camel->simple(-1) } "method simple failure";

    eval { Camel->simple(-1) };
    like $@, qr/line \s+ $line/x, "simple failure line number";
    like $@, qr/$file/x,          "simple failure filename";
}

# In BLOCK, the variable @_ will be the argument list of the method.

{

    package Camel;
    precondition argcheck => sub {
        Test::More::is_deeply(
            \@_,
            [ 'Camel', 1, 2, 3 ],
            "method simple arguments"
        );
    };

    sub argcheck { }
}

Camel->argcheck( 1, 2, 3 );

# Modifying @_ WILL NOT MODIFY the arguments passed to the method. (The first
# item of @_ will be the class name or object, as usual.)

{

    package Camel;
    precondition argmod => sub {
        @_ = ( 4, 5, 6 );
    };

    sub argmod {
        Test::More::is_deeply(
            \@_,
            [ 'Camel', 1, 2, 3 ],
            "no method argument modification"
        );
    }
}

Camel->argmod( 1, 2, 3 );

# With methods, if the the precondition fails (returns false),
# preconditions for the parent class will be checked.

{
    my $has_invoked_parent_pre = 0;
    my $has_invoked_child_pre  = 0;

    {

        package ClassA;
        use Class::Agreement;

        sub new { bless {}, shift }

        precondition pass => sub { ++$has_invoked_parent_pre; 1 };
        sub pass { }

        precondition fail => sub { ++$has_invoked_parent_pre; 0 };
        sub fail { }

        package ClassB;
        use base 'ClassA';
        use Class::Agreement;

        precondition pass => sub { ++$has_invoked_child_pre; 1 };
        sub pass { }

        precondition fail => sub { ++$has_invoked_child_pre; 0 };
        sub fail { }
    }

    eval { ClassB->pass };
    is $has_invoked_child_pre, 1, "child precondition invoked on success";
    is $has_invoked_parent_pre, 0,
        "parent precondition NOT invoked on success";

    eval { ClassB->fail };
    is $has_invoked_child_pre,  2, "child precondition invoked on failure";
    is $has_invoked_parent_pre, 1, "parent precondition invoked on failure";
}

# If the preconditions for both the child's method and the parent's method
# fail, the input to the method must have been invalid.

{
    my ( $parent_line, $child_line );

    {

        package ClassA;

        $parent_line = __LINE__ + 1;
        precondition m => sub { $_[1] > 0 };
        sub m { }

        package ClassB;

        $child_line = __LINE__ + 1;
        precondition m => sub { not $_[1] % 2 };
        sub m { }
    }

    {
        my $usage_line = __LINE__ + 1;
        eval { ClassB->m(-3) };
        like $@, qr/ ClassB::m .* client .* input /isx, "client input error";
        like $@, qr/line $usage_line/,                  "failure line number";
        like $@, qr/$file/x,                            "failure filename";
    }

    # If the precondition for the parent passes, there's a problem with the
    # hierarchy between the class and the parent class.

    eval { ClassB->m(3) };
    like $@, qr/ hierarchy .* between .* ClassA .* ClassB /isx,
        "hierarchy error";
    like $@, qr/line $parent_line \(the parent\)/,
        "failure line number parent";
    like $@, qr/line $child_line \(the child\)/, "failure line number child";
    like $@, qr/$file/x, "failure filename";

# Note that only the relationships between child and parent classes are checked
# -- this module won't traverse the complete ancestry of a class.
}

{
    my $third_line;
    {

        package ClassC;
        use base 'ClassB';
        use Class::Agreement;

        $third_line = __LINE__ + 1;
        precondition m => sub { not $_[1] % 3 };
        sub m { }
    }

    eval { ClassC->m(4) };
    like $@, qr/ hierarchy .* between .* ClassB .* ClassC /isx,
        "hierarchy only between parent and child";
    like $@, qr/line \s+ $third_line/x, "failure line number";
    like $@, qr/$file/x, "failure filename";
}

# You can use this keyword multiple times to declare multiple preconditions on
# the given method.

{

    package Camel;

    precondition multiple => sub { $_[1] > 0 };
    precondition multiple => sub { not $_[1] % 2 };

    sub multiple { }
}

lives_ok { Camel->multiple(4) } "method multiple success";
dies_ok  { Camel->multiple(-4) } "method multiple failure first";
dies_ok  { Camel->multiple(3) } "method multiple failure second";
dies_ok  { Camel->multiple(-3) } "method multiple failure both";

