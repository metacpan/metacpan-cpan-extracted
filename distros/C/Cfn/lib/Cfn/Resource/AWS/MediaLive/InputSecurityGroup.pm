# AWS::MediaLive::InputSecurityGroup generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::MediaLive::InputSecurityGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::MediaLive::InputSecurityGroup->new( %$_ ) };

package Cfn::Resource::AWS::MediaLive::InputSecurityGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::MediaLive::InputSecurityGroup', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','eu-central-1','eu-west-1','sa-east-1','us-east-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::InputSecurityGroup::InputWhitelistRuleCidr',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::InputSecurityGroup::InputWhitelistRuleCidr',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::MediaLive::InputSecurityGroup::InputWhitelistRuleCidr')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::MediaLive::InputSecurityGroup::InputWhitelistRuleCidr',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::MediaLive::InputSecurityGroup::InputWhitelistRuleCidr',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::MediaLive::InputSecurityGroup::InputWhitelistRuleCidr->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::MediaLive::InputSecurityGroup::InputWhitelistRuleCidr {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Cidr => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::MediaLive::InputSecurityGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Tags => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WhitelistRules => (isa => 'ArrayOfCfn::Resource::Properties::AWS::MediaLive::InputSecurityGroup::InputWhitelistRuleCidr', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::MediaLive::InputSecurityGroup - Cfn resource for AWS::MediaLive::InputSecurityGroup

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::MediaLive::InputSecurityGroup.

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
