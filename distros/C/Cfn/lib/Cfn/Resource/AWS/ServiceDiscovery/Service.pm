# AWS::ServiceDiscovery::Service generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ServiceDiscovery::Service',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ServiceDiscovery::Service->new( %$_ ) };

package Cfn::Resource::AWS::ServiceDiscovery::Service {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ServiceDiscovery::Service', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Id','Name' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::ServiceDiscovery::Service::DnsRecord',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ServiceDiscovery::Service::DnsRecord',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::DnsRecord')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::DnsRecord',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::DnsRecord',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ServiceDiscovery::Service::DnsRecord->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ServiceDiscovery::Service::DnsRecord {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TTL => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::HealthCheckCustomConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::HealthCheckCustomConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ServiceDiscovery::Service::HealthCheckCustomConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ServiceDiscovery::Service::HealthCheckCustomConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FailureThreshold => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::HealthCheckConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::HealthCheckConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ServiceDiscovery::Service::HealthCheckConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ServiceDiscovery::Service::HealthCheckConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FailureThreshold => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResourcePath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::DnsConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::DnsConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ServiceDiscovery::Service::DnsConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ServiceDiscovery::Service::DnsConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DnsRecords => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ServiceDiscovery::Service::DnsRecord', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NamespaceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RoutingPolicy => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::ServiceDiscovery::Service {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DnsConfig => (isa => 'Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::DnsConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HealthCheckConfig => (isa => 'Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::HealthCheckConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HealthCheckCustomConfig => (isa => 'Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::HealthCheckCustomConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has NamespaceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::ServiceDiscovery::Service - Cfn resource for AWS::ServiceDiscovery::Service

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::ServiceDiscovery::Service.

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
