#!perl -T

use strict;
use warnings;

use Test::More;

use B::RecDeparse;

my $brd = B::RecDeparse->new(level => -1);

sub foo { 123 }
sub baz;
my $pkg;
my $coderef;

my @tests = (
 [ e1 => 'foo()',      '123' ],
 [ e2 => 'foo(1)',     '123' ],
 [ e3 => 'foo(@_)',    '123' ],
 [ e4 => 'foo(shift)', '123' ],

 [ n1 => 'bar()',      'bar' ],
 [ n2 => 'bar(1)',     'bar' ],
 [ n3 => 'bar(@_)',    'bar' ],
 [ n4 => 'bar(shift)', 'bar' ],

 [ d1 => 'baz()',      'baz' ],
 [ d2 => 'baz(1)',     'baz' ],
 [ d3 => 'baz(@_)',    'baz' ],
 [ d4 => 'baz(shift)', 'baz' ],

 [ c1 => '$coderef->()',      'coderef' ],
 [ c2 => '$coderef->(1)',     'coderef' ],
 [ c3 => '$coderef->(@_)',    'coderef' ],
 [ c4 => '$coderef->(shift)', 'coderef' ],

 [ m1  => '"pkg"->qux()',      'qux' ],
 [ m2  => '"pkg"->qux(1)',     'qux' ],
 [ m3  => '"pkg"->qux(@_)',    'qux' ],
 [ m4  => '"pkg"->qux(shift)', 'qux' ],
 [ m5  => '$pkg->qux()',       'qux' ],
 [ m6  => '$pkg->qux(1)',      'qux' ],
 [ m7  => '$pkg->qux(@_)',     'qux' ],
 [ m8  => '$pkg->qux(shift)',  'qux' ],
 [ m9  => 'shift->qux()',      'qux' ],
 [ m10 => 'shift->qux(1)',     'qux' ],
 [ m11 => 'shift->qux(@_)',    'qux' ],
 [ m12 => 'shift->qux(shift)', 'qux' ],
);

if (eval 'use List::Util qw<sum>; 1') {
 push @tests, (
  [ x1 => 'sum()',      'sum' ],
  [ x2 => 'sum(1)',     'sum' ],
  [ x3 => 'sum(@_)',    'sum' ],
  [ x4 => 'sum(shift)', 'sum' ],
 );
}

plan tests => 2 * @tests;

for my $test (@tests) {
 my ($name, $source, $match) = @$test;

 my $code = do {
  local $@;
  eval "sub { $source }";
 };

 my $res = eval { $brd->coderef2text($code) };
 is  $@,    '',             "deparsing sub $name doesn't croak";
 $res = '' unless defined $res;
 like $res, qr/\Q$match\E/, "deparsing sub $name works as expected";
}
