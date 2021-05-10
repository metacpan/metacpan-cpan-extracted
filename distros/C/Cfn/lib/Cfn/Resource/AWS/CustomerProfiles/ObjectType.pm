# AWS::CustomerProfiles::ObjectType generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CustomerProfiles::ObjectType',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CustomerProfiles::ObjectType->new( %$_ ) };

package Cfn::Resource::AWS::CustomerProfiles::ObjectType {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CustomerProfiles::ObjectType', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'CreatedAt','LastUpdatedAt' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-1','ap-southeast-2','eu-central-1','eu-west-2','us-east-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::ObjectTypeKey',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::ObjectTypeKey',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::ObjectTypeKey')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::ObjectTypeKey',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::ObjectTypeKey',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::CustomerProfiles::ObjectType::ObjectTypeKey->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::CustomerProfiles::ObjectType::ObjectTypeKey {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FieldNames => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StandardIdentifiers => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::ObjectTypeField',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::ObjectTypeField',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::CustomerProfiles::ObjectType::ObjectTypeField->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::CustomerProfiles::ObjectType::ObjectTypeField {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ContentType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Source => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Target => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::KeyMap',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::KeyMap',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::KeyMap')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::KeyMap',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::KeyMap',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::CustomerProfiles::ObjectType::KeyMap->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::CustomerProfiles::ObjectType::KeyMap {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ObjectTypeKeyList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::ObjectTypeKey', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::FieldMap',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::FieldMap',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::FieldMap')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::FieldMap',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::FieldMap',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::CustomerProfiles::ObjectType::FieldMap->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::CustomerProfiles::ObjectType::FieldMap {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ObjectTypeField => (isa => 'Cfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::ObjectTypeField', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::CustomerProfiles::ObjectType {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AllowProfileCreation => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DomainName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EncryptionKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExpirationDays => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Fields => (isa => 'ArrayOfCfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::FieldMap', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Keys => (isa => 'ArrayOfCfn::Resource::Properties::AWS::CustomerProfiles::ObjectType::KeyMap', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ObjectTypeName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TemplateId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::CustomerProfiles::ObjectType - Cfn resource for AWS::CustomerProfiles::ObjectType

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::CustomerProfiles::ObjectType.

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
