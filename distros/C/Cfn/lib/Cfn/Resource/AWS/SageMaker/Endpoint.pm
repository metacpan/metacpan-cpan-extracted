# AWS::SageMaker::Endpoint generated from spec 22.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SageMaker::Endpoint->new( %$_ ) };

package Cfn::Resource::AWS::SageMaker::Endpoint {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'EndpointName' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::CapacitySize',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::CapacitySize',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::Endpoint::CapacitySize->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::Endpoint::CapacitySize {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::TrafficRoutingConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::TrafficRoutingConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::Endpoint::TrafficRoutingConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::Endpoint::TrafficRoutingConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CanarySize => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::CapacitySize', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WaitIntervalInSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::Endpoint::Alarm',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::Endpoint::Alarm',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::SageMaker::Endpoint::Alarm')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::Alarm',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::Alarm',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::Endpoint::Alarm->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::Endpoint::Alarm {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AlarmName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::BlueGreenUpdatePolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::BlueGreenUpdatePolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::Endpoint::BlueGreenUpdatePolicy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::Endpoint::BlueGreenUpdatePolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaximumExecutionTimeoutInSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TerminationWaitInSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TrafficRoutingConfiguration => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::TrafficRoutingConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::AutoRollbackConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::AutoRollbackConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::Endpoint::AutoRollbackConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::Endpoint::AutoRollbackConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Alarms => (isa => 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::Endpoint::Alarm', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::Endpoint::VariantProperty',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::Endpoint::VariantProperty',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::SageMaker::Endpoint::VariantProperty')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::VariantProperty',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::VariantProperty',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::Endpoint::VariantProperty->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::Endpoint::VariantProperty {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VariantPropertyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::DeploymentConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::DeploymentConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SageMaker::Endpoint::DeploymentConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SageMaker::Endpoint::DeploymentConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AutoRollbackConfiguration => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::AutoRollbackConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BlueGreenUpdatePolicy => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::BlueGreenUpdatePolicy', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::SageMaker::Endpoint {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DeploymentConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::Endpoint::DeploymentConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EndpointConfigName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EndpointName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ExcludeRetainedVariantProperties => (isa => 'ArrayOfCfn::Resource::Properties::AWS::SageMaker::Endpoint::VariantProperty', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RetainAllVariantProperties => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::SageMaker::Endpoint - Cfn resource for AWS::SageMaker::Endpoint

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::SageMaker::Endpoint.

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
