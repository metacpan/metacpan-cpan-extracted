# AWS::Greengrass::SubscriptionDefinitionVersion generated from spec 6.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Greengrass::SubscriptionDefinitionVersion',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Greengrass::SubscriptionDefinitionVersion->new( %$_ ) };

package Cfn::Resource::AWS::Greengrass::SubscriptionDefinitionVersion {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Greengrass::SubscriptionDefinitionVersion', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-gov-west-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::SubscriptionDefinitionVersion::Subscription',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::SubscriptionDefinitionVersion::Subscription',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Greengrass::SubscriptionDefinitionVersion::Subscription')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Greengrass::SubscriptionDefinitionVersion::Subscription',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Greengrass::SubscriptionDefinitionVersion::Subscription',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Greengrass::SubscriptionDefinitionVersion::SubscriptionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Greengrass::SubscriptionDefinitionVersion::SubscriptionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Source => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Subject => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Target => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

package Cfn::Resource::Properties::AWS::Greengrass::SubscriptionDefinitionVersion {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has SubscriptionDefinitionId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Subscriptions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Greengrass::SubscriptionDefinitionVersion::Subscription', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
