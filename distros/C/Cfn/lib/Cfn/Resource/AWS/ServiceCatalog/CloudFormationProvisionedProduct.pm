# AWS::ServiceCatalog::CloudFormationProvisionedProduct generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ServiceCatalog::CloudFormationProvisionedProduct',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ServiceCatalog::CloudFormationProvisionedProduct->new( %$_ ) };

package Cfn::Resource::AWS::ServiceCatalog::CloudFormationProvisionedProduct {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ServiceCatalog::CloudFormationProvisionedProduct', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'CloudformationStackArn','ProvisionedProductId','RecordId' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::ServiceCatalog::CloudFormationProvisionedProduct::ProvisioningPreferences',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ServiceCatalog::CloudFormationProvisionedProduct::ProvisioningPreferences',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ServiceCatalog::CloudFormationProvisionedProduct::ProvisioningPreferences->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ServiceCatalog::CloudFormationProvisionedProduct::ProvisioningPreferences {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has StackSetAccounts => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StackSetFailureToleranceCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StackSetFailureTolerancePercentage => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StackSetMaxConcurrencyCount => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StackSetMaxConcurrencyPercentage => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StackSetOperationType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StackSetRegions => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::ServiceCatalog::CloudFormationProvisionedProduct::ProvisioningParameter',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::ServiceCatalog::CloudFormationProvisionedProduct::ProvisioningParameter',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::ServiceCatalog::CloudFormationProvisionedProduct::ProvisioningParameter')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::ServiceCatalog::CloudFormationProvisionedProduct::ProvisioningParameter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::ServiceCatalog::CloudFormationProvisionedProduct::ProvisioningParameter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::ServiceCatalog::CloudFormationProvisionedProduct::ProvisioningParameter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::ServiceCatalog::CloudFormationProvisionedProduct::ProvisioningParameter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::ServiceCatalog::CloudFormationProvisionedProduct {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AcceptLanguage => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NotificationArns => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has PathId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PathName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProductId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProductName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProvisionedProductName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ProvisioningArtifactId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProvisioningArtifactName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProvisioningParameters => (isa => 'ArrayOfCfn::Resource::Properties::AWS::ServiceCatalog::CloudFormationProvisionedProduct::ProvisioningParameter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProvisioningPreferences => (isa => 'Cfn::Resource::Properties::AWS::ServiceCatalog::CloudFormationProvisionedProduct::ProvisioningPreferences', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::ServiceCatalog::CloudFormationProvisionedProduct - Cfn resource for AWS::ServiceCatalog::CloudFormationProvisionedProduct

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::ServiceCatalog::CloudFormationProvisionedProduct.

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
