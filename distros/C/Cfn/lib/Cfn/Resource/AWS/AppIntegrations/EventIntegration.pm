# AWS::AppIntegrations::EventIntegration generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AppIntegrations::EventIntegration',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AppIntegrations::EventIntegration->new( %$_ ) };

package Cfn::Resource::AWS::AppIntegrations::EventIntegration {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AppIntegrations::EventIntegration', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Associations','EventIntegrationArn' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-2','us-east-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::AppIntegrations::EventIntegration::Metadata',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::AppIntegrations::EventIntegration::Metadata',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::AppIntegrations::EventIntegration::Metadata')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::AppIntegrations::EventIntegration::Metadata',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppIntegrations::EventIntegration::Metadata',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppIntegrations::EventIntegration::Metadata->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppIntegrations::EventIntegration::Metadata {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppIntegrations::EventIntegration::EventIntegrationAssociation',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppIntegrations::EventIntegration::EventIntegrationAssociation',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppIntegrations::EventIntegration::EventIntegrationAssociation->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppIntegrations::EventIntegration::EventIntegrationAssociation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClientAssociationMetadata => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AppIntegrations::EventIntegration::Metadata', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ClientId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EventBridgeRuleName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EventIntegrationAssociationArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EventIntegrationAssociationId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppIntegrations::EventIntegration::EventFilter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppIntegrations::EventIntegration::EventFilter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppIntegrations::EventIntegration::EventFilter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppIntegrations::EventIntegration::EventFilter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Source => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::AppIntegrations::EventIntegration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EventBridgeBus => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EventFilter => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::AppIntegrations::EventIntegration - Cfn resource for AWS::AppIntegrations::EventIntegration

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::AppIntegrations::EventIntegration.

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
