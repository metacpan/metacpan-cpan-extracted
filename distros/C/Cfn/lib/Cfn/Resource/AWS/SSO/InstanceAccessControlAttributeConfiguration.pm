# AWS::SSO::InstanceAccessControlAttributeConfiguration generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SSO::InstanceAccessControlAttributeConfiguration',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SSO::InstanceAccessControlAttributeConfiguration->new( %$_ ) };

package Cfn::Resource::AWS::SSO::InstanceAccessControlAttributeConfiguration {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SSO::InstanceAccessControlAttributeConfiguration', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttributeValueSourceList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttributeValueSourceList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttributeValueSourceList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttributeValueSourceList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccessControlAttributeValueSourceList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttributeValue',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttributeValue',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttributeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttributeValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Source => (isa => 'Cfn::Resource::Properties::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttributeValueSourceList', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttribute',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttribute',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttribute')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttribute',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttribute',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttribute->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttribute {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Resource::Properties::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttributeValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::SSO::InstanceAccessControlAttributeConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AccessControlAttributes => (isa => 'ArrayOfCfn::Resource::Properties::AWS::SSO::InstanceAccessControlAttributeConfiguration::AccessControlAttribute', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InstanceArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::SSO::InstanceAccessControlAttributeConfiguration - Cfn resource for AWS::SSO::InstanceAccessControlAttributeConfiguration

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::SSO::InstanceAccessControlAttributeConfiguration.

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
