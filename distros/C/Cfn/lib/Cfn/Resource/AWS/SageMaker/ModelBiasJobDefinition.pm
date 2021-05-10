# AWS::SageMaker::ModelBiasJobDefinition generated from spec 22.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition->new( %$_ ) };

package Cfn::Resource::AWS::SageMaker::ModelBiasJobDefinition {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'CreationTime','JobDefinitionArn' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::S3Output',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::S3Output',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::S3Output->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::S3Output {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LocalPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3UploadMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3Uri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::VpcConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::VpcConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::VpcConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::VpcConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SecurityGroupIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Subnets => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::MonitoringOutput',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::MonitoringOutput',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::MonitoringOutput')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::MonitoringOutput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::MonitoringOutput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::MonitoringOutput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::MonitoringOutput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3Output => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::S3Output', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::MonitoringGroundTruthS3Input',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::MonitoringGroundTruthS3Input',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::MonitoringGroundTruthS3Input->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::MonitoringGroundTruthS3Input {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3Uri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::Environment',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::Environment',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::Environment->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::Environment {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::EndpointInput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::EndpointInput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::EndpointInput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::EndpointInput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EndpointName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EndTimeOffset => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has FeaturesAttribute => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InferenceAttribute => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LocalPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ProbabilityAttribute => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ProbabilityThresholdAttribute => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3DataDistributionType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3InputMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has StartTimeOffset => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::ConstraintsResource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::ConstraintsResource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::ConstraintsResource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::ConstraintsResource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3Uri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::ClusterConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::ClusterConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::ClusterConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::ClusterConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InstanceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VolumeKmsKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VolumeSizeInGB => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::StoppingCondition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::StoppingCondition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::StoppingCondition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::StoppingCondition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxRuntimeInSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::NetworkConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::NetworkConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::NetworkConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::NetworkConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EnableInterContainerTrafficEncryption => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EnableNetworkIsolation => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VpcConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::VpcConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::MonitoringResources',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::MonitoringResources',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::MonitoringResources->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::MonitoringResources {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClusterConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::ClusterConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::MonitoringOutputConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::MonitoringOutputConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::MonitoringOutputConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::MonitoringOutputConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has KmsKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MonitoringOutputs => (isa => 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::MonitoringOutput', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::ModelBiasJobInput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::ModelBiasJobInput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::ModelBiasJobInput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::ModelBiasJobInput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EndpointInput => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::EndpointInput', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has GroundTruthS3Input => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::MonitoringGroundTruthS3Input', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::ModelBiasBaselineConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::ModelBiasBaselineConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::ModelBiasBaselineConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::ModelBiasBaselineConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BaseliningJobName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ConstraintsResource => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::ConstraintsResource', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::ModelBiasAppSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::ModelBiasAppSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::ModelBiasAppSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelBiasJobDefinition::ModelBiasAppSpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConfigUri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Environment => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::Environment', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ImageUri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has JobDefinitionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has JobResources => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::MonitoringResources', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ModelBiasAppSpecification => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::ModelBiasAppSpecification', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ModelBiasBaselineConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::ModelBiasBaselineConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ModelBiasJobInput => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::ModelBiasJobInput', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ModelBiasJobOutputConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::MonitoringOutputConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has NetworkConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::NetworkConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has StoppingCondition => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelBiasJobDefinition::StoppingCondition', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::SageMaker::ModelBiasJobDefinition - Cfn resource for AWS::SageMaker::ModelBiasJobDefinition

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::SageMaker::ModelBiasJobDefinition.

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
