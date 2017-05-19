use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::NatGateway',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::NatGateway->new( %$_ ) };

package Cfn::Resource::AWS::EC2::NatGateway{
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::NatGateway', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::NatGateway{
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has AllocationId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has SubnetId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
