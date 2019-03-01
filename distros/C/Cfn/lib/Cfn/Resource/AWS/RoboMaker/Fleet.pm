# AWS::RoboMaker::Fleet generated from spec 2.24.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::RoboMaker::Fleet',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::RoboMaker::Fleet->new( %$_ ) };

package Cfn::Resource::AWS::RoboMaker::Fleet {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::RoboMaker::Fleet', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'Arn' ]
  }
}



package Cfn::Resource::Properties::AWS::RoboMaker::Fleet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
