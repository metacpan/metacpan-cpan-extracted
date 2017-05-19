use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Events::Rule',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Events::Rule->new( %$_ ) };

package Cfn::Resource::AWS::Events::Rule {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Events::Rule', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::Events::Rule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Description => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has EventPattern => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Name => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has RoleArn => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has ScheduleExpression => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has State => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Targets => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
