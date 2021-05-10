# AWS::ECS::CapacityProvider generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ECS::CapacityProvider',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ECS::CapacityProvider->new( %$_ ) };

package Cfn::Resource::AWS::ECS::CapacityProvider {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ECS::CapacityProvider', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::ECS::CapacityProvider::ManagedScaling',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ECS::CapacityProvider::ManagedScaling',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ECS::CapacityProvider::ManagedScaling->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ECS::CapacityProvider::ManagedScaling {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaximumScalingStepSize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinimumScalingStepSize => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Status => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetCapacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ECS::CapacityProvider::AutoScalingGroupProvider',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ECS::CapacityProvider::AutoScalingGroupProvider',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ECS::CapacityProvider::AutoScalingGroupProvider->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ECS::CapacityProvider::AutoScalingGroupProvider {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AutoScalingGroupArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ManagedScaling => (isa => 'Cfn::Resource::Properties::AWS::ECS::CapacityProvider::ManagedScaling', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ManagedTerminationProtection => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::ECS::CapacityProvider {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AutoScalingGroupProvider => (isa => 'Cfn::Resource::Properties::AWS::ECS::CapacityProvider::AutoScalingGroupProvider', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::ECS::CapacityProvider - Cfn resource for AWS::ECS::CapacityProvider

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::ECS::CapacityProvider.

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
