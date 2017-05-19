use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::SecurityGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::SecurityGroup->new( %$_ ) };

package Cfn::Resource::AWS::EC2::SecurityGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::SecurityGroup', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::SecurityGroup  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has GroupDescription => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has SecurityGroupEgress => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has SecurityGroupIngress => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has VpcId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1)
}

1;
