# AWS::ApiGatewayV2::ApiGatewayManagedOverrides generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides->new( %$_ ) };

package Cfn::Resource::AWS::ApiGatewayV2::ApiGatewayManagedOverrides {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'us-east-1' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::RouteSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::RouteSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::RouteSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::RouteSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataTraceEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DetailedMetricsEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoggingLevel => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ThrottlingBurstLimit => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ThrottlingRateLimit => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::AccessLogSettings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::AccessLogSettings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::AccessLogSettings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::AccessLogSettings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DestinationArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Format => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::StageOverrides',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::StageOverrides',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::StageOverrides->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::StageOverrides {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccessLogSettings => (isa => 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::AccessLogSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AutoDeploy => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DefaultRouteSettings => (isa => 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::RouteSettings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RouteSettings => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StageVariables => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::RouteOverrides',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::RouteOverrides',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::RouteOverrides->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::RouteOverrides {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AuthorizationScopes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AuthorizationType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AuthorizerId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OperationName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Target => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::IntegrationOverrides',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::IntegrationOverrides',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::IntegrationOverrides->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::IntegrationOverrides {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IntegrationMethod => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PayloadFormatVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimeoutInMillis => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ApiId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Integration => (isa => 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::IntegrationOverrides', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Route => (isa => 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::RouteOverrides', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Stage => (isa => 'Cfn::Resource::Properties::AWS::ApiGatewayV2::ApiGatewayManagedOverrides::StageOverrides', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::ApiGatewayV2::ApiGatewayManagedOverrides - Cfn resource for AWS::ApiGatewayV2::ApiGatewayManagedOverrides

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::ApiGatewayV2::ApiGatewayManagedOverrides.

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
