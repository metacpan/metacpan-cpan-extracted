# AWS::Glue::SecurityConfiguration generated from spec 18.4.0
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
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-northwest-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','us-east-1','us-east-2','us-west-1','us-west-2' ]
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
       return Cfn::Resource::Properties::Object::AWS::Glue::SecurityConfiguration::S3Encryptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Glue::SecurityConfiguration::S3Encryptions {
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
       return Cfn::Resource::Properties::Object::AWS::Glue::SecurityConfiguration::JobBookmarksEncryption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Glue::SecurityConfiguration::JobBookmarksEncryption {
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
       return Cfn::Resource::Properties::Object::AWS::Glue::SecurityConfiguration::CloudWatchEncryption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Glue::SecurityConfiguration::CloudWatchEncryption {
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
       return Cfn::Resource::Properties::Object::AWS::Glue::SecurityConfiguration::S3Encryption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Glue::SecurityConfiguration::S3Encryption {
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
       return Cfn::Resource::Properties::Object::AWS::Glue::SecurityConfiguration::EncryptionConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Glue::SecurityConfiguration::EncryptionConfiguration {
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
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Glue::SecurityConfiguration - Cfn resource for AWS::Glue::SecurityConfiguration

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Glue::SecurityConfiguration.

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
