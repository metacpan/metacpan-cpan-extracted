# AWS::CustomerProfiles::Domain generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CustomerProfiles::Domain',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CustomerProfiles::Domain->new( %$_ ) };

package Cfn::Resource::AWS::CustomerProfiles::Domain {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CustomerProfiles::Domain', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'CreatedAt','LastUpdatedAt' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-1','ap-southeast-2','eu-central-1','eu-west-2','us-east-1','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::CustomerProfiles::Domain {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DeadLetterQueueUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DefaultEncryptionKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DefaultExpirationDays => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DomainName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::CustomerProfiles::Domain - Cfn resource for AWS::CustomerProfiles::Domain

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::CustomerProfiles::Domain.

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
