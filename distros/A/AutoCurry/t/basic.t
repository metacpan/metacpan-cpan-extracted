#! perl

use Test::More tests => 9;

use warnings;
use strict;

{   
    package T1;
    use AutoCurry 't';
    sub t { "@_" };
}

is( T1::t_c(1)->(2), "1 2", "use AutoCurry by name" );


{   
    package T2;
    use AutoCurry ':all';
    sub s { "@_" };
    sub t { "@_" };
}

is( T2::s_c(1)->(2), "1 2", "use AutoCurry all (1/2)" );
is( T2::t_c(3)->(4), "3 4", "use AutoCurry all (2/2)" );

{   
    package T3;
    sub s { "@_" };
    sub t { "@_" };
}

ok( ! T3->can("s_c") &&
    AutoCurry::curry_named_functions("T3::s") &&
    T3->can("s_c") &&
    T3::s_c(1)->(2) eq "1 2",
    "curry_named_functions w/ fully-qualified sub" );

ok( ! T3->can("t_c") &&
    do { package T3; AutoCurry::curry_named_functions("t") } &&
    T3->can("t_c") &&
    T3::t_c(1)->(2) eq "1 2",
    "curry_named_functions w/ local sub" );

my @created;
{   
    package T4;
    sub t { "@_" };
    @created = AutoCurry::curry_package();
}

is_deeply( \@created, ["T4::t_c"],
           "curry_package on caller creates expected fns" );
is( T4::t_c(1)->(2), "1 2", "curry_package on caller makes good fns" );


{   
    package T5;
    sub t { "@_" };
}

is_deeply( [AutoCurry::curry_package("T5")], ["T5::t_c"],
           "curry_package on given package creates expected fns" );
is( T5::t_c(1)->(2), "1 2", "curry_package on given package makes good fns" );
