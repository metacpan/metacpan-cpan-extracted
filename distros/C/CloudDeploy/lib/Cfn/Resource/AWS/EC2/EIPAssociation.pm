use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::EIPAssociation',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::EIPAssociation->new( %$_ ) };

package Cfn::Resource::AWS::EC2::EIPAssociation {
   use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::EIPAssociation', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::EIPAssociation  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has AllocationId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has EIP => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has InstanceId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has NetworkInterfaceId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has PrivateIpAddress => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
