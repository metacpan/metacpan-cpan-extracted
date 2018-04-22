package A;

sub new {
  my $class = shift;
  bless { @_ , new_A => 1 }, $class;
}

1;

package B;
use Types::Standard -types;
use Class::Slot;

use parent -norequire, 'A';

slot new_B => Int, req => 1;

1;

package C;

use parent -norequire, 'B';

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);
  $self->{new_C} = 1;
  return $self;
}

1;

package D;
use Types::Standard -types;
use Class::Slot;

use parent -norequire, 'B';

slot new_B => Any;

1;

package main;
use Class::Slot -debug;
use Test::More;

ok my $o = C->new(new_B => 1), 'ok';

ok $o->isa('A'), 'isa A';
is $o->{new_A}, 1, 'new_A';

ok $o->isa('B'), 'isa B';
is $o->new_B, 1, 'new_B';

ok $o->isa('C'), 'isa C';
is $o->{new_C}, 1, 'new_C';

ok(do{ eval{ C->new(new_B => 'foo') }; $@ }, 'type check when called from non-slots child class');
ok(D->new(new_B => 'foo'), 'type check skipped when called from slots-based child class');

done_testing;
