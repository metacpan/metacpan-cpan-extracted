# AWS::GreengrassV2::ComponentVersion generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion->new( %$_ ) };

package Cfn::Resource::AWS::GreengrassV2::ComponentVersion {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','ComponentName','ComponentVersion' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaVolumeMount',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaVolumeMount',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaVolumeMount')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaVolumeMount',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaVolumeMount',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::LambdaVolumeMount->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::LambdaVolumeMount {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AddGroupOwner => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DestinationPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Permission => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SourcePath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaDeviceMount',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaDeviceMount',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaDeviceMount')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaDeviceMount',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaDeviceMount',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::LambdaDeviceMount->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::LambdaDeviceMount {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AddGroupOwner => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Path => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Permission => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaContainerParams',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaContainerParams',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::LambdaContainerParams->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::LambdaContainerParams {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Devices => (isa => 'ArrayOfCfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaDeviceMount', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MemorySizeInKB => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MountROSysfs => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Volumes => (isa => 'ArrayOfCfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaVolumeMount', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaLinuxProcessParams',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaLinuxProcessParams',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::LambdaLinuxProcessParams->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::LambdaLinuxProcessParams {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ContainerParams => (isa => 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaContainerParams', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has IsolationMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaEventSource',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaEventSource',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaEventSource')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaEventSource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaEventSource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::LambdaEventSource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::LambdaEventSource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Topic => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaExecutionParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaExecutionParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::LambdaExecutionParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::LambdaExecutionParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EnvironmentVariables => (isa => 'Cfn::Value::Hash|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EventSources => (isa => 'ArrayOfCfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaEventSource', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ExecArgs => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InputPayloadEncodingType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LinuxProcessParams => (isa => 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaLinuxProcessParams', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MaxIdleTimeInSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MaxInstancesCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has MaxQueueSize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Pinned => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has StatusTimeoutInSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has TimeoutInSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::ComponentPlatform',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::ComponentPlatform',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::ComponentPlatform')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::ComponentPlatform',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::ComponentPlatform',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::ComponentPlatform->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::ComponentPlatform {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Attributes => (isa => 'Cfn::Value::Hash|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'MapOfCfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::ComponentDependencyRequirement',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Hash') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'MapOfCfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::ComponentDependencyRequirement',
  from 'HashRef',
   via {
     my $arg = $_;
     if (my $f = Cfn::TypeLibrary::try_function($arg)) {
       return $f
     } else {
       Cfn::Value::Hash->new(Value => {
         map { $_ => Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::ComponentDependencyRequirement')->coerce($arg->{$_}) } keys %$arg
       });
     }
   };

subtype 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::ComponentDependencyRequirement',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::ComponentDependencyRequirement',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::ComponentDependencyRequirement->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::ComponentDependencyRequirement {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DependencyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VersionRequirement => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaFunctionRecipeSource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaFunctionRecipeSource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::LambdaFunctionRecipeSource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GreengrassV2::ComponentVersion::LambdaFunctionRecipeSource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ComponentDependencies => (isa => 'MapOfCfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::ComponentDependencyRequirement', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ComponentLambdaParameters => (isa => 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaExecutionParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ComponentName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ComponentPlatforms => (isa => 'ArrayOfCfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::ComponentPlatform', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ComponentVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LambdaArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has InlineRecipe => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LambdaFunction => (isa => 'Cfn::Resource::Properties::AWS::GreengrassV2::ComponentVersion::LambdaFunctionRecipeSource', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'Cfn::Value::Hash|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::GreengrassV2::ComponentVersion - Cfn resource for AWS::GreengrassV2::ComponentVersion

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::GreengrassV2::ComponentVersion.

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
