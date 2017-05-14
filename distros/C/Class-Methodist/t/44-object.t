## -*- perl -*-

################ TraditionalClass ################
package TraditionalClass;

sub new {
  my $class = shift;
  bless { }, $class;
}

sub set {
  my ($self, $val) = @_;
  $self->{val} = $val;
}

sub get {
  my $self = shift;
  return $self->{val}
}

################ TestClassOne ################
package TestClassOne;

use Class::Methodist
  (
   ctor => 'new',
   object => 'obj'
  );

################ TestClassTwo ################
package TestClassTwo;

use Class::Methodist
  (
   object => { name => 'one', class => 'TestClassOne' }
  );

sub new {
  my $class = shift;
  $class->beget(one => TestClassOne->new());
}

################ main ################
package main;

use Test::More 'no_plan';

my $trad = TraditionalClass->new();
$trad->set(42);

my $tc1 = TestClassOne->new();
$tc1->obj($trad);

my $trad2 = $tc1->obj();
is($trad2->get(), 42, 'Values match');

my $tc2 = TestClassTwo->new();

ok(defined($tc2->{one}), 'Value set');
$tc2->clear_one();
ok(! defined($tc2->{one}), 'Value cleared');
