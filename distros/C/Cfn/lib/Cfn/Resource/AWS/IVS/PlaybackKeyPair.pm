# AWS::IVS::PlaybackKeyPair generated from spec 20.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IVS::PlaybackKeyPair',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IVS::PlaybackKeyPair->new( %$_ ) };

package Cfn::Resource::AWS::IVS::PlaybackKeyPair {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IVS::PlaybackKeyPair', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Fingerprint' ]
  }
  sub supported_regions {
    [ 'eu-west-1','us-east-1','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::IVS::PlaybackKeyPair {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has PublicKeyMaterial => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IVS::PlaybackKeyPair - Cfn resource for AWS::IVS::PlaybackKeyPair

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IVS::PlaybackKeyPair.

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
