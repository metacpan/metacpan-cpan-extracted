#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 7;

use_ok('DBIx::Class::Numeric');
use_ok('FakeClass');

FakeClass::_set_fake_cols(
	foo => 5,
	bar => 2,
);

# Test increase
FakeClass->increase_foo(5);
is(FakeClass->get_column('foo'), 10, "Column foo increased correctly");

# Test decrease
FakeClass->decrease_bar(3);
is(FakeClass->get_column('bar'), -1, "Column bar decreased correctly");

# Test increment
FakeClass->increment_bar;
is(FakeClass->get_column('bar'), 0, "Column bar increment correctly");

# Test decrement
FakeClass->decrement_foo;
is(FakeClass->get_column('foo'), 9, "Column foo decremented correctly");

# Test adjust
FakeClass->adjust_foo(-3);
is(FakeClass->get_column('foo'), 6, "Column foo adjusted correctly");
