# AWS::IoT::TopicRule generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoT::TopicRule->new( %$_ ) };

package Cfn::Resource::AWS::IoT::TopicRule {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn' ]
  }
  sub supported_regions {
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::AssetPropertyVariant',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::AssetPropertyVariant',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::AssetPropertyVariant->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::AssetPropertyVariant {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BooleanValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DoubleValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IntegerValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StringValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::AssetPropertyTimestamp',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::AssetPropertyTimestamp',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::AssetPropertyTimestamp->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::AssetPropertyTimestamp {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has OffsetInNanos => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimeInSeconds => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoT::TopicRule::TimestreamDimension',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoT::TopicRule::TimestreamDimension',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoT::TopicRule::TimestreamDimension')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::TimestreamDimension',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::TimestreamDimension',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::TimestreamDimension->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::TimestreamDimension {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::SigV4Authorization',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::SigV4Authorization',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::SigV4Authorization->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::SigV4Authorization {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SigningRegion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoT::TopicRule::AssetPropertyValue',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoT::TopicRule::AssetPropertyValue',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoT::TopicRule::AssetPropertyValue')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::AssetPropertyValue',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::AssetPropertyValue',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::AssetPropertyValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::AssetPropertyValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Quality => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Timestamp => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::AssetPropertyTimestamp', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::AssetPropertyVariant', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::TimestreamTimestamp',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::TimestreamTimestamp',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::TimestreamTimestamp->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::TimestreamTimestamp {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Unit => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::TimestreamDimensionsList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::TimestreamDimensionsList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::TimestreamDimensionsList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::TimestreamDimensionsList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TimestreamDimensionsList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoT::TopicRule::TimestreamDimension', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::PutItemInput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::PutItemInput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::PutItemInput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::PutItemInput {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoT::TopicRule::PutAssetPropertyValueEntry',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoT::TopicRule::PutAssetPropertyValueEntry',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoT::TopicRule::PutAssetPropertyValueEntry')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::PutAssetPropertyValueEntry',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::PutAssetPropertyValueEntry',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::PutAssetPropertyValueEntry->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::PutAssetPropertyValueEntry {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AssetId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EntryId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PropertyAlias => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PropertyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PropertyValues => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoT::TopicRule::AssetPropertyValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::HttpAuthorization',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::HttpAuthorization',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::HttpAuthorization->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::HttpAuthorization {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Sigv4 => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::SigV4Authorization', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoT::TopicRule::HttpActionHeader',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoT::TopicRule::HttpActionHeader',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoT::TopicRule::HttpActionHeader')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::HttpActionHeader',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::HttpActionHeader',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::HttpActionHeader->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::HttpActionHeader {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::TimestreamAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::TimestreamAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::TimestreamAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::TimestreamAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DatabaseName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Dimensions => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::TimestreamDimensionsList', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Timestamp => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::TimestreamTimestamp', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::StepFunctionsAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::StepFunctionsAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::StepFunctionsAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::StepFunctionsAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ExecutionNamePrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StateMachineName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::SqsAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::SqsAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::SqsAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::SqsAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has QueueUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UseBase64 => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::SnsAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::SnsAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::SnsAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::SnsAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MessageFormat => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TargetArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::S3Action',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::S3Action',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::S3Action->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::S3Action {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BucketName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CannedAcl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::RepublishAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::RepublishAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::RepublishAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::RepublishAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Qos => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Topic => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::LambdaAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::LambdaAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::LambdaAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::LambdaAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has FunctionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::KinesisAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::KinesisAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::KinesisAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::KinesisAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PartitionKey => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StreamName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::KafkaAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::KafkaAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::KafkaAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::KafkaAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClientProperties => (isa => 'Cfn::Value::Hash|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DestinationArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Partition => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Topic => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::IotSiteWiseAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::IotSiteWiseAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::IotSiteWiseAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::IotSiteWiseAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PutAssetPropertyValueEntries => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoT::TopicRule::PutAssetPropertyValueEntry', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::IotEventsAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::IotEventsAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::IotEventsAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::IotEventsAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BatchMode => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InputName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MessageId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::IotAnalyticsAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::IotAnalyticsAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::IotAnalyticsAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::IotAnalyticsAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BatchMode => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ChannelName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::HttpAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::HttpAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::HttpAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::HttpAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Auth => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::HttpAuthorization', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConfirmationUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Headers => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoT::TopicRule::HttpActionHeader', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Url => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::FirehoseAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::FirehoseAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::FirehoseAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::FirehoseAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BatchMode => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DeliveryStreamName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Separator => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::ElasticsearchAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::ElasticsearchAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::ElasticsearchAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::ElasticsearchAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Endpoint => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Index => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::DynamoDBv2Action',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::DynamoDBv2Action',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::DynamoDBv2Action->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::DynamoDBv2Action {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PutItem => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::PutItemInput', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::DynamoDBAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::DynamoDBAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::DynamoDBAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::DynamoDBAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HashKeyField => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HashKeyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has HashKeyValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PayloadField => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RangeKeyField => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RangeKeyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RangeKeyValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::CloudwatchMetricAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::CloudwatchMetricAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::CloudwatchMetricAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::CloudwatchMetricAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has MetricName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricNamespace => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricTimestamp => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricUnit => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MetricValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::CloudwatchLogsAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::CloudwatchLogsAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::CloudwatchLogsAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::CloudwatchLogsAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has LogGroupName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::CloudwatchAlarmAction',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::CloudwatchAlarmAction',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::CloudwatchAlarmAction->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::CloudwatchAlarmAction {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AlarmName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StateReason => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StateValue => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::IoT::TopicRule::Action',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::IoT::TopicRule::Action',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::IoT::TopicRule::Action')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::Action',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::Action',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::Action->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::Action {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CloudwatchAlarm => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::CloudwatchAlarmAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CloudwatchLogs => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::CloudwatchLogsAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CloudwatchMetric => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::CloudwatchMetricAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DynamoDB => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::DynamoDBAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DynamoDBv2 => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::DynamoDBv2Action', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Elasticsearch => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::ElasticsearchAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Firehose => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::FirehoseAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Http => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::HttpAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IotAnalytics => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::IotAnalyticsAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IotEvents => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::IotEventsAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IotSiteWise => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::IotSiteWiseAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Kafka => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::KafkaAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Kinesis => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::KinesisAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Lambda => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::LambdaAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Republish => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::RepublishAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3 => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::S3Action', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Sns => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::SnsAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Sqs => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::SqsAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StepFunctions => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::StepFunctionsAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Timestream => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::TimestreamAction', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoT::TopicRule::TopicRulePayload',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoT::TopicRule::TopicRulePayload',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::TopicRulePayload->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoT::TopicRule::TopicRulePayload {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Actions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::IoT::TopicRule::Action', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AwsIotSqlVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ErrorAction => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::Action', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RuleDisabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Sql => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::IoT::TopicRule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has RuleName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TopicRulePayload => (isa => 'Cfn::Resource::Properties::AWS::IoT::TopicRule::TopicRulePayload', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IoT::TopicRule - Cfn resource for AWS::IoT::TopicRule

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IoT::TopicRule.

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
