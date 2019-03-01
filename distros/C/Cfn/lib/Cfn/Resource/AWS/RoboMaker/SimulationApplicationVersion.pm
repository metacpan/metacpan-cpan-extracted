# AWS::RoboMaker::SimulationApplicationVersion generated from spec 2.24.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplicationVersion',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplicationVersion->new( %$_ ) };

package Cfn::Resource::AWS::RoboMaker::SimulationApplicationVersion {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplicationVersion', is => 'rw', coerce => 1);
  sub _build_attributes {
    [  ]
  }
}



package Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplicationVersion {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Application => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has CurrentRevisionId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
