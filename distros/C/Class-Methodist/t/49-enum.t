## -*- perl -*-

################ TestClass ################
package TestClass;

use Class::Methodist
  (
   ctor => 'new',
   enum => { name => 'color',
	     domain => [ qw/red orange yellow green blue indigo violet/ ],
	     default => 'red' },
   enum => { name => 'shipping',
	     domain => [ qw/sea air land/ ] },
  );

################ main ################
package main;

use Test::More tests => 16;
use Test::Exception;

can_ok('TestClass', 'new');
my $tc1 = TestClass->new();
isa_ok($tc1, 'TestClass');

is($tc1->color(), 'red', 'Check for default color');
is($tc1->shipping(), undef, 'Check for default shipping');

foreach my $val (qw/air land sea/) {
  $tc1->shipping($val);
  is($tc1->shipping(), $val, 'Valid shipping');
}

foreach my $val (qw/indigo green red orange violet yellow blue/) {
  $tc1->color($val);
  is($tc1->color(), $val, 'Valid color');
}

dies_ok { $tc1->shipping('pony express') } 'Invalid shipping';
dies_ok { $tc1->color('fuscia') } 'Invalid color';
