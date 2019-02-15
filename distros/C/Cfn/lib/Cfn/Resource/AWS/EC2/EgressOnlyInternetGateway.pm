# AWS::EC2::EgressOnlyInternetGateway generated from spec 1.11.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::EgressOnlyInternetGateway',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::EgressOnlyInternetGateway->new( %$_ ) };

package Cfn::Resource::AWS::EC2::EgressOnlyInternetGateway {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::EgressOnlyInternetGateway', is => 'rw', coerce => 1);
  sub _build_attributes {
    [  ]
  }
}



package Cfn::Resource::Properties::AWS::EC2::EgressOnlyInternetGateway {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has VpcId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
