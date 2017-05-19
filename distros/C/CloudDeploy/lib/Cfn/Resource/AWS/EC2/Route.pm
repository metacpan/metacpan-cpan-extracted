use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::Route',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::Route->new( %$_ ) };

package Cfn::Resource::AWS::EC2::Route {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::Route', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::Route  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has DestinationCidrBlock => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has DestinationIpv6CidrBlock => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has GatewayId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has InstanceId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has NatGatewayId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has NetworkInterfaceId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has RouteTableId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has VpcPeeringConnectionId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
