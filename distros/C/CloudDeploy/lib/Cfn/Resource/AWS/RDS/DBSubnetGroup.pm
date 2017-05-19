use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::RDS::DBSubnetGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::RDS::DBSubnetGroup->new( %$_ ) };

package Cfn::Resource::AWS::RDS::DBSubnetGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::RDS::DBSubnetGroup', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::RDS::DBSubnetGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has DBSubnetGroupDescription => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has SubnetIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
