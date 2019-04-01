# AWS::EMR::InstanceGroupConfig generated from spec 2.25.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig->new( %$_ ) };

package Cfn::Resource::AWS::EMR::InstanceGroupConfig {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::MetricDimension',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::MetricDimension',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::MetricDimension')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::MetricDimension',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::MetricDimension',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::MetricDimensionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::MetricDimensionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::SimpleScalingPolicyConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::SimpleScalingPolicyConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::SimpleScalingPolicyConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::SimpleScalingPolicyConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdjustmentType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CoolDown => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScalingAdjustment => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::CloudWatchAlarmDefinition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::CloudWatchAlarmDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::CloudWatchAlarmDefinitionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::CloudWatchAlarmDefinitionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ComparisonOperator => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Dimensions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::MetricDimension', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EvaluationPeriods => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Namespace => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Period => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Statistic => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Threshold => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Unit => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::VolumeSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::VolumeSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::VolumeSpecificationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::VolumeSpecificationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Iops => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SizeInGB => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VolumeType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingTrigger',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingTrigger',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingTriggerValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingTriggerValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudWatchAlarmDefinition => (isa => 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::CloudWatchAlarmDefinition', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingActionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingActionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Market => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SimpleScalingPolicyConfiguration => (isa => 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::SimpleScalingPolicyConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingRule',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingRule',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingRule')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingRule',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingRule',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingRuleValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingRuleValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Action => (isa => 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingAction', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Trigger => (isa => 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingTrigger', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingConstraints',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingConstraints',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingConstraintsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingConstraintsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxCapacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinCapacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::EbsBlockDeviceConfig',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::EbsBlockDeviceConfig',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::EbsBlockDeviceConfig')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::EbsBlockDeviceConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::EbsBlockDeviceConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::EbsBlockDeviceConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::EbsBlockDeviceConfigValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VolumeSpecification => (isa => 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::VolumeSpecification', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VolumesPerInstance => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::EbsConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::EbsConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::EbsConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::EbsConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EbsBlockDeviceConfigs => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::EbsBlockDeviceConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EbsOptimized => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::Configuration',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::Configuration',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::Configuration')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::Configuration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::Configuration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Classification => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ConfigurationProperties => (isa => 'Cfn::Value::Hash|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Configurations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::Configuration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::AutoScalingPolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::AutoScalingPolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::AutoScalingPolicyValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::AutoScalingPolicyValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Constraints => (isa => 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingConstraints', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Rules => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::ScalingRule', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AutoScalingPolicy => (isa => 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::AutoScalingPolicy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BidPrice => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Configurations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::Configuration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EbsConfiguration => (isa => 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig::EbsConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InstanceCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InstanceRole => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InstanceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has JobFlowId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Market => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
