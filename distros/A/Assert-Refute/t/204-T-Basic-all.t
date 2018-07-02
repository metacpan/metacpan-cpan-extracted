#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Assert::Refute qw(contract);

{
    # Be extra careful not to pollute the main namespace
    package T;
    use Assert::Refute qw(:all);
};

my $c;

$c = contract {
    package T;
    is 42, 42;
    is 42, 137;
    is undef, '';
    is '', undef;
    is undef, undef;
    is "foo", "foo";
    is "foo", "bar";
    is {}, [];
    is {}, {}, "different struct";
    my @x = 1..5;
    my @y = 11..15;
    is @x, @y, "scalar context";
}->apply;
is $c->get_sign, "t1NNN2NNN1d", "is()";
note $c->get_tap;

$c = contract {
    package T;
    isnt 42, 137;
    isnt 42, 42;
    isnt undef, undef;
    isnt undef, 42;
    isnt 42, undef;
    isnt '', undef;
    isnt undef, '';
}->apply;
is $c->get_sign, "t1NN4d", "isnt()";
note $c->get_tap;

$c = contract {
    package T;
    like "foo", qr/oo*/;
    like "foo", "oo*";
    like "foo", qr/bar/;
    like "foo", "f.*o";
    like undef, qr/.*/;
}->apply;
is $c->get_sign, "t1NN1Nd", "like()";
note $c->get_tap;

$c = contract {
    package T;
    unlike "foo", qr/bar/;
    unlike "foo", qr/foo/;
    unlike "foo", "oo*";
    unlike "foo", "f.*o";
    unlike undef, qr/.*/;
}->apply;
is $c->get_sign, "t1N1NNd", "unlike()";
note $c->get_tap;

$c = contract {
    package T;
    ok ok 1;
    ok ok 0;
    ok undef;
}->apply;
is $c->get_sign, "t2NNNd", "ok()";
note $c->get_tap;

$c = contract {
    package T;
    refute 0, "dummy";
    refute { foo => 42 }, "dummy";
}->apply;
is $c->get_sign, "t1Nd", "refute()";
note $c->get_tap;

$c = contract {
    package TT;
    our @ISA = 'T';
    package T;
    isa_ok current_contract, "Assert::Refute::Report";
    isa_ok current_contract, "Foo::Bar";
    isa_ok "TT", "T";
    isa_ok "TT", "Foo::Bar";
}->apply;
is $c->get_sign, "t1N1Nd", "isa_ok()";
note $c->get_tap;

$c = contract {
    package T;
    can_ok current_contract, "can_ok";
    can_ok current_contract, "frobnicate";
    can_ok "Assert::Refute", "import", "can_ok";
    can_ok "Assert::Refute", "unknown_subroutine";
    can_ok "No::Exist", "can", "isa", "import";
}->apply;
is $c->get_sign, "t1N1NNd", "can_ok()";
note $c->get_tap;

$c = contract {
    # TODO write a better new_ok
    package T;
    new_ok "Assert::Refute::Contract", [ code => sub {} ];
    new_ok "No::Such::Package", [];
}->apply;
is $c->get_sign, "t1Nd", "new_ok()";
note $c->get_tap;

$c = contract {
    package T;
    require_ok "Assert::Refute"; # already loaded
    require_ok "No::Such::Package::_______::000";
}->apply;
is $c->get_sign, "t1Nd", "require_ok()";
note $c->get_tap;

done_testing;
