use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::SecurityGroupIngress',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::SecurityGroupIngress->new( %$_ ) };

package Cfn::Resource::AWS::EC2::SecurityGroupIngress {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::SecurityGroupIngress', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::SecurityGroupIngress  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has GroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has GroupId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has IpProtocol => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has CidrIp => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has SourceSecurityGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has SourceSecurityGroupId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has SourceSecurityGroupOwnerId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has FromPort => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has ToPort => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
