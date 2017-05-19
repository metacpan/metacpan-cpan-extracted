use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::VPCGatewayAttachment',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::VPCGatewayAttachment->new( %$_ ) };

package Cfn::Resource::AWS::EC2::VPCGatewayAttachment {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::VPCGatewayAttachment', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::VPCGatewayAttachment  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has InternetGatewayId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has VpcId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has VpnGatewayId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
