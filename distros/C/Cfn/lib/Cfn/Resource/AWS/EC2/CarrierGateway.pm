# AWS::EC2::CarrierGateway generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::CarrierGateway',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::CarrierGateway->new( %$_ ) };

package Cfn::Resource::AWS::EC2::CarrierGateway {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::CarrierGateway', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'CarrierGatewayId','OwnerId','State' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','us-east-1','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::EC2::CarrierGateway {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpcId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::EC2::CarrierGateway - Cfn resource for AWS::EC2::CarrierGateway

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::EC2::CarrierGateway.

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
