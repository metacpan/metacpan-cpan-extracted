# AWS::MediaLive::InputSecurityGroup generated from spec 4.1.0
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
       return Cfn::Resource::Properties::AWS::MediaLive::InputSecurityGroup::InputWhitelistRuleCidrValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::MediaLive::InputSecurityGroup::InputWhitelistRuleCidrValue {
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
