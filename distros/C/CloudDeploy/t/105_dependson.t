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
  has Prop1 => (is => 'ro', isa => 'Cfn::Value', coerce => 1);
  has Prop2 => (is => 'ro', isa => 'Cfn::Value', coerce => 1);
  has Prop3 => (is => 'ro', isa => 'Cfn::Value', coerce => 1);
  has ArrayProp => (is => 'ro', isa => 'Cfn::Value::Array', coerce => 1);
}

package Cfn::Resource::Type1 {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (is => 'ro', isa => 'Cfn::Resource::Properties::DummyProps', coerce => 1);
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
  resource R4 => 'Type1', { ArrayProp => [ Ref('R3'), Ref('R4') ] };
  resource R5 => 'Type1', { Prop3 => { 'Fn::Join' => [ ' ', [ 'hello ', Ref('R3') ] ] } };
  resource R6 => 'Type1', { Prop1 => GetAtt('R2', 'Prop1') };
  resource R7 => 'Type1', { Prop1 => Ref('R1') }, { DependsOn => [ 'R2', 'R3' ] };
  resource R8 => 'Type1', { Prop1 => Ref('R2') }, { DependsOn => [ 'R2', 'R3' ] };
  resource R9 => 'Type1', { Prop1 => Ref('R2'), Prop2 => Ref('R2') };
  resource R10 => 'Type1', { Prop1 => Ref('R2'), Prop2 => GetAtt('R2', 'Attribute') };
  resource R11 => 'Type1', { Prop1 => Ref('R2'), Prop2 => Ref('R2'), ArrayProp => [ Ref('R2') ] };
  resource R12 => 'Type1', { }, { DependsOn => 'R1' };
}


my $o = Test1->new;

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
  { resource => 'R12', deps => [ 'R1' ], desc => 'A non-arrayref DependsOn works' },
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
