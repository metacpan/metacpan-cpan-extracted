# AWS::SES::ConfigurationSetEventDestination generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination->new( %$_ ) };

package Cfn::Resource::AWS::SES::ConfigurationSetEventDestination {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'eu-west-1','us-east-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination::DimensionConfiguration',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination::DimensionConfiguration',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination::DimensionConfiguration')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination::DimensionConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination::DimensionConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SES::ConfigurationSetEventDestination::DimensionConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SES::ConfigurationSetEventDestination::DimensionConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DefaultDimensionValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DimensionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DimensionValueSource => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination::KinesisFirehoseDestination',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination::KinesisFirehoseDestination',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SES::ConfigurationSetEventDestination::KinesisFirehoseDestination->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SES::ConfigurationSetEventDestination::KinesisFirehoseDestination {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DeliveryStreamARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IAMRoleARN => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination::CloudWatchDestination',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination::CloudWatchDestination',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SES::ConfigurationSetEventDestination::CloudWatchDestination->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SES::ConfigurationSetEventDestination::CloudWatchDestination {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DimensionConfigurations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination::DimensionConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination::EventDestination',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination::EventDestination',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SES::ConfigurationSetEventDestination::EventDestination->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SES::ConfigurationSetEventDestination::EventDestination {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudWatchDestination => (isa => 'Cfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination::CloudWatchDestination', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KinesisFirehoseDestination => (isa => 'Cfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination::KinesisFirehoseDestination', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MatchingEventTypes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ConfigurationSetName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EventDestination => (isa => 'Cfn::Resource::Properties::AWS::SES::ConfigurationSetEventDestination::EventDestination', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::SES::ConfigurationSetEventDestination - Cfn resource for AWS::SES::ConfigurationSetEventDestination

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::SES::ConfigurationSetEventDestination.

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
