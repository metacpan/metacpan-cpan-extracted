# AWS::ElastiCache::GlobalReplicationGroup generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup->new( %$_ ) };

package Cfn::Resource::AWS::ElastiCache::GlobalReplicationGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'GlobalReplicationGroupId','Status' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::ReshardingConfiguration',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::ReshardingConfiguration',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::ReshardingConfiguration')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::ReshardingConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::ReshardingConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElastiCache::GlobalReplicationGroup::ReshardingConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElastiCache::GlobalReplicationGroup::ReshardingConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has NodeGroupId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PreferredAvailabilityZones => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::RegionalConfiguration',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::RegionalConfiguration',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::RegionalConfiguration')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::RegionalConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::RegionalConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElastiCache::GlobalReplicationGroup::RegionalConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElastiCache::GlobalReplicationGroup::RegionalConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ReplicationGroupId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ReplicationGroupRegion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ReshardingConfigurations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::ReshardingConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::GlobalReplicationGroupMember',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::GlobalReplicationGroupMember',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::GlobalReplicationGroupMember')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::GlobalReplicationGroupMember',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::GlobalReplicationGroupMember',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElastiCache::GlobalReplicationGroup::GlobalReplicationGroupMember->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElastiCache::GlobalReplicationGroup::GlobalReplicationGroupMember {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ReplicationGroupId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ReplicationGroupRegion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Role => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AutomaticFailoverEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CacheNodeType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CacheParameterGroupName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EngineVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GlobalNodeGroupCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GlobalReplicationGroupDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GlobalReplicationGroupIdSuffix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Members => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::GlobalReplicationGroupMember', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RegionalConfigurations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ElastiCache::GlobalReplicationGroup::RegionalConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::ElastiCache::GlobalReplicationGroup - Cfn resource for AWS::ElastiCache::GlobalReplicationGroup

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::ElastiCache::GlobalReplicationGroup.

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
