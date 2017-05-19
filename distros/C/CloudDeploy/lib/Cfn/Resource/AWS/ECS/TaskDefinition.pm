use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ECS::TaskDefinition',
  from 'HashRef',
  via { Cfn::Resource::Properties::AWS::ECS::TaskDefinition->new( %$_ ) };

package Cfn::Resource::AWS::ECS::TaskDefinition {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ECS::TaskDefinition', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::ECS::TaskDefinition  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has ContainerDefinitions => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Volumes => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
