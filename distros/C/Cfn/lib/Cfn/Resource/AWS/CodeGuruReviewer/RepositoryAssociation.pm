# AWS::CodeGuruReviewer::RepositoryAssociation generated from spec 22.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CodeGuruReviewer::RepositoryAssociation',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CodeGuruReviewer::RepositoryAssociation->new( %$_ ) };

package Cfn::Resource::AWS::CodeGuruReviewer::RepositoryAssociation {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CodeGuruReviewer::RepositoryAssociation', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'AssociationArn' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-1','ap-southeast-2','eu-central-1','eu-north-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::CodeGuruReviewer::RepositoryAssociation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ConnectionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Owner => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::CodeGuruReviewer::RepositoryAssociation - Cfn resource for AWS::CodeGuruReviewer::RepositoryAssociation

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::CodeGuruReviewer::RepositoryAssociation.

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
