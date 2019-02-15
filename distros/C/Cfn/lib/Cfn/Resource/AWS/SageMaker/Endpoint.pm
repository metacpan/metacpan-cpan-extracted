# AWS::SageMaker::Endpoint generated from spec 2.5.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SageMaker::Endpoint->new( %$_ ) };

package Cfn::Resource::AWS::SageMaker::Endpoint {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'EndpointName' ]
  }
}



package Cfn::Resource::Properties::AWS::SageMaker::Endpoint {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has EndpointConfigName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EndpointName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
