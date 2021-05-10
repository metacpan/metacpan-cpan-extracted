# AWS::EC2::TransitGatewayMulticastDomain generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::TransitGatewayMulticastDomain',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::TransitGatewayMulticastDomain->new( %$_ ) };

package Cfn::Resource::AWS::EC2::TransitGatewayMulticastDomain {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::TransitGatewayMulticastDomain', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'CreationTime','State','TransitGatewayMulticastDomainArn','TransitGatewayMulticastDomainId' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::EC2::TransitGatewayMulticastDomain {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Options => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TransitGatewayId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::EC2::TransitGatewayMulticastDomain - Cfn resource for AWS::EC2::TransitGatewayMulticastDomain

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::EC2::TransitGatewayMulticastDomain.

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
