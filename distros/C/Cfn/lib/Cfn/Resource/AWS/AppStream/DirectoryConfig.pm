# AWS::AppStream::DirectoryConfig generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AppStream::DirectoryConfig',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AppStream::DirectoryConfig->new( %$_ ) };

package Cfn::Resource::AWS::AppStream::DirectoryConfig {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AppStream::DirectoryConfig', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','eu-central-1','eu-west-1','us-east-1','us-gov-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::AppStream::DirectoryConfig::ServiceAccountCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppStream::DirectoryConfig::ServiceAccountCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppStream::DirectoryConfig::ServiceAccountCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppStream::DirectoryConfig::ServiceAccountCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccountName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AccountPassword => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::AppStream::DirectoryConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DirectoryName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has OrganizationalUnitDistinguishedNames => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceAccountCredentials => (isa => 'Cfn::Resource::Properties::AWS::AppStream::DirectoryConfig::ServiceAccountCredentials', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::AppStream::DirectoryConfig - Cfn resource for AWS::AppStream::DirectoryConfig

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::AppStream::DirectoryConfig.

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
