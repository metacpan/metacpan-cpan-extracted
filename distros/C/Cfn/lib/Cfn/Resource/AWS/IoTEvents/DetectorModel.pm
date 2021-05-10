# AWS::IoTEvents::DetectorModel generated from spec 34.0.0
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
    [ 'ap-northeast-1','ap-northeast-2','ap-southeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::AssetPropertyVariant',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::AssetPropertyVariant',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::AssetPropertyVariant->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::AssetPropertyVariant {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BooleanValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DoubleValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IntegerValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StringValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::AssetPropertyTimestamp',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::AssetPropertyTimestamp',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::AssetPropertyTimestamp->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::AssetPropertyTimestamp {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has OffsetInNanos => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimeInSeconds => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Payload',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Payload',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::Payload->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::Payload {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ContentExpression => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::AssetPropertyValue',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::AssetPropertyValue',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::AssetPropertyValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::AssetPropertyValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Quality => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Timestamp => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::AssetPropertyTimestamp', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::AssetPropertyVariant', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Sqs',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Sqs',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::Sqs->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::Sqs {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Payload => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Payload', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has QueueUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::Sns->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::Sns {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Payload => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Payload', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SetVariable',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SetVariable',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::SetVariable->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::SetVariable {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VariableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SetTimer',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::SetTimer',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::SetTimer->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::SetTimer {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DurationExpression => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Seconds => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimerName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ResetTimer',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ResetTimer',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::ResetTimer->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::ResetTimer {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TimerName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Lambda',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Lambda',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::Lambda->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::Lambda {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FunctionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Payload => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Payload', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotTopicPublish',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotTopicPublish',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::IotTopicPublish->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::IotTopicPublish {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MqttTopic => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Payload => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Payload', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotSiteWise',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotSiteWise',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::IotSiteWise->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::IotSiteWise {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AssetId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EntryId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PropertyAlias => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PropertyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PropertyValue => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::AssetPropertyValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotEvents',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotEvents',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::IotEvents->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::IotEvents {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InputName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Payload => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Payload', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Firehose',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Firehose',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::Firehose->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::Firehose {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DeliveryStreamName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Payload => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Payload', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Separator => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::DynamoDBv2',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::DynamoDBv2',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::DynamoDBv2->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::DynamoDBv2 {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Payload => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Payload', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::DynamoDB',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::DynamoDB',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::DynamoDB->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::DynamoDB {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HashKeyField => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HashKeyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HashKeyValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Operation => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Payload => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Payload', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PayloadField => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RangeKeyField => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RangeKeyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RangeKeyValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ClearTimer',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ClearTimer',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::ClearTimer->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::ClearTimer {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TimerName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::Action->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::Action {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClearTimer => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::ClearTimer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DynamoDB => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::DynamoDB', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DynamoDBv2 => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::DynamoDBv2', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Firehose => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Firehose', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IotEvents => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotEvents', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IotSiteWise => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::IotSiteWise', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::TransitionEvent->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::TransitionEvent {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Actions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Action', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Condition => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EventName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has NextState => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::Event->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::Event {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Actions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::Action', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Condition => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EventName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnInput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnInput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::OnInput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::OnInput {
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
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::OnExit->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::OnExit {
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
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::OnEnter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::OnEnter {
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
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::State->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::State {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has OnEnter => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnEnter', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OnExit => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnExit', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OnInput => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::OnInput', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StateName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::DetectorModelDefinition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::DetectorModelDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::DetectorModelDefinition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTEvents::DetectorModel::DetectorModelDefinition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has InitialStateName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has States => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoTEvents::DetectorModel::State', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DetectorModelDefinition => (isa => 'Cfn::Resource::Properties::AWS::IoTEvents::DetectorModel::DetectorModelDefinition', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DetectorModelDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DetectorModelName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EvaluationMethod => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IoTEvents::DetectorModel - Cfn resource for AWS::IoTEvents::DetectorModel

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IoTEvents::DetectorModel.

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
