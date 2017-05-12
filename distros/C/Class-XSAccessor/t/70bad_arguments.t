use strict;
use warnings;

use Test::More tests => 3 + 6;
BEGIN { use_ok('Class::XSAccessor') };
BEGIN { use_ok('Class::XSAccessor::Array') };

package FooHash;
use Class::XSAccessor
  getters => {
    get_foo => 'foo',
  };

package FooArray;
use Class::XSAccessor::Array
  getters => {
    get_foo => 0,
  };

package main;

BEGIN {pass();}

my ($foo, $bar);
my @tests = (
  { 
    name => 'Hash as Hash object',
    expect => 'pass',
    obj => bless({} => 'FooHash'),
  },
  { 
    name => 'Array as Hash object',
    expect => 'fail',
    obj => bless([] => 'FooHash'),
  },
  { 
    name => 'Scalar as Hash object',
    expect => 'fail',
    obj => bless(\$foo => 'FooHash'),
  },
  { 
    name => 'Hash as Array object',
    expect => 'fail',
    obj => bless({} => 'FooArray'),
  },
  { 
    name => 'Array as Array object',
    expect => 'pass',
    obj => bless([] => 'FooArray'),
  },
  { 
    name => 'Scalar as Array object',
    expect => 'fail',
    obj => bless(\$bar => 'FooArray'),
  },
);

foreach my $test (sort {$a->{name} cmp $b->{name}} @tests) {
  my ($expect, $name, $obj) = @{$test}{qw(expect name obj)};
  
  my $okay = eval {
    $obj->get_foo;
    1;
  };
  my $err = $@ || '';
  chomp $err;
  ok(
    ($expect eq 'pass' && $okay)
    || ($expect eq 'fail' && !$okay),
    "$name (errmsg: $err)"
  );
}


