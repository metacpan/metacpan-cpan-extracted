# AWS::CloudFront::OriginRequestPolicy generated from spec 20.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CloudFront::OriginRequestPolicy',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CloudFront::OriginRequestPolicy->new( %$_ ) };

package Cfn::Resource::AWS::CloudFront::OriginRequestPolicy {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CloudFront::OriginRequestPolicy', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Id','LastModifiedTime' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::CloudFront::OriginRequestPolicy::QueryStringsConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CloudFront::OriginRequestPolicy::QueryStringsConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::CloudFront::OriginRequestPolicy::QueryStringsConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::CloudFront::OriginRequestPolicy::QueryStringsConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has QueryStringBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has QueryStrings => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::CloudFront::OriginRequestPolicy::HeadersConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CloudFront::OriginRequestPolicy::HeadersConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::CloudFront::OriginRequestPolicy::HeadersConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::CloudFront::OriginRequestPolicy::HeadersConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HeaderBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Headers => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::CloudFront::OriginRequestPolicy::CookiesConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CloudFront::OriginRequestPolicy::CookiesConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::CloudFront::OriginRequestPolicy::CookiesConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::CloudFront::OriginRequestPolicy::CookiesConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CookieBehavior => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Cookies => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::CloudFront::OriginRequestPolicy::OriginRequestPolicyConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CloudFront::OriginRequestPolicy::OriginRequestPolicyConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::CloudFront::OriginRequestPolicy::OriginRequestPolicyConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::CloudFront::OriginRequestPolicy::OriginRequestPolicyConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Comment => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CookiesConfig => (isa => 'Cfn::Resource::Properties::AWS::CloudFront::OriginRequestPolicy::CookiesConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HeadersConfig => (isa => 'Cfn::Resource::Properties::AWS::CloudFront::OriginRequestPolicy::HeadersConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has QueryStringsConfig => (isa => 'Cfn::Resource::Properties::AWS::CloudFront::OriginRequestPolicy::QueryStringsConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::CloudFront::OriginRequestPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has OriginRequestPolicyConfig => (isa => 'Cfn::Resource::Properties::AWS::CloudFront::OriginRequestPolicy::OriginRequestPolicyConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::CloudFront::OriginRequestPolicy - Cfn resource for AWS::CloudFront::OriginRequestPolicy

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::CloudFront::OriginRequestPolicy.

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
