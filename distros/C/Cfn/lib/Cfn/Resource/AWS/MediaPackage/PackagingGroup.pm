# AWS::MediaPackage::PackagingGroup generated from spec 20.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::MediaPackage::PackagingGroup->new( %$_ ) };

package Cfn::Resource::AWS::MediaPackage::PackagingGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingGroup', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','DomainName' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingGroup::Authorization',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingGroup::Authorization',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingGroup::Authorization->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaPackage::PackagingGroup::Authorization {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CdnIdentifierSecret => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecretsRoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::MediaPackage::PackagingGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Authorization => (isa => 'Cfn::Resource::Properties::AWS::MediaPackage::PackagingGroup::Authorization', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::MediaPackage::PackagingGroup - Cfn resource for AWS::MediaPackage::PackagingGroup

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::MediaPackage::PackagingGroup.

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
