# AWS::ApplicationAutoScaling::ScalableTarget generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalableTarget',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalableTarget->new( %$_ ) };

package Cfn::Resource::AWS::ApplicationAutoScaling::ScalableTarget {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalableTarget', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalableTarget::ScalableTargetAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalableTarget::ScalableTargetAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApplicationAutoScaling::ScalableTarget::ScalableTargetAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApplicationAutoScaling::ScalableTarget::ScalableTargetAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxCapacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinCapacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalableTarget::SuspendedState',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalableTarget::SuspendedState',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApplicationAutoScaling::ScalableTarget::SuspendedState->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApplicationAutoScaling::ScalableTarget::SuspendedState {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DynamicScalingInSuspended => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DynamicScalingOutSuspended => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScheduledScalingSuspended => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalableTarget::ScheduledAction',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalableTarget::ScheduledAction',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalableTarget::ScheduledAction')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalableTarget::ScheduledAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalableTarget::ScheduledAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApplicationAutoScaling::ScalableTarget::ScheduledAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApplicationAutoScaling::ScalableTarget::ScheduledAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EndTime => (isa => 'Cfn::Value::Timestamp', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScalableTargetAction => (isa => 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalableTarget::ScalableTargetAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Schedule => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScheduledActionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StartTime => (isa => 'Cfn::Value::Timestamp', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalableTarget {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has MaxCapacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinCapacity => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScalableDimension => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ScheduledActions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalableTarget::ScheduledAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceNamespace => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SuspendedState => (isa => 'Cfn::Resource::Properties::AWS::ApplicationAutoScaling::ScalableTarget::SuspendedState', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::ApplicationAutoScaling::ScalableTarget - Cfn resource for AWS::ApplicationAutoScaling::ScalableTarget

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::ApplicationAutoScaling::ScalableTarget.

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
