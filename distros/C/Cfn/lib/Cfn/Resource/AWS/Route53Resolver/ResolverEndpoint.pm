# AWS::Route53Resolver::ResolverEndpoint generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Route53Resolver::ResolverEndpoint',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Route53Resolver::ResolverEndpoint->new( %$_ ) };

package Cfn::Resource::AWS::Route53Resolver::ResolverEndpoint {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Route53Resolver::ResolverEndpoint', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Direction','HostVPCId','IpAddressCount','Name','ResolverEndpointId' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-southeast-1','ap-southeast-2','eu-north-1','eu-west-1','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::Route53Resolver::ResolverEndpoint::IpAddressRequest',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Route53Resolver::ResolverEndpoint::IpAddressRequest',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Route53Resolver::ResolverEndpoint::IpAddressRequest')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Route53Resolver::ResolverEndpoint::IpAddressRequest',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Route53Resolver::ResolverEndpoint::IpAddressRequest',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Route53Resolver::ResolverEndpoint::IpAddressRequest->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Route53Resolver::ResolverEndpoint::IpAddressRequest {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Ip => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubnetId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Route53Resolver::ResolverEndpoint {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Direction => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has IpAddresses => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Route53Resolver::ResolverEndpoint::IpAddressRequest', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecurityGroupIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Route53Resolver::ResolverEndpoint - Cfn resource for AWS::Route53Resolver::ResolverEndpoint

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Route53Resolver::ResolverEndpoint.

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
