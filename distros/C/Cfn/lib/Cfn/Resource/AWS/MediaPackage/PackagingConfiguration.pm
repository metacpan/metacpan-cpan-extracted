# AWS::MediaPackage::PackagingConfiguration generated from spec 20.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration->new( %$_ ) };

package Cfn::Resource::AWS::MediaPackage::PackagingConfiguration {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::StreamSelection',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::StreamSelection',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::StreamSelection->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::StreamSelection {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MaxVideoBitsPerSecond => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinVideoBitsPerSecond => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StreamOrder => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::SpekeKeyProvider',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::SpekeKeyProvider',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::SpekeKeyProvider->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::SpekeKeyProvider {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SystemIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Url => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::MssManifest',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::MssManifest',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::MssManifest')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::MssManifest',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::MssManifest',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::MssManifest->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::MssManifest {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ManifestName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StreamSelection => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::StreamSelection', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::MssEncryption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::MssEncryption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::MssEncryption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::MssEncryption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SpekeKeyProvider => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::SpekeKeyProvider', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::HlsManifest',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::HlsManifest',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::HlsManifest')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::HlsManifest',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::HlsManifest',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::HlsManifest->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::HlsManifest {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AdMarkers => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeIframeOnlyStream => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ManifestName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProgramDateTimeIntervalSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RepeatExtXKey => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StreamSelection => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::StreamSelection', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::HlsEncryption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::HlsEncryption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::HlsEncryption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::HlsEncryption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConstantInitializationVector => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EncryptionMethod => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SpekeKeyProvider => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::SpekeKeyProvider', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::DashManifest',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::DashManifest',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::DashManifest')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::DashManifest',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::DashManifest',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::DashManifest->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::DashManifest {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ManifestLayout => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ManifestName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MinBufferTimeSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Profile => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StreamSelection => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::StreamSelection', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::DashEncryption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::DashEncryption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::DashEncryption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::DashEncryption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SpekeKeyProvider => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::SpekeKeyProvider', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::CmafEncryption',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::CmafEncryption',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::CmafEncryption->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::CmafEncryption {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SpekeKeyProvider => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::SpekeKeyProvider', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::MssPackage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::MssPackage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::MssPackage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::MssPackage {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Encryption => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::MssEncryption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MssManifests => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::MssManifest', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentDurationSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::HlsPackage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::HlsPackage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::HlsPackage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::HlsPackage {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Encryption => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::HlsEncryption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HlsManifests => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::HlsManifest', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentDurationSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UseAudioRenditionGroup => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::DashPackage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::DashPackage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::DashPackage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::DashPackage {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DashManifests => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::DashManifest', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Encryption => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::DashEncryption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PeriodTriggers => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentDurationSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentTemplateFormat => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::CmafPackage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::CmafPackage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::CmafPackage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingConfiguration::CmafPackage {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Encryption => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::CmafEncryption', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HlsManifests => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::HlsManifest', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SegmentDurationSeconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has CmafPackage => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::CmafPackage', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DashPackage => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::DashPackage', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HlsPackage => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::HlsPackage', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MssPackage => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingConfiguration::MssPackage', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PackagingGroupId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::MediaPackage::PackagingConfiguration - Cfn resource for AWS::MediaPackage::PackagingConfiguration

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::MediaPackage::PackagingConfiguration.

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
