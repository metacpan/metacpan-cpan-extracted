BEGIN{ $ENV{CLASS_SLOT_NO_XS} = 1 };

package Class_A;

sub new {
  my $class = shift;
  bless { @_ , new_Class_A => 1 }, $class;
}

1;


package Class_B;
use Class::Slot;
use Scalar::Util qw(looks_like_number);
use parent -norequire, 'Class_A';

slot new_Class_B => \&looks_like_number, req => 1;

1;


package Class_C;
use parent -norequire, 'Class_B';

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);
  $self->{new_Class_C} = 1;
  return $self;
}

1;


package Class_D;
use Class::Slot;
use parent -norequire, 'Class_B';

slot new_Class_B => sub{ 1 };

1;


package main;
use Class::Slot -debug;
use Test2::V0;

ok(Class_B->isa('Class_A'), 'Class_B isa Class_A');
ok(Class_C->isa('Class_B'), 'Class_C isa Class_B');

ok my $o = Class_C->new(new_Class_B => 1), 'ctor';

ok $o->isa('Class_A'), 'isa Class_A';
is $o->{new_Class_A}, 1, 'new_Class_A';

ok $o->isa('Class_B'), 'isa Class_B';
is $o->new_Class_B, 1, 'new_Class_B';

ok $o->isa('Class_C'), 'isa Class_C';
is $o->{new_Class_C}, 1, 'new_Class_C';

ok(do{ eval{ C->new(new_Class_B => 'foo') }; $@ }, 'type check when called from non-slots child class');
ok(Class_D->new(new_Class_B => 'foo'), 'type check skipped when called from slots-based child class');

done_testing;
