# AWS::Pinpoint::App generated from spec 6.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Pinpoint::App',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Pinpoint::App->new( %$_ ) };

package Cfn::Resource::AWS::Pinpoint::App {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Pinpoint::App', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn' ]
  }
  sub supported_regions {
    [ 'ap-south-1','ap-southeast-2','eu-central-1','eu-west-1','us-east-1','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::Pinpoint::App {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
