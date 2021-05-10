# AWS::StepFunctions::StateMachine generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::StepFunctions::StateMachine->new( %$_ ) };

package Cfn::Resource::AWS::StepFunctions::StateMachine {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Name' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::CloudWatchLogsLogGroup',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::CloudWatchLogsLogGroup',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::StepFunctions::StateMachine::CloudWatchLogsLogGroup->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::StepFunctions::StateMachine::CloudWatchLogsLogGroup {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LogGroupArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::StepFunctions::StateMachine::LogDestination',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::StepFunctions::StateMachine::LogDestination',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::LogDestination')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::LogDestination',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::LogDestination',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::StepFunctions::StateMachine::LogDestination->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::StepFunctions::StateMachine::LogDestination {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudWatchLogsLogGroup => (isa => 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::CloudWatchLogsLogGroup', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::TracingConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::TracingConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::StepFunctions::StateMachine::TracingConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::StepFunctions::StateMachine::TracingConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::StepFunctions::StateMachine::TagsEntry',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::StepFunctions::StateMachine::TagsEntry',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::TagsEntry')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::TagsEntry',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::TagsEntry',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::StepFunctions::StateMachine::TagsEntry->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::StepFunctions::StateMachine::TagsEntry {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::S3Location',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::S3Location',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::StepFunctions::StateMachine::S3Location->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::StepFunctions::StateMachine::S3Location {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Bucket => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Version => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::LoggingConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::LoggingConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::StepFunctions::StateMachine::LoggingConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::StepFunctions::StateMachine::LoggingConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Destinations => (isa => 'ArrayOfCfn::Resource::Properties::AWS::StepFunctions::StateMachine::LogDestination', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeExecutionData => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Level => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::Definition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::Definition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::StepFunctions::StateMachine::Definition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::StepFunctions::StateMachine::Definition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
}

package Cfn::Resource::Properties::AWS::StepFunctions::StateMachine {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Definition => (isa => 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::Definition', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DefinitionS3Location => (isa => 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::S3Location', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DefinitionString => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DefinitionSubstitutions => (isa => 'Cfn::Value::Hash|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LoggingConfiguration => (isa => 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::LoggingConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StateMachineName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has StateMachineType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::AWS::StepFunctions::StateMachine::TagsEntry', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TracingConfiguration => (isa => 'Cfn::Resource::Properties::AWS::StepFunctions::StateMachine::TracingConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::StepFunctions::StateMachine - Cfn resource for AWS::StepFunctions::StateMachine

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::StepFunctions::StateMachine.

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
