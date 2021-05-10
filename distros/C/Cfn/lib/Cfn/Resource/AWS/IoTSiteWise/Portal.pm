# AWS::IoTSiteWise::Portal generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::Portal',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoTSiteWise::Portal->new( %$_ ) };

package Cfn::Resource::AWS::IoTSiteWise::Portal {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::Portal', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'PortalArn','PortalClientId','PortalId','PortalStartUrl' ]
  }
  sub supported_regions {
    [ 'ap-southeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','us-east-1','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::IoTSiteWise::Portal {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has PortalAuthMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has PortalContactEmail => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PortalDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PortalName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IoTSiteWise::Portal - Cfn resource for AWS::IoTSiteWise::Portal

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IoTSiteWise::Portal.

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
