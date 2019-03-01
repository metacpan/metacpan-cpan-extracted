# AWS::Route53Resolver::ResolverEndpoint generated from spec 2.22.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Route53Resolver::ResolverEndpoint',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Route53Resolver::ResolverEndpoint->new( %$_ ) };

package Cfn::Resource::AWS::Route53Resolver::ResolverEndpoint {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Route53Resolver::ResolverEndpoint', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'Arn','Direction','HostVPCId','IpAddressCount','Name','ResolverEndpointId' ]
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
       return Cfn::Resource::Properties::AWS::Route53Resolver::ResolverEndpoint::IpAddressRequestValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Route53Resolver::ResolverEndpoint::IpAddressRequestValue {
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
