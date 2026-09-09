#!/usr/bin/env perl
# What `<:` buys, measured against Object::Proto.
#
# A typed Object::Proto slot checks its value on every set. When the value is
# known while the call is still being compiled, that check is settled once and
# the accessor emits the plain setter instead. `<:` is what makes a variable's
# value knowable at compile time, so only the declaration is marked - the calls
# below use the variables plainly.
#
#     perl -Mblib -I../Object-Proto/blib/lib -I../Object-Proto/blib/arch \
#          bench/confold.pl

use strict;
use warnings;
use Benchmark qw(cmpthese);

use Confold;

BEGIN {
    unless (eval { require Object::Proto; 1 }) {
        print "Object::Proto is not available; nothing to measure.\n";
        exit 0;
    }
}

# Class names and slot specs, from variables the compiler can read.
my $int_class = <: 'BInt';
my $str_class = <: 'BStr';
my $int_slot  = <: 'a:Int';
my $str_slot  = <: 'a:Str';

BEGIN {
    Object::Proto::define('BUntyped', 'a');
    Object::Proto::define($int_class, $int_slot);
    Object::Proto::define($str_class, $str_slot);
}

my $ui = BUntyped->new(a => 0);
my $oi = BInt->new(a => 0);
my $os = BStr->new(a => 'x');

# The `<:` ones are readable at compile time; the plain ones are not.
my $plain_int = 42;
my $plain_num = "12345";
my $plain_str = "hello";
my $const_int = <: 42;
my $const_num = <: "12345";
my $const_str = <: "hello";

# One accessor call is a few tens of nanoseconds, which is the same order as
# Benchmark's own per-iteration overhead. Batching the calls keeps the thing
# being measured in charge of the result.
my $INNER = 20_000;

print "=" x 68, "\n";
print "Confold: a compile-time value removes a runtime type check\n";
print "rates are batches of $INNER accessor calls per second\n";
print "=" x 68, "\n\n";

print "-- Int slot, integer value --\n";
cmpthese(-2, {
    'untyped floor'    => sub { BUntyped::a($ui, $plain_int) },
    'plain variable'   => sub { BInt::a($oi, $plain_int)  },
    '<: variable'      => sub { BInt::a($oi, $const_int)  },
});

print "\n-- Int slot, string value (the check runs strtoll) --\n";
cmpthese(-2, {
    'untyped floor'    => sub { BUntyped::a($ui, $plain_num) },
    'plain variable'   => sub { BInt::a($oi, $plain_num)  },
    '<: variable'      => sub { BInt::a($oi, $const_num)  },
});

print "\n-- Str slot --\n";
cmpthese(-2, {
    'untyped floor'    => sub { BUntyped::a($ui, $plain_str) },
    'plain variable'   => sub { BStr::a($os, $plain_str)     },
    '<: variable'      => sub { BStr::a($os, $const_str)     },
});

print <<'NOTE';

The `<: variable` rows should sit with the untyped floor rather than with the
plain variable: the type check is not being made cheaper, it is not being run.

The classes themselves are defined inside a BEGIN block from `<:` variables. A
plain `my` variable is empty at that point, because its assignment has not run
yet; a `<:` one is not.
NOTE
