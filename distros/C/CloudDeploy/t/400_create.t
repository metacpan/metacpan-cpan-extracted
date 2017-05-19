#/usr/bin/env perl

use CCfn;

use Data::Dumper;
use Test::More;

use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::DummyProps',
  from 'HashRef',
   via { Cfn::Resource::Properties::DummyProps->new( %$_ ) };

package Cfn::Resource::Properties::DummyProps {
  use Moose;
  extends 'Cfn::Resource::Properties';

  has Prop1 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop2 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop3 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has ArrayProp => (is => 'rw', isa => 'Cfn::Value::Array', coerce => 1);
}

package Cfn::Resource::Properties::DummyInstanceProps {
  use Moose;
  extends 'Cfn::Resource::Properties';

  has Name => (is => 'ro', isa => 'Str');
  has IP => (is => 'ro', isa => 'Str', traits => ['RefValue']);
  has Prop1 => (is => 'ro', isa => 'Str');
  has Attribute => (is => 'ro', isa => 'Str');
}

package Cfn::Resource::Type1 {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (is => 'ro', isa => 'Cfn::Resource::Properties::DummyProps', coerce => 1);

  has Instance => (is => 'rw');

  sub create {
    my ($self, $logical_name, $stack_name) = @_;
    my $name = sprintf('%s-%s', $logical_name, $stack_name);
    # do the provisioning...
    $self->Instance(
      Cfn::Resource::Properties::DummyInstanceProps->new(
        Name => $name, 
        IP => '0.0.0.0',
        Prop1 => 'Prop1', 
        Attribute => 'Attribute'
      )
    );
  }

  sub find {

  }

  sub update {

  }
}

package Test1 {
  use Moose;
  extends 'CCfn';
  use CCfnX::Shortcuts;
  use CCfnX::CommonArgs;

  has params => (is => 'ro', default => sub { CCfnX::CommonArgs->new(
    name => 'test',
    account => 'devel-capside',
    region => 'eu-west-1',
  ) });

  resource R1 => 'Type1', { }, { DependsOn => [ 'R2', 'R3' ] };
  resource R2 => 'Type1', { };
  resource R3 => 'Type1', { Prop1 => Ref('R2') };
  resource R4 => 'Type1', { ArrayProp => [ Ref('R3') ] }; #, Ref('R5') ] };
  # resource R5 => 'Type1', { Prop3 => { 'Fn::Join' => [ ' ', [ 'hello ', Ref('R3') ] ] } };
  resource R6 => 'Type1', { Prop1 => GetAtt('R2', 'Prop1') };
  resource R7 => 'Type1', { Prop1 => Ref('R1') }, { DependsOn => [ 'R2', 'R3' ] };
  resource R8 => 'Type1', { Prop1 => Ref('R2') }, { DependsOn => [ 'R2', 'R3' ] };
  resource R9 => 'Type1', { Prop1 => Ref('R2'), Prop2 => Ref('R2') };
  resource R10 => 'Type1', { Prop1 => Ref('R2'), Prop2 => GetAtt('R2', 'Attribute') };
  resource R11 => 'Type1', { Prop1 => Ref('R2'), Prop2 => Ref('R2'), ArrayProp => [ Ref('R2') ] };
}

my $self = Test1->new;
my $stack_name = '001';

my $order = [ $self->_creation_order ];

my $resource_in_position = {};
my $i = 0;
foreach my $element (@$order) {
  $resource_in_position->{ $element } = $i;
  $i++;
}

sub is_before {
  my ($before, $after) = @_;
  cmp_ok($resource_in_position->{ $before }, '<', $resource_in_position->{ $after }, "$before is before $after in resource order");
}

is_before('R2', 'R1');
is_before('R3', 'R1');
is_before('R2', 'R3');
is_before('R3', 'R4');
is_before('R2', 'R6');
is_before('R2', 'R7');
is_before('R3', 'R7');
is_before('R2', 'R8');
is_before('R3', 'R8');
is_before('R2', 'R9');
is_before('R2', 'R10');
is_before('R2', 'R11');

my @rest = $self->_creation_order;

while (my $logical_name = shift @rest){
  my $object = $self->Resource($logical_name);
  $object->create($logical_name, $stack_name);
  # Will scan all the rest of objects in the stack, and convert all refs and getatts to values
  map { $self->Resource($_)->resolve_references_to_logicalid_with($logical_name, $object->Instance) } @rest;
}

my $o = Test1->new;

if (not $o->does('CCfnX::Dependencies')) {
  pass "Skipping all testing because the dependencies role is not applied";
  done_testing;
  exit 0;
}

my $tests = [
  { resource => 'R1',  deps => [ 'R2', 'R3' ], desc => 'Explicit DependsOn'},
  { resource => 'R2',  deps => [  ], desc => 'No deps' },
  { resource => 'R3',  deps => [ 'R2' ], desc => 'Deps in a property with a Ref' },
  { resource => 'R4',  deps => [ 'R3', 'R4' ], desc => 'Deps in an Array property' },
  { resource => 'R5',  deps => [ 'R3' ], desc => 'Ref in a function gets detected' },
  { resource => 'R6',  deps => [ 'R2' ], desc => 'GetAtt also reports deps' },
  { resource => 'R7',  deps => [ 'R1', 'R2', 'R3' ], desc => 'Mix between implicit and explicit' },
  { resource => 'R8',  deps => [ 'R2', 'R3' ], desc => 'Explicit and implicit repeated should not duplicate' },
  { resource => 'R9',  deps => [ 'R2' ], desc => 'Repeated dep only counted once' },
  { resource => 'R10', deps => [ 'R2' ], desc => 'Dep via Ref and GetAtt only counted once' },
  { resource => 'R11', deps => [ 'R2' ], desc => 'Repeated ref in props and array props' },
];

foreach my $test (@$tests) {
  my @deps;
  @deps = @{ $o->Resource( $test->{ resource} )->dependencies };
  my $desc = $test->{ desc } || '';
  @deps = sort @deps;
  my $num_deps = scalar(@deps);
  is_deeply(\@deps, $test->{deps}, "Got $num_deps deps from $test->{ resource }: $desc") or diag(Dumper(\@deps));
}

done_testing;
