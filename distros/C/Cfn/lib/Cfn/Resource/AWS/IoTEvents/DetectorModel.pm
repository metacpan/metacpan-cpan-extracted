# AWS::IoTEvents::DetectorModel generated from spec 5.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel->new( %$_ ) };

package Cfn::Resource::AWS::IoTEvents::DetectorModel {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-2','eu-central-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Sqs',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Sqs',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SqsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SqsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has QueueUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UseBase64 => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Sns',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Sns',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SnsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SnsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TargetArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SetVariable',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SetVariable',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SetVariableValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SetVariableValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VariableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SetTimer',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SetTimer',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SetTimerValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SetTimerValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Seconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimerName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ResetTimer',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ResetTimer',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ResetTimerValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ResetTimerValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TimerName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Lambda',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Lambda',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::LambdaValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::LambdaValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FunctionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotTopicPublish',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotTopicPublish',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotTopicPublishValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotTopicPublishValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MqttTopic => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotEvents',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotEvents',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotEventsValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotEventsValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InputName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Firehose',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Firehose',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::FirehoseValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::FirehoseValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DeliveryStreamName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Separator => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ClearTimer',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ClearTimer',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ClearTimerValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ClearTimerValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TimerName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Action',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Action',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Action')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Action',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Action',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ActionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ActionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClearTimer => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ClearTimer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Firehose => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Firehose', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IotEvents => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotEvents', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IotTopicPublish => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotTopicPublish', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Lambda => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Lambda', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ResetTimer => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ResetTimer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SetTimer => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SetTimer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SetVariable => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SetVariable', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Sns => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Sns', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Sqs => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Sqs', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::TransitionEvent',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::TransitionEvent',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::TransitionEvent')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::TransitionEvent',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::TransitionEvent',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::TransitionEventValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::TransitionEventValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Actions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Action', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Condition => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EventName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NextState => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Event',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Event',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Event')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Event',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Event',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::EventValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::EventValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Actions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Action', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Condition => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EventName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnInput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnInput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnInputValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnInputValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Events => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Event', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TransitionEvents => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::TransitionEvent', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnExit',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnExit',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnExitValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnExitValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Events => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Event', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnEnter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnEnter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnEnterValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnEnterValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Events => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Event', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::State',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::State',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::State')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::State',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::State',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::StateValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::StateValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has OnEnter => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnEnter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OnExit => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnExit', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OnInput => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnInput', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StateName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::DetectorModelDefinition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::DetectorModelDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::DetectorModelDefinitionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::DetectorModelDefinitionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InitialStateName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has States => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::State', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DetectorModelDefinition => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::DetectorModelDefinition', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DetectorModelDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DetectorModelName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
