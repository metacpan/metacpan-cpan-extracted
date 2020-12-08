# AWS::AutoScalingPlans::ScalingPlan generated from spec 18.4.0
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
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
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
       return Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::MetricDimension->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::MetricDimension {
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
       return Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::PredefinedScalingMetricSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::PredefinedScalingMetricSpecification {
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
       return Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::CustomizedScalingMetricSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::CustomizedScalingMetricSpecification {
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
       return Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::TargetTrackingConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::TargetTrackingConfiguration {
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
       return Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::TagFilter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::TagFilter {
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
       return Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::PredefinedLoadMetricSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::PredefinedLoadMetricSpecification {
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
       return Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::CustomizedLoadMetricSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::CustomizedLoadMetricSpecification {
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
       return Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::ScalingInstruction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::ScalingInstruction {
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
       return Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::ApplicationSource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AutoScalingPlans::ScalingPlan::ApplicationSource {
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
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::AutoScalingPlans::ScalingPlan - Cfn resource for AWS::AutoScalingPlans::ScalingPlan

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::AutoScalingPlans::ScalingPlan.

See L<Cfn> for more information on how to use it.

=head1 AUTHOR

    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com

=head1 COPYRIGHT and LICENSE

Copyright (c) 2013 by CAPSiDE
This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.

=cut
