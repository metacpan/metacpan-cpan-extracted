use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::EIP',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::EIP->new( %$_ ) };

package Cfn::Resource::AWS::EC2::EIP {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::EIP', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::EIP {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has InstanceId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  #TODO: Domain has restrictions
  has Domain => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
