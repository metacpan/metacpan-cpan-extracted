#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;

throws_ok {
    package Class1;
    use Class::Method::Modifiers::Fast;

    before foo => sub {};

} qr/The method 'foo' is not found in the inheritance hierarchy for class Class1/;

throws_ok {
    package Class2;
    use Class::Method::Modifiers::Fast;

    after foo => sub {};
} qr/The method 'foo' is not found in the inheritance hierarchy for class Class2/;

throws_ok {
    package Class3;
    use Class::Method::Modifiers::Fast;

    around foo => sub {};
} qr/The method 'foo' is not found in the inheritance hierarchy for class Class3/;

throws_ok {
    package Class4;
    use Class::Method::Modifiers::Fast;

    sub foo {}

    around 'foo', 'bar' => sub {};
} qr/The method 'bar' is not found in the inheritance hierarchy for class Class4/;

