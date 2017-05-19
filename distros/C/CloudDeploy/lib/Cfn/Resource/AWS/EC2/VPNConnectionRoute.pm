use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::VPNConnectionRoute',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::VPNConnectionRoute->new( %$_ ) };

package Cfn::Resource::AWS::EC2::VPNConnectionRoute {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::VPNConnectionRoute', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::VPNConnectionRoute  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has DestinationCidrBlock => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has VpnConnectionId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
