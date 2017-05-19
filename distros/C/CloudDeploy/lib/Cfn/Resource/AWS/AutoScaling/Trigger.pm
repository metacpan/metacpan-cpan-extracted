use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AutoScaling::Trigger',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AutoScaling::Trigger->new( %$_ ) };

package Cfn::Resource::AWS::AutoScaling::Trigger {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AutoScaling::Trigger', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::AutoScaling::Trigger  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has AutoScalingGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has BreachDuration => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Dimensions => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, required => 1);
  has LowerBreachScaleIncrement => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has LowerThreshold => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has MetricName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Namespace => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Period => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Statistic => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Unit => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has UpperBreachScaleIncrement => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has UpperThreshold => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
