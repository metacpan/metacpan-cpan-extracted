use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::NetworkInterface',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::NetworkInterface->new( %$_ ) };

package Cfn::Resource::AWS::EC2::NetworkInterface {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkInterface', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::NetworkInterface  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Description => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has GroupSet => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has PrivateIpAddress => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has PrivateIpAddresses => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has SecondaryPrivateIpAddressCount => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has SourceDestCheck => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has SubnetId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
