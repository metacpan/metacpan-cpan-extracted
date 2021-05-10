# AWS::GameLift::GameServerGroup generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::GameLift::GameServerGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::GameLift::GameServerGroup->new( %$_ ) };

package Cfn::Resource::AWS::GameLift::GameServerGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::GameLift::GameServerGroup', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'AutoScalingGroupArn','GameServerGroupArn' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','eu-central-1','eu-west-1','eu-west-2','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::GameLift::GameServerGroup::TargetTrackingConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GameLift::GameServerGroup::TargetTrackingConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GameLift::GameServerGroup::TargetTrackingConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GameLift::GameServerGroup::TargetTrackingConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TargetValue => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GameLift::GameServerGroup::LaunchTemplate',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GameLift::GameServerGroup::LaunchTemplate',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GameLift::GameServerGroup::LaunchTemplate->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GameLift::GameServerGroup::LaunchTemplate {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LaunchTemplateId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LaunchTemplateName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Version => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::GameLift::GameServerGroup::InstanceDefinition',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::GameLift::GameServerGroup::InstanceDefinition',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::GameLift::GameServerGroup::InstanceDefinition')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::GameLift::GameServerGroup::InstanceDefinition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GameLift::GameServerGroup::InstanceDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GameLift::GameServerGroup::InstanceDefinition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GameLift::GameServerGroup::InstanceDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstanceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WeightedCapacity => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GameLift::GameServerGroup::AutoScalingPolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GameLift::GameServerGroup::AutoScalingPolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GameLift::GameServerGroup::AutoScalingPolicy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GameLift::GameServerGroup::AutoScalingPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EstimatedInstanceWarmup => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetTrackingConfiguration => (isa => 'Cfn::Resource::Properties::AWS::GameLift::GameServerGroup::TargetTrackingConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::GameLift::GameServerGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AutoScalingPolicy => (isa => 'Cfn::Resource::Properties::AWS::GameLift::GameServerGroup::AutoScalingPolicy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BalancingStrategy => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeleteOption => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GameServerGroupName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GameServerProtectionPolicy => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InstanceDefinitions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::GameLift::GameServerGroup::InstanceDefinition', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LaunchTemplate => (isa => 'Cfn::Resource::Properties::AWS::GameLift::GameServerGroup::LaunchTemplate', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxSize => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinSize => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpcSubnets => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::GameLift::GameServerGroup - Cfn resource for AWS::GameLift::GameServerGroup

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::GameLift::GameServerGroup.

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
