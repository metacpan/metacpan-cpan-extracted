# AWS::IoTSiteWise::Gateway generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::Gateway',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoTSiteWise::Gateway->new( %$_ ) };

package Cfn::Resource::AWS::IoTSiteWise::Gateway {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::Gateway', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'GatewayId' ]
  }
  sub supported_regions {
    [ 'ap-southeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','us-east-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::Gateway::Greengrass',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::Gateway::Greengrass',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::Gateway::Greengrass->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::Gateway::Greengrass {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has GroupArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::Gateway::GatewayPlatform',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::Gateway::GatewayPlatform',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::Gateway::GatewayPlatform->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::Gateway::GatewayPlatform {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Greengrass => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::Gateway::Greengrass', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::Gateway::GatewayCapabilitySummary',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::Gateway::GatewayCapabilitySummary',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       die 'Only accepts functions'; 
     }
   },
  from 'ArrayRef',
   via {
     Cfn::Value::Array->new(Value => [
       map { 
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTSiteWise::Gateway::GatewayCapabilitySummary')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::Gateway::GatewayCapabilitySummary',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::Gateway::GatewayCapabilitySummary',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::Gateway::GatewayCapabilitySummary->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::Gateway::GatewayCapabilitySummary {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CapabilityConfiguration => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CapabilityNamespace => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::IoTSiteWise::Gateway {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has GatewayCapabilitySummaries => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTSiteWise::Gateway::GatewayCapabilitySummary', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GatewayName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GatewayPlatform => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::Gateway::GatewayPlatform', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IoTSiteWise::Gateway - Cfn resource for AWS::IoTSiteWise::Gateway

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IoTSiteWise::Gateway.

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
