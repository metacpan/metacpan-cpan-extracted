use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::RDS::DBSecurityGroupIngress',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::RDS::DBSecurityGroupIngress->new( %$_ ) };

package Cfn::Resource::AWS::RDS::DBSecurityGroupIngress {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::RDS::DBSecurityGroupIngress', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::RDS::DBSecurityGroupIngress  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has CIDRIP => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has DBSecurityGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has EC2SecurityGroupId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has EC2SecurityGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has EC2SecurityGroupOwnerId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
