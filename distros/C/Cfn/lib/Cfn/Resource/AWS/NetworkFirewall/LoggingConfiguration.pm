# AWS::NetworkFirewall::LoggingConfiguration generated from spec 21.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::LoggingConfiguration',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::NetworkFirewall::LoggingConfiguration->new( %$_ ) };

package Cfn::Resource::AWS::NetworkFirewall::LoggingConfiguration {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::LoggingConfiguration', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'FirewallArn','FirewallName' ]
  }
  sub supported_regions {
    [ 'eu-west-1','us-east-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::LoggingConfiguration::LogDestinationConfig',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::LoggingConfiguration::LogDestinationConfig',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::NetworkFirewall::LoggingConfiguration::LogDestinationConfig')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::LoggingConfiguration::LogDestinationConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::LoggingConfiguration::LogDestinationConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::LoggingConfiguration::LogDestinationConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::LoggingConfiguration::LogDestinationConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LogDestination => (isa => 'Cfn::Value::Hash|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogDestinationType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LogType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::LoggingConfiguration::LogDestinationConfigs',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::LoggingConfiguration::LogDestinationConfigs',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::LoggingConfiguration::LogDestinationConfigs->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::LoggingConfiguration::LogDestinationConfigs {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LogDestinationConfigs => (isa => 'ArrayOfCfn::Resource::Properties::AWS::NetworkFirewall::LoggingConfiguration::LogDestinationConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::NetworkFirewall::LoggingConfiguration::LoggingConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::NetworkFirewall::LoggingConfiguration::LoggingConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::NetworkFirewall::LoggingConfiguration::LoggingConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::NetworkFirewall::LoggingConfiguration::LoggingConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LogDestinationConfigs => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::LoggingConfiguration::LogDestinationConfigs', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::NetworkFirewall::LoggingConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has LoggingConfiguration => (isa => 'Cfn::Resource::Properties::AWS::NetworkFirewall::LoggingConfiguration::LoggingConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::NetworkFirewall::LoggingConfiguration - Cfn resource for AWS::NetworkFirewall::LoggingConfiguration

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::NetworkFirewall::LoggingConfiguration.

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
