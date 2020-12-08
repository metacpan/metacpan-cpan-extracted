# Alexa::ASK::Skill generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::Alexa::ASK::Skill',
  from 'HashRef',
   via { Cfn::Resource::Properties::Alexa::ASK::Skill->new( %$_ ) };

package Cfn::Resource::Alexa::ASK::Skill {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::Alexa::ASK::Skill', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
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
       return Cfn::Resource::Properties::Object::Alexa::ASK::Skill::Overrides->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::Alexa::ASK::Skill::Overrides {
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
       return Cfn::Resource::Properties::Object::Alexa::ASK::Skill::SkillPackage->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::Alexa::ASK::Skill::SkillPackage {
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
       return Cfn::Resource::Properties::Object::Alexa::ASK::Skill::AuthenticationConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::Alexa::ASK::Skill::AuthenticationConfiguration {
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
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::Alexa::ASK::Skill - Cfn resource for Alexa::ASK::Skill

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object Alexa::ASK::Skill.

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
