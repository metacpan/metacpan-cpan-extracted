# AWS::PinpointEmail::ConfigurationSet generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet->new( %$_ ) };

package Cfn::Resource::AWS::PinpointEmail::ConfigurationSet {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-south-1','ap-southeast-2','eu-central-1','eu-west-1','us-east-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::TrackingOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::TrackingOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSet::TrackingOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSet::TrackingOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CustomRedirectDomain => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::Tags',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::Tags',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::Tags')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::Tags',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::Tags',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSet::Tags->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSet::Tags {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::SendingOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::SendingOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSet::SendingOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSet::SendingOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SendingEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::ReputationOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::ReputationOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSet::ReputationOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSet::ReputationOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ReputationMetricsEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::DeliveryOptions',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::DeliveryOptions',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSet::DeliveryOptions->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSet::DeliveryOptions {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SendingPoolName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DeliveryOptions => (isa => 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::DeliveryOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ReputationOptions => (isa => 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::ReputationOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SendingOptions => (isa => 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::SendingOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::Tags', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TrackingOptions => (isa => 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSet::TrackingOptions', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::PinpointEmail::ConfigurationSet - Cfn resource for AWS::PinpointEmail::ConfigurationSet

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::PinpointEmail::ConfigurationSet.

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
