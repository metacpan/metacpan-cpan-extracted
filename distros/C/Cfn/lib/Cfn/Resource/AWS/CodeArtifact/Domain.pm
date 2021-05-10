# AWS::CodeArtifact::Domain generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CodeArtifact::Domain',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CodeArtifact::Domain->new( %$_ ) };

package Cfn::Resource::AWS::CodeArtifact::Domain {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CodeArtifact::Domain', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','EncryptionKey','Name','Owner' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-south-1','ap-southeast-1','ap-southeast-2','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','us-east-1','us-east-2','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::CodeArtifact::Domain {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DomainName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EncryptionKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has PermissionsPolicyDocument => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::CodeArtifact::Domain - Cfn resource for AWS::CodeArtifact::Domain

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::CodeArtifact::Domain.

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
