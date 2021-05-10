# AWS::Backup::BackupPlan generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Backup::BackupPlan',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Backup::BackupPlan->new( %$_ ) };

package Cfn::Resource::AWS::Backup::BackupPlan {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Backup::BackupPlan', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'BackupPlanArn','BackupPlanId','VersionId' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Backup::BackupPlan::LifecycleResourceType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Backup::BackupPlan::LifecycleResourceType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Backup::BackupPlan::LifecycleResourceType->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Backup::BackupPlan::LifecycleResourceType {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DeleteAfterDays => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MoveToColdStorageAfterDays => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Backup::BackupPlan::CopyActionResourceType',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Backup::BackupPlan::CopyActionResourceType',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Backup::BackupPlan::CopyActionResourceType')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Backup::BackupPlan::CopyActionResourceType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Backup::BackupPlan::CopyActionResourceType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Backup::BackupPlan::CopyActionResourceType->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Backup::BackupPlan::CopyActionResourceType {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DestinationBackupVaultArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Lifecycle => (isa => 'Cfn::Resource::Properties::AWS::Backup::BackupPlan::LifecycleResourceType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Backup::BackupPlan::BackupRuleResourceType',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Backup::BackupPlan::BackupRuleResourceType',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Backup::BackupPlan::BackupRuleResourceType')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Backup::BackupPlan::BackupRuleResourceType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Backup::BackupPlan::BackupRuleResourceType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Backup::BackupPlan::BackupRuleResourceType->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Backup::BackupPlan::BackupRuleResourceType {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CompletionWindowMinutes => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CopyActions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Backup::BackupPlan::CopyActionResourceType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EnableContinuousBackup => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Lifecycle => (isa => 'Cfn::Resource::Properties::AWS::Backup::BackupPlan::LifecycleResourceType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RecoveryPointTags => (isa => 'Cfn::Value::Hash|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RuleName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScheduleExpression => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StartWindowMinutes => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetBackupVault => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Backup::BackupPlan::AdvancedBackupSettingResourceType',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Backup::BackupPlan::AdvancedBackupSettingResourceType',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Backup::BackupPlan::AdvancedBackupSettingResourceType')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Backup::BackupPlan::AdvancedBackupSettingResourceType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Backup::BackupPlan::AdvancedBackupSettingResourceType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Backup::BackupPlan::AdvancedBackupSettingResourceType->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Backup::BackupPlan::AdvancedBackupSettingResourceType {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BackupOptions => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Backup::BackupPlan::BackupPlanResourceType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Backup::BackupPlan::BackupPlanResourceType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Backup::BackupPlan::BackupPlanResourceType->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Backup::BackupPlan::BackupPlanResourceType {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdvancedBackupSettings => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Backup::BackupPlan::AdvancedBackupSettingResourceType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BackupPlanName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BackupPlanRule => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Backup::BackupPlan::BackupRuleResourceType', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Backup::BackupPlan {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has BackupPlan => (isa => 'Cfn::Resource::Properties::AWS::Backup::BackupPlan::BackupPlanResourceType', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BackupPlanTags => (isa => 'Cfn::Value::Hash|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Backup::BackupPlan - Cfn resource for AWS::Backup::BackupPlan

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Backup::BackupPlan.

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
