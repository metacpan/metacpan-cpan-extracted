# AWS::Glue::DataCatalogEncryptionSettings generated from spec 3.2.0
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
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','eu-west-3','us-east-1','us-east-2','us-west-1','us-west-2' ]
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
       return Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings::EncryptionAtRestValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings::EncryptionAtRestValue {
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
       return Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings::ConnectionPasswordEncryptionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings::ConnectionPasswordEncryptionValue {
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
       return Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings::DataCatalogEncryptionSettingsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Glue::DataCatalogEncryptionSettings::DataCatalogEncryptionSettingsValue {
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
