#!perl -Tw

use strict;
use Test::More qw(no_plan);

BEGIN { use_ok('Class::TransparentFactory'); }

{
    package Facade1;
    use Class::TransparentFactory qw(foo);

    sub impl { return "Provider1"; }

    package Provider1;
    sub foo { return "@_" }

    package main;

    is(Facade1->foo(42, 54), "Provider1 42 54", "simplest facade");
}

{
    package Facade2;
    use Class::TransparentFactory qw(foo bar);

    sub impl {
        my $wanted = (caller(1))[3] =~ /::foo$/ ? 'Moose' : 'Caribou';
        return "Provider2::${wanted}Provider";
    }

    package Provider2::MooseProvider;
    sub foo { return "@_" }
    sub bar { return "@_" }
    package Provider2::CaribouProvider;
    sub foo { return "@_" }
    sub bar { return "@_" }

    package main;
    is(Facade2->foo(42, 54), "Provider2::MooseProvider 42 54",   "caller-based factory");
    is(Facade2->bar(42, 54), "Provider2::CaribouProvider 42 54", "caller-based factory");
}

{
    package Facade3;
    use Class::TransparentFactory qw(foo bar);

    sub impl {
        return $_[1] eq 'moose' ? "Provider3::One" : "Provider3::Two";
    }

    package Provider3::One;
    sub foo { return "Provider3::One::foo" }
    sub bar { return "Provider3::One::bar" }
    package Provider3::Two;
    sub foo { return "Provider3::Two::foo" }
    sub bar { return "Provider3::Two::bar" }

    package main;
    is(Facade3->foo("moose", 54), "Provider3::One::foo", "arg-based factory");
    is(Facade3->bar(42,      54), "Provider3::Two::bar", "arg-based factory");
}




