# AWS::WorkSpaces::ConnectionAlias generated from spec 20.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::WorkSpaces::ConnectionAlias',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::WorkSpaces::ConnectionAlias->new( %$_ ) };

package Cfn::Resource::AWS::WorkSpaces::ConnectionAlias {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::WorkSpaces::ConnectionAlias', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'AliasId','Associations','ConnectionAliasState' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','sa-east-1','us-east-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::WorkSpaces::ConnectionAlias::ConnectionAliasAssociation',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::WorkSpaces::ConnectionAlias::ConnectionAliasAssociation',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::WorkSpaces::ConnectionAlias::ConnectionAliasAssociation->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::WorkSpaces::ConnectionAlias::ConnectionAliasAssociation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AssociatedAccountId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AssociationStatus => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectionIdentifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::WorkSpaces::ConnectionAlias {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ConnectionString => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::WorkSpaces::ConnectionAlias - Cfn resource for AWS::WorkSpaces::ConnectionAlias

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::WorkSpaces::ConnectionAlias.

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
