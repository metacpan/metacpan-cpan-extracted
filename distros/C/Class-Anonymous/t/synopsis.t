use strict;
use warnings;

use Test::More;

use Class::Anonymous;
use Class::Anonymous::Utils ':all';

my $lifeform = class {
  my ($self, $name) = @_;
  method greeting => sub { "My name is $name" };
};

my $mortal = extend $lifeform => via {
  my ($self, $name, $age) = @_;
  around greeting => sub {
    my $orig = shift;
    $orig->() . " and I'm $age years old";
  };
};

my $bob = $mortal->new('Bob', 40);
is $bob->greeting, q[My name is Bob and I'm 40 years old], 'correct greeting';
isa_ok $bob, $mortal, 'Bob is a mortal';
isa_ok $bob, $lifeform, 'Bob is a lifeform';

done_testing;

