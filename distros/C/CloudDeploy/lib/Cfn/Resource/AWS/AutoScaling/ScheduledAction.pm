use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AutoScaling::ScheduledAction',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AutoScaling::ScheduledAction->new( %$_ ) };

package Cfn::Resource::AWS::AutoScaling::ScheduledAction {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AutoScaling::ScheduledAction', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::AutoScaling::ScheduledAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has AutoScalingGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has DesiredCapacity => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has EndTime => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has MaxSize => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has MinSize => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Recurrence => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has StartTime => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
