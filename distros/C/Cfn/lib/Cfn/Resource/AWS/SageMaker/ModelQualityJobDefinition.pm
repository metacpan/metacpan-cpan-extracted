# AWS::SageMaker::ModelQualityJobDefinition generated from spec 22.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition->new( %$_ ) };

package Cfn::Resource::AWS::SageMaker::ModelQualityJobDefinition {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'CreationTime','JobDefinitionArn' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::S3Output',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::S3Output',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::S3Output->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::S3Output {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LocalPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3UploadMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3Uri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::VpcConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::VpcConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::VpcConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::VpcConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SecurityGroupIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Subnets => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::MonitoringOutput',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::MonitoringOutput',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::MonitoringOutput')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::MonitoringOutput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::MonitoringOutput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::MonitoringOutput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::MonitoringOutput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3Output => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::S3Output', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::MonitoringGroundTruthS3Input',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::MonitoringGroundTruthS3Input',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::MonitoringGroundTruthS3Input->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::MonitoringGroundTruthS3Input {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3Uri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::Environment',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::Environment',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::Environment->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::Environment {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::EndpointInput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::EndpointInput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::EndpointInput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::EndpointInput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EndpointName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EndTimeOffset => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InferenceAttribute => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LocalPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ProbabilityAttribute => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ProbabilityThresholdAttribute => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3DataDistributionType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3InputMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has StartTimeOffset => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::ConstraintsResource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::ConstraintsResource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::ConstraintsResource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::ConstraintsResource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3Uri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::ClusterConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::ClusterConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::ClusterConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::ClusterConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InstanceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VolumeKmsKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VolumeSizeInGB => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::StoppingCondition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::StoppingCondition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::StoppingCondition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::StoppingCondition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxRuntimeInSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::NetworkConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::NetworkConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::NetworkConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::NetworkConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EnableInterContainerTrafficEncryption => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EnableNetworkIsolation => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VpcConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::VpcConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::MonitoringResources',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::MonitoringResources',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::MonitoringResources->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::MonitoringResources {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClusterConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::ClusterConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::MonitoringOutputConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::MonitoringOutputConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::MonitoringOutputConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::MonitoringOutputConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has KmsKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MonitoringOutputs => (isa => 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::MonitoringOutput', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::ModelQualityJobInput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::ModelQualityJobInput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::ModelQualityJobInput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::ModelQualityJobInput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EndpointInput => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::EndpointInput', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has GroundTruthS3Input => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::MonitoringGroundTruthS3Input', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::ModelQualityBaselineConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::ModelQualityBaselineConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::ModelQualityBaselineConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::ModelQualityBaselineConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BaseliningJobName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ConstraintsResource => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::ConstraintsResource', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::ModelQualityAppSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::ModelQualityAppSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::ModelQualityAppSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelQualityJobDefinition::ModelQualityAppSpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ContainerArguments => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ContainerEntrypoint => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Environment => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::Environment', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ImageUri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has PostAnalyticsProcessorSourceUri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ProblemType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RecordPreprocessorSourceUri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has JobDefinitionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has JobResources => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::MonitoringResources', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ModelQualityAppSpecification => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::ModelQualityAppSpecification', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ModelQualityBaselineConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::ModelQualityBaselineConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ModelQualityJobInput => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::ModelQualityJobInput', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ModelQualityJobOutputConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::MonitoringOutputConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has NetworkConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::NetworkConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has StoppingCondition => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelQualityJobDefinition::StoppingCondition', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::SageMaker::ModelQualityJobDefinition - Cfn resource for AWS::SageMaker::ModelQualityJobDefinition

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::SageMaker::ModelQualityJobDefinition.

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
