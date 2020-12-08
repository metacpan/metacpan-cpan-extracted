# AWS::RoboMaker::SimulationApplication generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplication',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplication->new( %$_ ) };

package Cfn::Resource::AWS::RoboMaker::SimulationApplication {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplication', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','CurrentRevisionId' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-1','eu-central-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::RoboMaker::SimulationApplication::SourceConfig',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::RoboMaker::SimulationApplication::SourceConfig',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplication::SourceConfig')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplication::SourceConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplication::SourceConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::RoboMaker::SimulationApplication::SourceConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::RoboMaker::SimulationApplication::SourceConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Architecture => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3Bucket => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplication::SimulationSoftwareSuite',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplication::SimulationSoftwareSuite',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::RoboMaker::SimulationApplication::SimulationSoftwareSuite->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::RoboMaker::SimulationApplication::SimulationSoftwareSuite {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Version => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplication::RobotSoftwareSuite',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplication::RobotSoftwareSuite',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::RoboMaker::SimulationApplication::RobotSoftwareSuite->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::RoboMaker::SimulationApplication::RobotSoftwareSuite {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Version => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplication::RenderingEngine',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplication::RenderingEngine',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::RoboMaker::SimulationApplication::RenderingEngine->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::RoboMaker::SimulationApplication::RenderingEngine {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Version => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplication {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has CurrentRevisionId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RenderingEngine => (isa => 'Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplication::RenderingEngine', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RobotSoftwareSuite => (isa => 'Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplication::RobotSoftwareSuite', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SimulationSoftwareSuite => (isa => 'Cfn::Resource::Properties::AWS::RoboMaker::SimulationApplication::SimulationSoftwareSuite', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Sources => (isa => 'ArrayOfCfn::Resource::Properties::AWS::RoboMaker::SimulationApplication::SourceConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'Cfn::Value::Json|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::RoboMaker::SimulationApplication - Cfn resource for AWS::RoboMaker::SimulationApplication

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::RoboMaker::SimulationApplication.

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
