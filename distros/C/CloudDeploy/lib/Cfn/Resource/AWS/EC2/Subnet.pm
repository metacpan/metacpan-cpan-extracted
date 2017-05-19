use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::Subnet',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::Subnet->new( %$_ ) };

package Cfn::Resource::AWS::EC2::Subnet {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::Subnet', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::Subnet  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has AvailabilityZone => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has CidrBlock => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has VpcId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
