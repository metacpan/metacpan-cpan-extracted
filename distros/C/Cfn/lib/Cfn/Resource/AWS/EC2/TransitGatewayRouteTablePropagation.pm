# AWS::EC2::TransitGatewayRouteTablePropagation generated from spec 2.16.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::TransitGatewayRouteTablePropagation',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::TransitGatewayRouteTablePropagation->new( %$_ ) };

package Cfn::Resource::AWS::EC2::TransitGatewayRouteTablePropagation {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::TransitGatewayRouteTablePropagation', is => 'rw', coerce => 1);
  sub _build_attributes {
    [  ]
  }
}



package Cfn::Resource::Properties::AWS::EC2::TransitGatewayRouteTablePropagation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has TransitGatewayAttachmentId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has TransitGatewayRouteTableId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
