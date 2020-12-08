# AWS::S3::StorageLens generated from spec 21.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::S3::StorageLens',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::S3::StorageLens->new( %$_ ) };

package Cfn::Resource::AWS::S3::StorageLens {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::S3::StorageLens', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'StorageLensArn' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::S3::StorageLens::SelectionCriteria',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3::StorageLens::SelectionCriteria',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3::StorageLens::SelectionCriteria->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3::StorageLens::SelectionCriteria {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Delimiter => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MaxDepth => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinStorageBytesPercentage => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::S3::StorageLens::PrefixLevelStorageMetrics',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3::StorageLens::PrefixLevelStorageMetrics',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3::StorageLens::PrefixLevelStorageMetrics->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3::StorageLens::PrefixLevelStorageMetrics {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IsEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SelectionCriteria => (isa => 'Cfn::Resource::Properties::AWS::S3::StorageLens::SelectionCriteria', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::S3::StorageLens::PrefixLevel',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3::StorageLens::PrefixLevel',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3::StorageLens::PrefixLevel->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3::StorageLens::PrefixLevel {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has StorageMetrics => (isa => 'Cfn::Resource::Properties::AWS::S3::StorageLens::PrefixLevelStorageMetrics', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::S3::StorageLens::Encryption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3::StorageLens::Encryption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3::StorageLens::Encryption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3::StorageLens::Encryption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

subtype 'Cfn::Resource::Properties::AWS::S3::StorageLens::ActivityMetrics',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3::StorageLens::ActivityMetrics',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3::StorageLens::ActivityMetrics->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3::StorageLens::ActivityMetrics {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IsEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::S3::StorageLens::S3BucketDestination',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3::StorageLens::S3BucketDestination',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3::StorageLens::S3BucketDestination->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3::StorageLens::S3BucketDestination {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccountId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Encryption => (isa => 'Cfn::Resource::Properties::AWS::S3::StorageLens::Encryption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Format => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OutputSchemaVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Prefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::S3::StorageLens::BucketLevel',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3::StorageLens::BucketLevel',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3::StorageLens::BucketLevel->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3::StorageLens::BucketLevel {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ActivityMetrics => (isa => 'Cfn::Resource::Properties::AWS::S3::StorageLens::ActivityMetrics', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PrefixLevel => (isa => 'Cfn::Resource::Properties::AWS::S3::StorageLens::PrefixLevel', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::S3::StorageLens::DataExport',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3::StorageLens::DataExport',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3::StorageLens::DataExport->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3::StorageLens::DataExport {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3BucketDestination => (isa => 'Cfn::Resource::Properties::AWS::S3::StorageLens::S3BucketDestination', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::S3::StorageLens::BucketsAndRegions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3::StorageLens::BucketsAndRegions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3::StorageLens::BucketsAndRegions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3::StorageLens::BucketsAndRegions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Buckets => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Regions => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::S3::StorageLens::AwsOrg',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3::StorageLens::AwsOrg',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3::StorageLens::AwsOrg->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3::StorageLens::AwsOrg {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::S3::StorageLens::AccountLevel',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3::StorageLens::AccountLevel',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3::StorageLens::AccountLevel->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3::StorageLens::AccountLevel {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ActivityMetrics => (isa => 'Cfn::Resource::Properties::AWS::S3::StorageLens::ActivityMetrics', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BucketLevel => (isa => 'Cfn::Resource::Properties::AWS::S3::StorageLens::BucketLevel', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::S3::StorageLens::StorageLensConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::S3::StorageLens::StorageLensConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::S3::StorageLens::StorageLensConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::S3::StorageLens::StorageLensConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccountLevel => (isa => 'Cfn::Resource::Properties::AWS::S3::StorageLens::AccountLevel', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AwsOrg => (isa => 'Cfn::Resource::Properties::AWS::S3::StorageLens::AwsOrg', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataExport => (isa => 'Cfn::Resource::Properties::AWS::S3::StorageLens::DataExport', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Exclude => (isa => 'Cfn::Resource::Properties::AWS::S3::StorageLens::BucketsAndRegions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Include => (isa => 'Cfn::Resource::Properties::AWS::S3::StorageLens::BucketsAndRegions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IsEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StorageLensArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::S3::StorageLens {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has StorageLensConfiguration => (isa => 'Cfn::Resource::Properties::AWS::S3::StorageLens::StorageLensConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::S3::StorageLens - Cfn resource for AWS::S3::StorageLens

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::S3::StorageLens.

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
