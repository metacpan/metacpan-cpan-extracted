#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;

do {
    package Fib;
    sub onacci { (1, 1, 2) }
};

is_deeply([Fib->onacci], [1, 1, 2]);

do {
    package Fib;
    use Class::Method::Modifiers::Fast;

    before onacci => sub {};
};

is_deeply([Fib->onacci], [1, 1, 2]);

do {
    package Fib;
    use Class::Method::Modifiers::Fast;

    after onacci => sub {};
};

is_deeply([Fib->onacci], [1, 1, 2]);
