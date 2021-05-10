# AWS::SageMaker::ModelExplainabilityJobDefinition generated from spec 22.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition->new( %$_ ) };

package Cfn::Resource::AWS::SageMaker::ModelExplainabilityJobDefinition {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'CreationTime','JobDefinitionArn' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::S3Output',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::S3Output',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::S3Output->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::S3Output {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LocalPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3UploadMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3Uri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::VpcConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::VpcConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::VpcConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::VpcConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SecurityGroupIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Subnets => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringOutput',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringOutput',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringOutput')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringOutput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringOutput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringOutput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringOutput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3Output => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::S3Output', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::Environment',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::Environment',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::Environment->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::Environment {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::EndpointInput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::EndpointInput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::EndpointInput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::EndpointInput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EndpointName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has FeaturesAttribute => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InferenceAttribute => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LocalPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ProbabilityAttribute => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3DataDistributionType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has S3InputMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::ConstraintsResource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::ConstraintsResource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::ConstraintsResource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::ConstraintsResource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3Uri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::ClusterConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::ClusterConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::ClusterConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::ClusterConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InstanceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VolumeKmsKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VolumeSizeInGB => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::StoppingCondition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::StoppingCondition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::StoppingCondition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::StoppingCondition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxRuntimeInSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::NetworkConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::NetworkConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::NetworkConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::NetworkConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EnableInterContainerTrafficEncryption => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EnableNetworkIsolation => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VpcConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::VpcConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringResources',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringResources',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringResources->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringResources {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClusterConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::ClusterConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringOutputConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringOutputConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringOutputConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringOutputConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has KmsKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MonitoringOutputs => (isa => 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringOutput', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::ModelExplainabilityJobInput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::ModelExplainabilityJobInput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::ModelExplainabilityJobInput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::ModelExplainabilityJobInput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EndpointInput => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::EndpointInput', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::ModelExplainabilityBaselineConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::ModelExplainabilityBaselineConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::ModelExplainabilityBaselineConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::ModelExplainabilityBaselineConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BaseliningJobName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ConstraintsResource => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::ConstraintsResource', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::ModelExplainabilityAppSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::ModelExplainabilityAppSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::ModelExplainabilityAppSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::ModelExplainabilityJobDefinition::ModelExplainabilityAppSpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConfigUri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Environment => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::Environment', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ImageUri => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has JobDefinitionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has JobResources => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringResources', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ModelExplainabilityAppSpecification => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::ModelExplainabilityAppSpecification', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ModelExplainabilityBaselineConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::ModelExplainabilityBaselineConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ModelExplainabilityJobInput => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::ModelExplainabilityJobInput', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ModelExplainabilityJobOutputConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::MonitoringOutputConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has NetworkConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::NetworkConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has StoppingCondition => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::ModelExplainabilityJobDefinition::StoppingCondition', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::SageMaker::ModelExplainabilityJobDefinition - Cfn resource for AWS::SageMaker::ModelExplainabilityJobDefinition

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::SageMaker::ModelExplainabilityJobDefinition.

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
