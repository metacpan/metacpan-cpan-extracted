#!perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use Class::Agreement;

{
    my $f = sub { ok not defined wantarray };
    precondition $f => sub {1};
    $f->();
}

{
    my $f = sub { ok defined wantarray and not wantarray };
    precondition $f => sub {1};
    scalar $f->();
}

{
    my $f = sub { ok wantarray };
    precondition $f => sub {1};
    no warnings 'syntax';
    my $x = [ $f->() ];
}

{

    package Camel;
    use Class::Agreement;

    precondition void => sub {1};

    sub void {
        Test::More::ok( not defined wantarray );
    }

    precondition scalar => sub {1};

    sub scalar {
        Test::More::ok( defined wantarray and not wantarray );
    }

    precondition array => sub {1};

    sub array {
        Test::More::ok(wantarray);
    }
}

SKIP:
{
    skip "void method context listed under CAVEATS" => 1;
    Camel->void;
}

my $x = Camel->scalar;
my @x = Camel->array;

