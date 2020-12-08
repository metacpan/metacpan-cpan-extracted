# AWS::ElasticLoadBalancing::LoadBalancer generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer->new( %$_ ) };

package Cfn::Resource::AWS::ElasticLoadBalancing::LoadBalancer {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'CanonicalHostedZoneName','CanonicalHostedZoneNameID','DNSName','SourceSecurityGroup.GroupName','SourceSecurityGroup.OwnerAlias' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::Policies',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::Policies',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::Policies')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::Policies',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::Policies',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancing::LoadBalancer::Policies->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancing::LoadBalancer::Policies {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Attributes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InstancePorts => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoadBalancerPorts => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PolicyName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PolicyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::Listeners',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::Listeners',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::Listeners')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::Listeners',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::Listeners',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancing::LoadBalancer::Listeners->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancing::LoadBalancer::Listeners {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InstancePort => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InstanceProtocol => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoadBalancerPort => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PolicyNames => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Protocol => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SSLCertificateId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::LBCookieStickinessPolicy',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::LBCookieStickinessPolicy',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::LBCookieStickinessPolicy')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::LBCookieStickinessPolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::LBCookieStickinessPolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancing::LoadBalancer::LBCookieStickinessPolicy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancing::LoadBalancer::LBCookieStickinessPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CookieExpirationPeriod => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PolicyName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::HealthCheck',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::HealthCheck',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancing::LoadBalancer::HealthCheck->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancing::LoadBalancer::HealthCheck {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HealthyThreshold => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Interval => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Target => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Timeout => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UnhealthyThreshold => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::ConnectionSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::ConnectionSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancing::LoadBalancer::ConnectionSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancing::LoadBalancer::ConnectionSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IdleTimeout => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::ConnectionDrainingPolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::ConnectionDrainingPolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancing::LoadBalancer::ConnectionDrainingPolicy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancing::LoadBalancer::ConnectionDrainingPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Timeout => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::AppCookieStickinessPolicy',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::AppCookieStickinessPolicy',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::AppCookieStickinessPolicy')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::AppCookieStickinessPolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::AppCookieStickinessPolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancing::LoadBalancer::AppCookieStickinessPolicy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancing::LoadBalancer::AppCookieStickinessPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CookieName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PolicyName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::AccessLoggingPolicy',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::AccessLoggingPolicy',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancing::LoadBalancer::AccessLoggingPolicy->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ElasticLoadBalancing::LoadBalancer::AccessLoggingPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EmitInterval => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3BucketName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3BucketPrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AccessLoggingPolicy => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::AccessLoggingPolicy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AppCookieStickinessPolicy => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::AppCookieStickinessPolicy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AvailabilityZones => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Conditional');
  has ConnectionDrainingPolicy => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::ConnectionDrainingPolicy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectionSettings => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::ConnectionSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CrossZone => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HealthCheck => (isa => 'Cfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::HealthCheck', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Conditional');
  has Instances => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LBCookieStickinessPolicy => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::LBCookieStickinessPolicy', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Listeners => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::Listeners', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoadBalancerName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Policies => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ElasticLoadBalancing::LoadBalancer::Policies', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scheme => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SecurityGroups => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Subnets => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Conditional');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::ElasticLoadBalancing::LoadBalancer - Cfn resource for AWS::ElasticLoadBalancing::LoadBalancer

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::ElasticLoadBalancing::LoadBalancer.

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
