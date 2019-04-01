# AWS::AutoScalingPlans::ScalingPlan generated from spec 2.25.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan->new( %$_ ) };

package Cfn::Resource::AWS::AutoScalingPlans::ScalingPlan {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'ScalingPlanName','ScalingPlanVersion' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::MetricDimension',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::MetricDimension',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::MetricDimension')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::MetricDimension',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::MetricDimension',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::MetricDimensionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::MetricDimensionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::PredefinedScalingMetricSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::PredefinedScalingMetricSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::PredefinedScalingMetricSpecificationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::PredefinedScalingMetricSpecificationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PredefinedScalingMetricType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceLabel => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::CustomizedScalingMetricSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::CustomizedScalingMetricSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::CustomizedScalingMetricSpecificationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::CustomizedScalingMetricSpecificationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Dimensions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::MetricDimension', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Namespace => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Statistic => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Unit => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::TargetTrackingConfiguration',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::TargetTrackingConfiguration',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::TargetTrackingConfiguration')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::TargetTrackingConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::TargetTrackingConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::TargetTrackingConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::TargetTrackingConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CustomizedScalingMetricSpecification => (isa => 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::CustomizedScalingMetricSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DisableScaleIn => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EstimatedInstanceWarmup => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PredefinedScalingMetricSpecification => (isa => 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::PredefinedScalingMetricSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScaleInCooldown => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScaleOutCooldown => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetValue => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::TagFilter',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::TagFilter',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::TagFilter')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::TagFilter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::TagFilter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::TagFilterValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::TagFilterValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Values => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::PredefinedLoadMetricSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::PredefinedLoadMetricSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::PredefinedLoadMetricSpecificationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::PredefinedLoadMetricSpecificationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PredefinedLoadMetricType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceLabel => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::CustomizedLoadMetricSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::CustomizedLoadMetricSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::CustomizedLoadMetricSpecificationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::CustomizedLoadMetricSpecificationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Dimensions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::MetricDimension', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Namespace => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Statistic => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Unit => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::ScalingInstruction',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::ScalingInstruction',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::ScalingInstruction')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::ScalingInstruction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::ScalingInstruction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::ScalingInstructionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::ScalingInstructionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CustomizedLoadMetricSpecification => (isa => 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::CustomizedLoadMetricSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DisableDynamicScaling => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxCapacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinCapacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PredefinedLoadMetricSpecification => (isa => 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::PredefinedLoadMetricSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PredictiveScalingMaxCapacityBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PredictiveScalingMaxCapacityBuffer => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PredictiveScalingMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScalableDimension => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScalingPolicyUpdateBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScheduledActionBufferTime => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceNamespace => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetTrackingConfigurations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::TargetTrackingConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::ApplicationSource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::ApplicationSource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::ApplicationSourceValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::ApplicationSourceValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudFormationStackARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TagFilters => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::TagFilter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApplicationSource => (isa => 'Cfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::ApplicationSource', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScalingInstructions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AutoScalingPlans::ScalingPlan::ScalingInstruction', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
