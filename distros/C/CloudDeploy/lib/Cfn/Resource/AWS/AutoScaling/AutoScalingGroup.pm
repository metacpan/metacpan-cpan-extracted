use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AutoScaling::AutoScalingGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AutoScaling::AutoScalingGroup->new( %$_ ) };

package Cfn::Resource::AWS::AutoScaling::AutoScalingGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AutoScaling::AutoScalingGroup', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::AutoScaling::AutoScalingGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has AvailabilityZones => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, required => 1);
  has Cooldown => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has DesiredCapacity => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has HealthCheckGracePeriod => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has HealthCheckType => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has LaunchConfigurationName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has LoadBalancerNames => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has MaxSize => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has MinSize => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);;
  has NotificationConfigurations => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has TerminationPolicies => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has VPCZoneIdentifier => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has MetricsCollection => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, required => 0);
}

1;
