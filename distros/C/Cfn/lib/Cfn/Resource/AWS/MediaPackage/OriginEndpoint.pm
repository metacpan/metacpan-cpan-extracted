# AWS::MediaPackage::OriginEndpoint generated from spec 20.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint->new( %$_ ) };

package Cfn::Resource::AWS::MediaPackage::OriginEndpoint {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Url' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::SpekeKeyProvider',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::SpekeKeyProvider',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::SpekeKeyProvider->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::SpekeKeyProvider {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CertificateArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SystemIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Url => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::StreamSelection',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::StreamSelection',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::StreamSelection->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::StreamSelection {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxVideoBitsPerSecond => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinVideoBitsPerSecond => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StreamOrder => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::MssEncryption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::MssEncryption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::MssEncryption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::MssEncryption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SpekeKeyProvider => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::SpekeKeyProvider', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::HlsManifest',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::HlsManifest',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::HlsManifest')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::HlsManifest',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::HlsManifest',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::HlsManifest->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::HlsManifest {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdMarkers => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AdsOnDeliveryRestrictions => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AdTriggers => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeIframeOnlyStream => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ManifestName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PlaylistType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PlaylistWindowSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProgramDateTimeIntervalSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Url => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::HlsEncryption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::HlsEncryption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::HlsEncryption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::HlsEncryption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConstantInitializationVector => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EncryptionMethod => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KeyRotationIntervalSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RepeatExtXKey => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SpekeKeyProvider => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::SpekeKeyProvider', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::DashEncryption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::DashEncryption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::DashEncryption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::DashEncryption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has KeyRotationIntervalSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SpekeKeyProvider => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::SpekeKeyProvider', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::CmafEncryption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::CmafEncryption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::CmafEncryption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::CmafEncryption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has KeyRotationIntervalSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SpekeKeyProvider => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::SpekeKeyProvider', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::MssPackage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::MssPackage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::MssPackage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::MssPackage {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Encryption => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::MssEncryption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ManifestWindowSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentDurationSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StreamSelection => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::StreamSelection', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::HlsPackage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::HlsPackage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::HlsPackage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::HlsPackage {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdMarkers => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AdsOnDeliveryRestrictions => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AdTriggers => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Encryption => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::HlsEncryption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeIframeOnlyStream => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PlaylistType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PlaylistWindowSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProgramDateTimeIntervalSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentDurationSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StreamSelection => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::StreamSelection', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UseAudioRenditionGroup => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::DashPackage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::DashPackage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::DashPackage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::DashPackage {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdsOnDeliveryRestrictions => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AdTriggers => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Encryption => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::DashEncryption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ManifestLayout => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ManifestWindowSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinBufferTimeSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinUpdatePeriodSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PeriodTriggers => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Profile => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentDurationSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentTemplateFormat => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StreamSelection => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::StreamSelection', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SuggestedPresentationDelaySeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::CmafPackage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::CmafPackage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::CmafPackage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::CmafPackage {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Encryption => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::CmafEncryption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HlsManifests => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::HlsManifest', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentDurationSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentPrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StreamSelection => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::StreamSelection', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::Authorization',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::Authorization',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::Authorization->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::OriginEndpoint::Authorization {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CdnIdentifierSecret => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecretsRoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Authorization => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::Authorization', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ChannelId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CmafPackage => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::CmafPackage', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DashPackage => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::DashPackage', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HlsPackage => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::HlsPackage', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ManifestName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MssPackage => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::OriginEndpoint::MssPackage', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Origination => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StartoverWindowSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimeDelaySeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Whitelist => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::MediaPackage::OriginEndpoint - Cfn resource for AWS::MediaPackage::OriginEndpoint

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::MediaPackage::OriginEndpoint.

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
