#!perl

use strict;
use warnings;

use Test::More tests => 31;
use Test::Exception;

use Class::Agreement;

my $file = __FILE__;

# postcondition NAME, BLOCK
#
# Specify that the method NAME must meet the postcondition as specified in
# BLOCK.

{

    package Camel;
    use Class::Agreement;

    sub simple { $_[1] }

    postcondition simple => sub { result > 0 };
}

lives_ok { Camel->simple(5) } "method simple success";
dies_ok  { Camel->simple(-1) } "method simple failure";

eval { Camel->simple(-1) };
like $@, qr/line \s+ 25/x, "simple failure line number";
like $@, qr/$file/x,       "simple failure filename";

# In BLOCK, the variable @_ will be the argument list of the method.

{

    package Camel;

    sub argcheck { }

    postcondition argcheck => sub {
        Test::More::is_deeply( \@_, [ 'Camel', 1, 2, 3 ],
            "method arguments" );
    };
}

Camel->argcheck( 1, 2, 3 );

# The function "result" may be used to retrieve the return values of the
# method.  If the method returns a list, calling "result" in array context will
# return all of return values, and calling "result" in scalar context will
# return only the first item of that list.

{

    package Camel;

    sub returnlist { ( 6, 5, 4 ) }

    postcondition returnlist => sub {
        Test::More::is_deeply( [result], [ 6, 5, 4 ], "return list, array" );
        Test::More::is( result, 6, "return list, scalar" );
    };
}

Camel->returnlist;

# If the method returns a scalar, "result" called in scalar context will be
# that scalar, and "result" in array context will return a list with one
# element.

{

    package Camel;

    sub returnscalar {7}

    postcondition returnscalar => sub {
        Test::More::is_deeply( [result], [7], "return scalar, array" );
        Test::More::is( result, 7, "return scalar, scalar" );
    };
}

Camel->returnscalar;

# With methods, postconditions for the parent class will be checked if they
# exist.

{
    my $has_invoked_parent_post = 0;
    my $has_invoked_child_post  = 0;

    {

        package ClassA;
        use Class::Agreement;

        sub new { bless {}, shift }

        sub pass { }
        postcondition pass => sub { ++$has_invoked_parent_post; 1 };

        sub fail { }
        postcondition fail => sub { ++$has_invoked_parent_post; 0 };

        package ClassB;
        use base 'ClassA';
        use Class::Agreement;

        sub pass { }
        postcondition pass => sub { ++$has_invoked_child_post; 1 };

        sub fail { }
        postcondition fail => sub { ++$has_invoked_child_post; 0 };
    }

    eval { ClassB->pass };
    is $has_invoked_child_post,  1, "child postcondition invoked on success";
    is $has_invoked_parent_post, 1, "parent postcondition invoked on success";

    eval { ClassB->fail };
    is $has_invoked_child_post,  2, "child postcondition invoked on failure";
    is $has_invoked_parent_post, 2, "parent postcondition invoked on failure";
}

# If the postcondition for the child's method fails, the blame lies with the
# child method's implementation since it is not adhering to its contract.

{
    my ( $parent_line, $child_line );

    {

        package ClassA;

        sub m { $_[1] }
        $parent_line = __LINE__ + 1;
        postcondition m => sub { result > 0 };

        package ClassB;

        sub m { $_[1] }
        $child_line = __LINE__ + 1;
        postcondition m => sub { not result % 2 };
    }

    eval { ClassB->m(4) };
    is $@, '', "no failure, multiple classes";

    eval { ClassB->m(3) };
    like $@, qr/ ClassB::m .* implementation /isx,
        "blame implementation, child fails";
    like $@, qr/line \s+ $child_line/x, "failure line number";
    like $@, qr/$file/x, "failure filename";

    eval { ClassB->m(-3) };
    like $@, qr/ ClassB::m .* implementation /isx,
        "blame implementation, both fail";
    like $@, qr/line \s+ $child_line/x, "failure line number";
    like $@, qr/$file/x, "failure filename";

# If the postcondition for the child method passes, but the postcondition for
# the parent's fails, the problem lies with the hierarchy betweeen the classes.

    eval { ClassB->m(-4) };
    like $@, qr/ hierarchy .* between .* ClassA .* ClassB /isx,
        "hierarchy error";
    like $@, qr/line \s+ $parent_line/x, "failure line number";
    like $@, qr/line \s+ $child_line/x,  "failure line number";
    like $@, qr/$file/x,                 "failure filename";
}

# Note again that only the relationships between child and parent classes are
# checked -- this module won't traverse the complete ancestry of a class.

{
    my $third_line;

    {

        package ClassC;
        use base 'ClassB';
        use Class::Agreement;

        sub m { $_[1] }
        postcondition m => sub { not result % 3 };
        $third_line = __LINE__ - 1;
    }

    eval { ClassC->m(9) };
    like $@, qr/ hierarchy .* between .* ClassB .* ClassC /isx,
        "hierarchy only between parent and child";
    like $@, qr/line \s+ $third_line/x, "failure line number";
    like $@, qr/$file/x, "failure filename";
}

# You can use this keyword multiple times to declare multiple postconditions on
# the given method.

{

    package Camel;

    sub multiple { $_[1] }

    postcondition multiple => sub { result > 0 };
    postcondition multiple => sub { not result % 2 };
}

lives_ok { Camel->multiple(4) } "method multiple success";
dies_ok  { Camel->multiple(-4) } "method multiple failure first";
dies_ok  { Camel->multiple(3) } "method multiple failure second";
dies_ok  { Camel->multiple(-3) } "method multiple failure both";

