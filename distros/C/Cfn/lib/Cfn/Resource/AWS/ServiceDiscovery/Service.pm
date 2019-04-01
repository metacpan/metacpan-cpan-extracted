# AWS::ServiceDiscovery::Service generated from spec 2.25.0
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
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','eu-west-3','us-east-1','us-east-2','us-west-1','us-west-2' ]
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
       return Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::DnsRecordValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::DnsRecordValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TTL => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::HealthCheckCustomConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::HealthCheckCustomConfigValue {
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
       return Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::HealthCheckConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::HealthCheckConfigValue {
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
       return Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::DnsConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::ServiceDiscovery::Service::DnsConfigValue {
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
}

1;
