# AWS::GroundStation::DataflowEndpointGroup generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup->new( %$_ ) };

package Cfn::Resource::AWS::GroundStation::DataflowEndpointGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Id' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-southeast-2','eu-central-1','eu-north-1','eu-west-1','me-south-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup::SocketAddress',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup::SocketAddress',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::DataflowEndpointGroup::SocketAddress->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::DataflowEndpointGroup::SocketAddress {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Port => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup::SecurityDetails',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup::SecurityDetails',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::DataflowEndpointGroup::SecurityDetails->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::DataflowEndpointGroup::SecurityDetails {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecurityGroupIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubnetIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup::DataflowEndpoint',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup::DataflowEndpoint',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::DataflowEndpointGroup::DataflowEndpoint->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::DataflowEndpointGroup::DataflowEndpoint {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Address => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup::SocketAddress', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Mtu => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup::EndpointDetails',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup::EndpointDetails',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup::EndpointDetails')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup::EndpointDetails',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup::EndpointDetails',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::GroundStation::DataflowEndpointGroup::EndpointDetails->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::GroundStation::DataflowEndpointGroup::EndpointDetails {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Endpoint => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup::DataflowEndpoint', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecurityDetails => (isa => 'Cfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup::SecurityDetails', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has EndpointDetails => (isa => 'ArrayOfCfn::Resource::Properties::AWS::GroundStation::DataflowEndpointGroup::EndpointDetails', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::GroundStation::DataflowEndpointGroup - Cfn resource for AWS::GroundStation::DataflowEndpointGroup

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::GroundStation::DataflowEndpointGroup.

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
