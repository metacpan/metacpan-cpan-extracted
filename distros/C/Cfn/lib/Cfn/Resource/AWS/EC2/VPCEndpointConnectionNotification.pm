# AWS::EC2::VPCEndpointConnectionNotification generated from spec 14.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::VPCEndpointConnectionNotification',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::VPCEndpointConnectionNotification->new( %$_ ) };

package Cfn::Resource::AWS::EC2::VPCEndpointConnectionNotification {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::VPCEndpointConnectionNotification', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-3','cn-north-1','cn-northwest-1','eu-north-1','us-east-1' ]
  }
}



package Cfn::Resource::Properties::AWS::EC2::VPCEndpointConnectionNotification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ConnectionEvents => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectionNotificationArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VPCEndpointId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::EC2::VPCEndpointConnectionNotification - Cfn resource for AWS::EC2::VPCEndpointConnectionNotification

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::EC2::VPCEndpointConnectionNotification.

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
