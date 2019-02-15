# AWS::ApplicationAutoScaling::ScalingPolicy generated from spec 2.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy->new( %$_ ) };

package Cfn::Resource::AWS::ApplicationAutoScaling::ScalingPolicy {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy', is => 'rw', coerce => 1);
  sub _build_attributes {
    [  ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::MetricDimension',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::MetricDimension',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       die 'Only accepts functions'; 
     }
   },
  from 'ArrayRef',
   via {
     Cfn::Value::Array->new(Value => [
       map { 
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::MetricDimension')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::MetricDimension',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::MetricDimension',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::MetricDimensionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::MetricDimensionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::StepAdjustment',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::StepAdjustment',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       die 'Only accepts functions'; 
     }
   },
  from 'ArrayRef',
   via {
     Cfn::Value::Array->new(Value => [
       map { 
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::StepAdjustment')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::StepAdjustment',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::StepAdjustment',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::StepAdjustmentValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::StepAdjustmentValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MetricIntervalLowerBound => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricIntervalUpperBound => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScalingAdjustment => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::PredefinedMetricSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::PredefinedMetricSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::PredefinedMetricSpecificationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::PredefinedMetricSpecificationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PredefinedMetricType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceLabel => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::CustomizedMetricSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::CustomizedMetricSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::CustomizedMetricSpecificationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::CustomizedMetricSpecificationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Dimensions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::MetricDimension', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Namespace => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Statistic => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Unit => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::TargetTrackingScalingPolicyConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::TargetTrackingScalingPolicyConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::TargetTrackingScalingPolicyConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::TargetTrackingScalingPolicyConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CustomizedMetricSpecification => (isa => 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::CustomizedMetricSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DisableScaleIn => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PredefinedMetricSpecification => (isa => 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::PredefinedMetricSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScaleInCooldown => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScaleOutCooldown => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetValue => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::StepScalingPolicyConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::StepScalingPolicyConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::StepScalingPolicyConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::StepScalingPolicyConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdjustmentType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Cooldown => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricAggregationType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinAdjustmentMagnitude => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StepAdjustments => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::StepAdjustment', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has PolicyName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has PolicyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ScalableDimension => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ScalingTargetId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ServiceNamespace => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has StepScalingPolicyConfiguration => (isa => 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::StepScalingPolicyConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetTrackingScalingPolicyConfiguration => (isa => 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalingPolicy::TargetTrackingScalingPolicyConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
