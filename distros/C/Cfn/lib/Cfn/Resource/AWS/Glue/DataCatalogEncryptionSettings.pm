# AWS::Glue::DataCatalogEncryptionSettings generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings->new( %$_ ) };

package Cfn::Resource::AWS::Glue::DataCatalogEncryptionSettings {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-northwest-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','us-east-1','us-east-2','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings::EncryptionAtRest',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings::EncryptionAtRest',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Glue::DataCatalogEncryptionSettings::EncryptionAtRest->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Glue::DataCatalogEncryptionSettings::EncryptionAtRest {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CatalogEncryptionMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SseAwsKmsKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings::ConnectionPasswordEncryption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings::ConnectionPasswordEncryption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Glue::DataCatalogEncryptionSettings::ConnectionPasswordEncryption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Glue::DataCatalogEncryptionSettings::ConnectionPasswordEncryption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has KmsKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ReturnConnectionPasswordEncrypted => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings::DataCatalogEncryptionSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings::DataCatalogEncryptionSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Glue::DataCatalogEncryptionSettings::DataCatalogEncryptionSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Glue::DataCatalogEncryptionSettings::DataCatalogEncryptionSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConnectionPasswordEncryption => (isa => 'Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings::ConnectionPasswordEncryption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EncryptionAtRest => (isa => 'Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings::EncryptionAtRest', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has CatalogId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DataCatalogEncryptionSettings => (isa => 'Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings::DataCatalogEncryptionSettings', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Glue::DataCatalogEncryptionSettings - Cfn resource for AWS::Glue::DataCatalogEncryptionSettings

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Glue::DataCatalogEncryptionSettings.

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
