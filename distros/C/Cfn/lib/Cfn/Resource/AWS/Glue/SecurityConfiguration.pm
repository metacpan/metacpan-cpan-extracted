# AWS::Glue::SecurityConfiguration generated from spec 3.2.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration->new( %$_ ) };

package Cfn::Resource::AWS::Glue::SecurityConfiguration {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','eu-west-3','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::S3Encryptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::S3Encryptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::S3EncryptionsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::S3EncryptionsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::JobBookmarksEncryption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::JobBookmarksEncryption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::JobBookmarksEncryptionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::JobBookmarksEncryptionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has JobBookmarksEncryptionMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KmsKeyArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::CloudWatchEncryption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::CloudWatchEncryption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::CloudWatchEncryptionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::CloudWatchEncryptionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudWatchEncryptionMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KmsKeyArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::S3Encryption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::S3Encryption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::S3EncryptionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::S3EncryptionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has KmsKeyArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3EncryptionMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::EncryptionConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::EncryptionConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::EncryptionConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::EncryptionConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudWatchEncryption => (isa => 'Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::CloudWatchEncryption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has JobBookmarksEncryption => (isa => 'Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::JobBookmarksEncryption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3Encryptions => (isa => 'Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::S3Encryptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has EncryptionConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Glue::SecurityConfiguration::EncryptionConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
