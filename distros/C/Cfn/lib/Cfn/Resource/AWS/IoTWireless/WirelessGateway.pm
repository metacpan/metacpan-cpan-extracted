# AWS::IoTWireless::WirelessGateway generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoTWireless::WirelessGateway',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoTWireless::WirelessGateway->new( %$_ ) };

package Cfn::Resource::AWS::IoTWireless::WirelessGateway {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoTWireless::WirelessGateway', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Id','ThingName' ]
  }
  sub supported_regions {
    [ 'eu-west-1','us-east-1' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IoTWireless::WirelessGateway::LoRaWANGateway',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTWireless::WirelessGateway::LoRaWANGateway',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTWireless::WirelessGateway::LoRaWANGateway->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTWireless::WirelessGateway::LoRaWANGateway {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has GatewayEui => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RfRegion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::IoTWireless::WirelessGateway {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LastUplinkReceivedAt => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoRaWAN => (isa => 'Cfn::Resource::Properties::AWS::IoTWireless::WirelessGateway::LoRaWANGateway', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ThingArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IoTWireless::WirelessGateway - Cfn resource for AWS::IoTWireless::WirelessGateway

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IoTWireless::WirelessGateway.

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
