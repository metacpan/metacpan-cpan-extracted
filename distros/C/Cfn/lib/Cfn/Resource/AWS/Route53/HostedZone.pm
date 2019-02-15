# AWS::Route53::HostedZone generated from spec 1.11.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Route53::HostedZone',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Route53::HostedZone->new( %$_ ) };

package Cfn::Resource::AWS::Route53::HostedZone {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Route53::HostedZone', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'NameServers' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::Route53::HostedZone::VPC',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Route53::HostedZone::VPC',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Route53::HostedZone::VPC')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Route53::HostedZone::VPC',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Route53::HostedZone::VPC',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Route53::HostedZone::VPCValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Route53::HostedZone::VPCValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VPCId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VPCRegion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Route53::HostedZone::QueryLoggingConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Route53::HostedZone::QueryLoggingConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Route53::HostedZone::QueryLoggingConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Route53::HostedZone::QueryLoggingConfigValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudWatchLogsLogGroupArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Route53::HostedZone::HostedZoneTag',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Route53::HostedZone::HostedZoneTag',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Route53::HostedZone::HostedZoneTag')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Route53::HostedZone::HostedZoneTag',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Route53::HostedZone::HostedZoneTag',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Route53::HostedZone::HostedZoneTagValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Route53::HostedZone::HostedZoneTagValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Route53::HostedZone::HostedZoneConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Route53::HostedZone::HostedZoneConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Route53::HostedZone::HostedZoneConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Route53::HostedZone::HostedZoneConfigValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Comment => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Route53::HostedZone {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has HostedZoneConfig => (isa => 'Cfn::Resource::Properties::AWS::Route53::HostedZone::HostedZoneConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HostedZoneTags => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Route53::HostedZone::HostedZoneTag', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has QueryLoggingConfig => (isa => 'Cfn::Resource::Properties::AWS::Route53::HostedZone::QueryLoggingConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VPCs => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Route53::HostedZone::VPC', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Conditional');
}

1;
