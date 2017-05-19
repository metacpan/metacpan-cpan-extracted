use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::RDS::DBSecurityGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::RDS::DBSecurityGroup->new( %$_ ) };

package Cfn::Resource::AWS::RDS::DBSecurityGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::RDS::DBSecurityGroup', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::RDS::DBSecurityGroup  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has EC2VpcId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has DBSecurityGroupIngress => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, required => 1);
  has GroupDescription => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
