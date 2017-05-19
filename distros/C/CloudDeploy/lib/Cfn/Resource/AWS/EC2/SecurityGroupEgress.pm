use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::SecurityGroupEgress',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::SecurityGroupEgress->new( %$_ ) };

package Cfn::Resource::AWS::EC2::SecurityGroupEgress {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::SecurityGroupEgress', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::SecurityGroupEgress  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has CidrIp => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has DestinationSecurityGroupId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has FromPort => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has GroupId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has IpProtocol => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has ToPort => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
