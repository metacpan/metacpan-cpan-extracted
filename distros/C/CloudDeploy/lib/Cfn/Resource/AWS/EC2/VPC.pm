use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::VPC',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::VPC->new( %$_ ) };

package Cfn::Resource::AWS::EC2::VPC {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::VPC', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::VPC {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has CidrBlock => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has InstanceTenancy => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has EnableDnsHostnames => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has EnableDnsSupport => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
