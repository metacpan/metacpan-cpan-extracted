#!perl

use strict;
use warnings;
use Test::More;

use Assert::Refute qw(:core);
use Assert::Refute::T::Array;

my $c;
$c = contract {
    array_of [], qr/foo/, "pass";
}->apply;

is $c->get_sign, "t1d", "Empty = pass";
note $c->get_tap;

$c = contract {
    array_of [qw[food fool foot]], qr/foo/, "pass";
}->apply;

is $c->get_sign, "t1d", "Still happy case";
note $c->get_tap;

$c = contract {
    array_of [qw[food bard bazooka]], qr/foo/, "Not passing";
}->apply;

is $c->get_sign, "tNd", "Nope";
# FIXME!!! What's wrong with these?
# like $c->get_tap, qr/#\s+ok 1/, "Expl. inc passing 1";
# like $c->get_tap, qr/#\s+not ok 2/, "Expl. inc failing 2";
# like $c->get_tap, qr/#\s+not ok 3/, "Expl. inc failing 3";
note $c->get_tap;

note "NOW THE HARD PART - SUBCONTRACT";

my $spec = contract {
    my ($self, $item) = @_;
    $self->like( $item->{name}, qr/^\w+$/, "name format");
    $self->cmp_ok( $item->{id}, ">", 0, "positive id");
} need_object => 1;

$c = contract {
    array_of [ { id => 1 }, { id => 2, name => "xxx" } ], $spec, "Complex criteria fail";
}->apply;

is $c->get_sign, "tNd", "Complex criteria - fail mode";

note "CONTRACT RESULT\n", $c->get_tap, "/CONTRACT RESULT";

note "PLAIN SUB SUBCONTRACT";

$c = contract {
    array_of [ { id => 1 }, { name => "foo" } ], sub {
        $_[0]->cmp_ok( $_[1]->{id}, '>', 0, "Positive" );
        Assert::Refute::like $_[1]->{name}, qr/^\w+$/, "Id - identifier";
    }, "Complex criteria fail - sub";
}->apply;

is $c->get_sign, "tNd", "Complex criteria - fail mode";

note "PLAIN SUB RESULT\n", $c->get_tap, "/PLAIN SUB RESULT";

done_testing;
