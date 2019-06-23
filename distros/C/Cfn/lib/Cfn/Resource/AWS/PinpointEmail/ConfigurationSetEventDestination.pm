# AWS::PinpointEmail::ConfigurationSetEventDestination generated from spec 3.3.0
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
       return Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::DimensionConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::DimensionConfigurationValue {
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
       return Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::SnsDestinationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::SnsDestinationValue {
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
       return Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::PinpointDestinationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::PinpointDestinationValue {
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
       return Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::KinesisFirehoseDestinationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::KinesisFirehoseDestinationValue {
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
       return Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::CloudWatchDestinationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::CloudWatchDestinationValue {
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
       return Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::EventDestinationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::PinpointEmail::ConfigurationSetEventDestination::EventDestinationValue {
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
