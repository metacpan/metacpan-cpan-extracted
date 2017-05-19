use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ECS::Service',
  from 'HashRef',
  via { Cfn::Resource::Properties::AWS::ECS::Service->new( %$_ ) };

package Cfn::Resource::AWS::ECS::Service {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ECS::Service', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::ECS::Service  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Cluster => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has DesiredCount => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has LoadBalancers => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Role => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has TaskDefinition => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
