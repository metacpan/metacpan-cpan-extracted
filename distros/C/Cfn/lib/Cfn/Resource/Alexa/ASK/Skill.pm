# Alexa::ASK::Skill generated from spec 2.22.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::Alexa::ASK::Skill',
  from 'HashRef',
   via { Cfn::Resource::Properties::Alexa::ASK::Skill->new( %$_ ) };

package Cfn::Resource::Alexa::ASK::Skill {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::Alexa::ASK::Skill', is => 'rw', coerce => 1);
  sub _build_attributes {
    [  ]
  }
}



subtype 'Cfn::Resource::Properties::Alexa::ASK::Skill::Overrides',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::Alexa::ASK::Skill::Overrides',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Alexa::ASK::Skill::OverridesValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Alexa::ASK::Skill::OverridesValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Manifest => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::Alexa::ASK::Skill::SkillPackage',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::Alexa::ASK::Skill::SkillPackage',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Alexa::ASK::Skill::SkillPackageValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Alexa::ASK::Skill::SkillPackageValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Overrides => (isa => 'Cfn::Resource::Properties::Alexa::ASK::Skill::Overrides', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3Bucket => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3BucketRole => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3ObjectVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::Alexa::ASK::Skill::AuthenticationConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::Alexa::ASK::Skill::AuthenticationConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Alexa::ASK::Skill::AuthenticationConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Alexa::ASK::Skill::AuthenticationConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClientId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientSecret => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RefreshToken => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::Alexa::ASK::Skill {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AuthenticationConfiguration => (isa => 'Cfn::Resource::Properties::Alexa::ASK::Skill::AuthenticationConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SkillPackage => (isa => 'Cfn::Resource::Properties::Alexa::ASK::Skill::SkillPackage', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VendorId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
