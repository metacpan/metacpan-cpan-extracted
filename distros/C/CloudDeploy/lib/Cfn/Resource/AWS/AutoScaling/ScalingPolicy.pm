use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AutoScaling::ScalingPolicy',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AutoScaling::ScalingPolicy->new( %$_ ) };

package Cfn::Resource::AWS::AutoScaling::ScalingPolicy {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AutoScaling::ScalingPolicy', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::AutoScaling::ScalingPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has AdjustmentType => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has AutoScalingGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Cooldown => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has ScalingAdjustment => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has MinAdjustmentMagnitude => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
