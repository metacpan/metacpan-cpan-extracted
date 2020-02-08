BEGIN{ $ENV{CLASS_SLOT_NO_XS} = 1 };


package Class_A;
use Class::Slot;
sub foo{ 42 }
1;


package Class_B;
use Class::Slot;
slot 'bar', def => sub{ Class_A->new }, fwd => ['foo'];
slot 'baz', def => sub{ Class_A->new }, fwd => {bat => 'foo'};
1;


package main;
use Test2::V0;

my $obj = Class_B->new;
is $obj->foo, 42, 'defined as array';
is $obj->bat, 42, 'defined as hash';

eval q{
  package Class_C;
  use Class::Slot;
  slot 'x', fwd => 'invalid type';
};

ok $@, 'fwd croaks on invalid type' or diag $@;

done_testing;
