# AWS::Athena::WorkGroup generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Athena::WorkGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Athena::WorkGroup->new( %$_ ) };

package Cfn::Resource::AWS::Athena::WorkGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Athena::WorkGroup', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'CreationTime','EffectiveEngineVersion' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::EncryptionConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::EncryptionConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Athena::WorkGroup::EncryptionConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Athena::WorkGroup::EncryptionConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EncryptionOption => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KmsKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::ResultConfigurationUpdates',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::ResultConfigurationUpdates',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Athena::WorkGroup::ResultConfigurationUpdates->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Athena::WorkGroup::ResultConfigurationUpdates {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EncryptionConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::EncryptionConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutputLocation => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RemoveEncryptionConfiguration => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RemoveOutputLocation => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::ResultConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::ResultConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Athena::WorkGroup::ResultConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Athena::WorkGroup::ResultConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EncryptionConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::EncryptionConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutputLocation => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::EngineVersion',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::EngineVersion',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Athena::WorkGroup::EngineVersion->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Athena::WorkGroup::EngineVersion {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EffectiveEngineVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SelectedEngineVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::WorkGroupConfigurationUpdates',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::WorkGroupConfigurationUpdates',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Athena::WorkGroup::WorkGroupConfigurationUpdates->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Athena::WorkGroup::WorkGroupConfigurationUpdates {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BytesScannedCutoffPerQuery => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EnforceWorkGroupConfiguration => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EngineVersion => (isa => 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::EngineVersion', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PublishCloudWatchMetricsEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RemoveBytesScannedCutoffPerQuery => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RequesterPaysEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResultConfigurationUpdates => (isa => 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::ResultConfigurationUpdates', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::WorkGroupConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::WorkGroupConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Athena::WorkGroup::WorkGroupConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Athena::WorkGroup::WorkGroupConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BytesScannedCutoffPerQuery => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EnforceWorkGroupConfiguration => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EngineVersion => (isa => 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::EngineVersion', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PublishCloudWatchMetricsEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RequesterPaysEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResultConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::ResultConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Athena::WorkGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RecursiveDeleteOption => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has State => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WorkGroupConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::WorkGroupConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WorkGroupConfigurationUpdates => (isa => 'Cfn::Resource::Properties::AWS::Athena::WorkGroup::WorkGroupConfigurationUpdates', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Athena::WorkGroup - Cfn resource for AWS::Athena::WorkGroup

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Athena::WorkGroup.

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
