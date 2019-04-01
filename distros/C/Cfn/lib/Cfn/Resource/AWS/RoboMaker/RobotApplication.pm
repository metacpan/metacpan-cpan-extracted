# AWS::RoboMaker::RobotApplication generated from spec 2.25.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::RoboMaker::RobotApplication',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::RoboMaker::RobotApplication->new( %$_ ) };

package Cfn::Resource::AWS::RoboMaker::RobotApplication {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::RoboMaker::RobotApplication', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','CurrentRevisionId' ]
  }
  sub supported_regions {
    [ 'eu-west-1','us-east-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::RoboMaker::RobotApplication::SourceConfig',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::RoboMaker::RobotApplication::SourceConfig',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::RoboMaker::RobotApplication::SourceConfig')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::RoboMaker::RobotApplication::SourceConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::RoboMaker::RobotApplication::SourceConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::RoboMaker::RobotApplication::SourceConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::RoboMaker::RobotApplication::SourceConfigValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Architecture => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3Bucket => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::RoboMaker::RobotApplication::RobotSoftwareSuite',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::RoboMaker::RobotApplication::RobotSoftwareSuite',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::RoboMaker::RobotApplication::RobotSoftwareSuiteValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::RoboMaker::RobotApplication::RobotSoftwareSuiteValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Version => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::RoboMaker::RobotApplication {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has CurrentRevisionId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RobotSoftwareSuite => (isa => 'Cfn::Resource::Properties::AWS::RoboMaker::RobotApplication::RobotSoftwareSuite', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Sources => (isa => 'ArrayOfCfn::Resource::Properties::AWS::RoboMaker::RobotApplication::SourceConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
