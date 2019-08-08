# AWS::IoTEvents::Input generated from spec 5.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::Input',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoTEvents::Input->new( %$_ ) };

package Cfn::Resource::AWS::IoTEvents::Input {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::Input', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-2','eu-central-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::Input::Attribute',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::Input::Attribute',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTEvents::Input::Attribute')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::Input::Attribute',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::Input::Attribute',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::Input::AttributeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::Input::AttributeValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has JsonPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::Input::InputDefinition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::Input::InputDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::Input::InputDefinitionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::Input::InputDefinitionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Attributes => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::Input::Attribute', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::IoTEvents::Input {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has InputDefinition => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::Input::InputDefinition', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
