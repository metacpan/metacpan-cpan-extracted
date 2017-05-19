use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CloudWatch::Alarm',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CloudWatch::Alarm->new( %$_ ) };

package Cfn::Resource::AWS::CloudWatch::Alarm {
   use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CloudWatch::Alarm', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::CloudWatch::Alarm  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has ActionsEnabled => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has AlarmActions => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has AlarmDescription => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has AlarmName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  # TODO: restriction GreaterThanOrEqualToThreshold | GreaterThanThreshold | LessThanThreshold | LessThanOrEqualToThreshold
  has ComparisonOperator => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Dimensions => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has EvaluationPeriods => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has InsufficientDataActions => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has MetricName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Namespace => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has OKActions => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Period => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Statistic => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Threshold => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Unit => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
