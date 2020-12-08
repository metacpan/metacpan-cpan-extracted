# AWS::Lambda::CodeSigningConfig generated from spec 21.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Lambda::CodeSigningConfig',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Lambda::CodeSigningConfig->new( %$_ ) };

package Cfn::Resource::AWS::Lambda::CodeSigningConfig {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Lambda::CodeSigningConfig', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'CodeSigningConfigArn','CodeSigningConfigId' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Lambda::CodeSigningConfig::CodeSigningPolicies',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Lambda::CodeSigningConfig::CodeSigningPolicies',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Lambda::CodeSigningConfig::CodeSigningPolicies->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Lambda::CodeSigningConfig::CodeSigningPolicies {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has UntrustedArtifactOnDeployment => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Lambda::CodeSigningConfig::AllowedPublishers',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Lambda::CodeSigningConfig::AllowedPublishers',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Lambda::CodeSigningConfig::AllowedPublishers->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Lambda::CodeSigningConfig::AllowedPublishers {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SigningProfileVersionArns => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Lambda::CodeSigningConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AllowedPublishers => (isa => 'Cfn::Resource::Properties::AWS::Lambda::CodeSigningConfig::AllowedPublishers', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CodeSigningPolicies => (isa => 'Cfn::Resource::Properties::AWS::Lambda::CodeSigningConfig::CodeSigningPolicies', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Lambda::CodeSigningConfig - Cfn resource for AWS::Lambda::CodeSigningConfig

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Lambda::CodeSigningConfig.

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
