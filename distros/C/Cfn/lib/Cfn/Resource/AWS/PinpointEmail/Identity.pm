# AWS::PinpointEmail::Identity generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::PinpointEmail::Identity',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::PinpointEmail::Identity->new( %$_ ) };

package Cfn::Resource::AWS::PinpointEmail::Identity {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::PinpointEmail::Identity', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'IdentityDNSRecordName1','IdentityDNSRecordName2','IdentityDNSRecordName3','IdentityDNSRecordValue1','IdentityDNSRecordValue2','IdentityDNSRecordValue3' ]
  }
  sub supported_regions {
    [ 'ap-south-1','ap-southeast-2','eu-central-1','eu-west-1','us-east-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::PinpointEmail::Identity::Tags',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::PinpointEmail::Identity::Tags',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::PinpointEmail::Identity::Tags')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::PinpointEmail::Identity::Tags',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::PinpointEmail::Identity::Tags',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::PinpointEmail::Identity::Tags->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::PinpointEmail::Identity::Tags {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::PinpointEmail::Identity::MailFromAttributes',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::PinpointEmail::Identity::MailFromAttributes',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::PinpointEmail::Identity::MailFromAttributes->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::PinpointEmail::Identity::MailFromAttributes {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BehaviorOnMxFailure => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MailFromDomain => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::PinpointEmail::Identity {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DkimSigningEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FeedbackForwardingEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MailFromAttributes => (isa => 'Cfn::Resource::Properties::AWS::PinpointEmail::Identity::MailFromAttributes', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::AWS::PinpointEmail::Identity::Tags', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::PinpointEmail::Identity - Cfn resource for AWS::PinpointEmail::Identity

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::PinpointEmail::Identity.

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
