#!perl

use strict;
use warnings;
use Assert::Refute::Build;
use Assert::Refute::Report; # Avoid T::M detection
use Test::More tests => 2;

BEGIN {
    package Foo;
    use parent qw(Exporter);
    use Assert::Refute::Build;

    build_refute even => sub {
        return $_[0] % 2;
    }, export => 1, args => 1;

    build_refute odd => sub {
        my ($self, $n, $message) = @_;
        $self->refute( !($n % 2), $message || "is odd" );
    }, export => 1, args => 1, manual => 1;
};

BEGIN {
    package T;
    Foo->import;
};

eval {
    package Bar;
    use Assert::Refute::Build;
    build_refute odd => sub { !($_[0] % 2) };
};
note $@;
like $@, qr/odd.*already.*Foo/, "Name already taken = no go";

my $report = Assert::Refute::Report->new->do_run(sub {
    package T;
    even 2, "pass";
    odd  3, "pass";
    $_[0]->even( 3, "fail" );
    $_[0]->odd(  2, "fail" );
});

is $report->get_sign, "t2NNd", "Signature as expected";

note "REPORT\n".$report->get_tap."/REPORT";
