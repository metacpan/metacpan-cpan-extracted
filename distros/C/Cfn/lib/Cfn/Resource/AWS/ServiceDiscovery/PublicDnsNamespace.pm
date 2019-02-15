# AWS::ServiceDiscovery::PublicDnsNamespace generated from spec 1.12.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ServiceDiscovery::PublicDnsNamespace',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ServiceDiscovery::PublicDnsNamespace->new( %$_ ) };

package Cfn::Resource::AWS::ServiceDiscovery::PublicDnsNamespace {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ServiceDiscovery::PublicDnsNamespace', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'Arn','Id' ]
  }
}



package Cfn::Resource::Properties::AWS::ServiceDiscovery::PublicDnsNamespace {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
