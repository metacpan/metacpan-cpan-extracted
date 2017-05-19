use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::VPNConnection',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::VPNConnection->new( %$_ ) };

package Cfn::Resource::AWS::EC2::VPNConnection {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::VPNConnection', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::VPNConnection  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Type => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has CustomerGatewayId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has VpnGatewayId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has StaticRoutesOnly => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
