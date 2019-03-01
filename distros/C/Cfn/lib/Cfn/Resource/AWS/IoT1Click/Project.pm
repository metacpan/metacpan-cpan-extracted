# AWS::IoT1Click::Project generated from spec 2.22.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoT1Click::Project',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoT1Click::Project->new( %$_ ) };

package Cfn::Resource::AWS::IoT1Click::Project {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoT1Click::Project', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'Arn','ProjectName' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IoT1Click::Project::PlacementTemplate',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT1Click::Project::PlacementTemplate',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoT1Click::Project::PlacementTemplateValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoT1Click::Project::PlacementTemplateValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DefaultAttributes => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeviceTemplates => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT1Click::Project::DeviceTemplate',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT1Click::Project::DeviceTemplate',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoT1Click::Project::DeviceTemplateValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoT1Click::Project::DeviceTemplateValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CallbackOverrides => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeviceType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::IoT1Click::Project {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PlacementTemplate => (isa => 'Cfn::Resource::Properties::AWS::IoT1Click::Project::PlacementTemplate', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProjectName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
