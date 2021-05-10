# AWS::SageMaker::DataQualityJobDefinition generated from spec 22.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition->new( %$_ ) };

package Cfn::Resource::AWS::SageMaker::DataQualityJobDefinition {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'CreationTime','JobDefinitionArn' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::S3Output',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::S3Output',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::S3Output->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::S3Output {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LocalPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3UploadMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3Uri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::VpcConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::VpcConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::VpcConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::VpcConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SecurityGroupIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Subnets => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::StatisticsResource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::StatisticsResource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::StatisticsResource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::StatisticsResource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3Uri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::MonitoringOutput',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::MonitoringOutput',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::MonitoringOutput')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::MonitoringOutput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::MonitoringOutput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::MonitoringOutput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::MonitoringOutput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3Output => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::S3Output', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::Environment',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::Environment',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::Environment->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::Environment {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::EndpointInput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::EndpointInput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::EndpointInput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::EndpointInput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EndpointName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LocalPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3DataDistributionType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3InputMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::ConstraintsResource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::ConstraintsResource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::ConstraintsResource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::ConstraintsResource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3Uri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::ClusterConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::ClusterConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::ClusterConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::ClusterConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InstanceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VolumeKmsKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VolumeSizeInGB => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::StoppingCondition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::StoppingCondition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::StoppingCondition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::StoppingCondition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxRuntimeInSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::NetworkConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::NetworkConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::NetworkConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::NetworkConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EnableInterContainerTrafficEncryption => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EnableNetworkIsolation => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VpcConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::VpcConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::MonitoringResources',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::MonitoringResources',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::MonitoringResources->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::MonitoringResources {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClusterConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::ClusterConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::MonitoringOutputConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::MonitoringOutputConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::MonitoringOutputConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::MonitoringOutputConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has KmsKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MonitoringOutputs => (isa => 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::MonitoringOutput', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::DataQualityJobInput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::DataQualityJobInput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::DataQualityJobInput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::DataQualityJobInput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EndpointInput => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::EndpointInput', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::DataQualityBaselineConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::DataQualityBaselineConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::DataQualityBaselineConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::DataQualityBaselineConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BaseliningJobName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ConstraintsResource => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::ConstraintsResource', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has StatisticsResource => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::StatisticsResource', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::DataQualityAppSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::DataQualityAppSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::DataQualityAppSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::DataQualityJobDefinition::DataQualityAppSpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ContainerArguments => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ContainerEntrypoint => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Environment => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::Environment', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ImageUri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has PostAnalyticsProcessorSourceUri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RecordPreprocessorSourceUri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DataQualityAppSpecification => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::DataQualityAppSpecification', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DataQualityBaselineConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::DataQualityBaselineConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DataQualityJobInput => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::DataQualityJobInput', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DataQualityJobOutputConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::MonitoringOutputConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has JobDefinitionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has JobResources => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::MonitoringResources', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has NetworkConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::NetworkConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has StoppingCondition => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::DataQualityJobDefinition::StoppingCondition', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::SageMaker::DataQualityJobDefinition - Cfn resource for AWS::SageMaker::DataQualityJobDefinition

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::SageMaker::DataQualityJobDefinition.

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
