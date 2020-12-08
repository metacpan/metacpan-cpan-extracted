# AWS::PinpointEmail::ConfigurationSetEventDestination generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination->new( %$_ ) };

package Cfn::Resource::AWS::PinpointEmail::ConfigurationSetEventDestination {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-south-1','ap-southeast-2','eu-central-1','eu-west-1','us-east-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::DimensionConfiguration',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::DimensionConfiguration',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::DimensionConfiguration')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::DimensionConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::DimensionConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSetEventDestination::DimensionConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSetEventDestination::DimensionConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DefaultDimensionValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DimensionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DimensionValueSource => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::SnsDestination',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::SnsDestination',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSetEventDestination::SnsDestination->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSetEventDestination::SnsDestination {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TopicArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::PinpointDestination',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::PinpointDestination',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSetEventDestination::PinpointDestination->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSetEventDestination::PinpointDestination {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ApplicationArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::KinesisFirehoseDestination',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::KinesisFirehoseDestination',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSetEventDestination::KinesisFirehoseDestination->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSetEventDestination::KinesisFirehoseDestination {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DeliveryStreamArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IamRoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::CloudWatchDestination',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::CloudWatchDestination',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSetEventDestination::CloudWatchDestination->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSetEventDestination::CloudWatchDestination {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DimensionConfigurations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::DimensionConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::EventDestination',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::EventDestination',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSetEventDestination::EventDestination->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::PinpointEmail::ConfigurationSetEventDestination::EventDestination {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudWatchDestination => (isa => 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::CloudWatchDestination', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KinesisFirehoseDestination => (isa => 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::KinesisFirehoseDestination', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MatchingEventTypes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PinpointDestination => (isa => 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::PinpointDestination', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SnsDestination => (isa => 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::SnsDestination', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ConfigurationSetName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EventDestination => (isa => 'Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::EventDestination', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EventDestinationName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::PinpointEmail::ConfigurationSetEventDestination - Cfn resource for AWS::PinpointEmail::ConfigurationSetEventDestination

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::PinpointEmail::ConfigurationSetEventDestination.

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
