# AWS::IoT1Click::Device generated from spec 14.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoT1Click::Device',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoT1Click::Device->new( %$_ ) };

package Cfn::Resource::AWS::IoT1Click::Device {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoT1Click::Device', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','DeviceId','Enabled' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::IoT1Click::Device {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DeviceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IoT1Click::Device - Cfn resource for AWS::IoT1Click::Device

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IoT1Click::Device.

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
