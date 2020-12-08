# AWS::NetworkFirewall::Firewall generated from spec 21.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::Firewall',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::NetworkFirewall::Firewall->new( %$_ ) };

package Cfn::Resource::AWS::NetworkFirewall::Firewall {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::Firewall', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'EndpointIds','FirewallArn','FirewallId' ]
  }
  sub supported_regions {
    [ 'eu-west-1','us-east-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::Firewall::Tags',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::Firewall::Tags',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::Firewall::Tags->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::Firewall::Tags {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::Firewall::SubnetMapping',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::Firewall::SubnetMapping',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::NetworkFirewall::Firewall::SubnetMapping')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::Firewall::SubnetMapping',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::Firewall::SubnetMapping',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::Firewall::SubnetMapping->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::Firewall::SubnetMapping {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SubnetId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::NetworkFirewall::Firewall {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DeleteProtection => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FirewallName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has FirewallPolicyArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FirewallPolicyChangeProtection => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubnetChangeProtection => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubnetMappings => (isa => 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::Firewall::SubnetMapping', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::Firewall::Tags', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpcId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::NetworkFirewall::Firewall - Cfn resource for AWS::NetworkFirewall::Firewall

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::NetworkFirewall::Firewall.

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
