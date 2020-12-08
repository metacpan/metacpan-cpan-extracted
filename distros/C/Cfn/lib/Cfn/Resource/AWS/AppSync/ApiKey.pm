# AWS::AppSync::ApiKey generated from spec 20.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AppSync::ApiKey',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AppSync::ApiKey->new( %$_ ) };

package Cfn::Resource::AWS::AppSync::ApiKey {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AppSync::ApiKey', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'ApiKey','Arn' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-southeast-2','cn-north-1','cn-northwest-1','eu-west-1','me-south-1','us-east-1','us-east-2','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::AppSync::ApiKey {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApiId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ApiKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Expires => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::AppSync::ApiKey - Cfn resource for AWS::AppSync::ApiKey

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::AppSync::ApiKey.

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
