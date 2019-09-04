# AWS::DynamoDB::Table generated from spec 5.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::DynamoDB::Table',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::DynamoDB::Table->new( %$_ ) };

package Cfn::Resource::AWS::DynamoDB::Table {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','StreamArn' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::DynamoDB::Table::ProvisionedThroughput',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DynamoDB::Table::ProvisionedThroughput',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::DynamoDB::Table::ProvisionedThroughputValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::DynamoDB::Table::ProvisionedThroughputValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ReadCapacityUnits => (isa => 'Cfn::Value::Long', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WriteCapacityUnits => (isa => 'Cfn::Value::Long', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DynamoDB::Table::Projection',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DynamoDB::Table::Projection',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::DynamoDB::Table::ProjectionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::DynamoDB::Table::ProjectionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has NonKeyAttributes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProjectionType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::KeySchema',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::KeySchema',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::DynamoDB::Table::KeySchema')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::DynamoDB::Table::KeySchema',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DynamoDB::Table::KeySchema',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::DynamoDB::Table::KeySchemaValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::DynamoDB::Table::KeySchemaValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AttributeName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KeyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DynamoDB::Table::TimeToLiveSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DynamoDB::Table::TimeToLiveSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::DynamoDB::Table::TimeToLiveSpecificationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::DynamoDB::Table::TimeToLiveSpecificationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AttributeName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DynamoDB::Table::StreamSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DynamoDB::Table::StreamSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::DynamoDB::Table::StreamSpecificationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::DynamoDB::Table::StreamSpecificationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has StreamViewType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DynamoDB::Table::SSESpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DynamoDB::Table::SSESpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::DynamoDB::Table::SSESpecificationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::DynamoDB::Table::SSESpecificationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SSEEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DynamoDB::Table::PointInTimeRecoverySpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DynamoDB::Table::PointInTimeRecoverySpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::DynamoDB::Table::PointInTimeRecoverySpecificationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::DynamoDB::Table::PointInTimeRecoverySpecificationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PointInTimeRecoveryEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::LocalSecondaryIndex',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::LocalSecondaryIndex',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::DynamoDB::Table::LocalSecondaryIndex')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::DynamoDB::Table::LocalSecondaryIndex',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DynamoDB::Table::LocalSecondaryIndex',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::DynamoDB::Table::LocalSecondaryIndexValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::DynamoDB::Table::LocalSecondaryIndexValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IndexName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KeySchema => (isa => 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::KeySchema', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Projection => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::Projection', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::GlobalSecondaryIndex',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::GlobalSecondaryIndex',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::DynamoDB::Table::GlobalSecondaryIndex')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::DynamoDB::Table::GlobalSecondaryIndex',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DynamoDB::Table::GlobalSecondaryIndex',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::DynamoDB::Table::GlobalSecondaryIndexValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::DynamoDB::Table::GlobalSecondaryIndexValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IndexName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KeySchema => (isa => 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::KeySchema', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Projection => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::Projection', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProvisionedThroughput => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::ProvisionedThroughput', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::AttributeDefinition',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::AttributeDefinition',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::DynamoDB::Table::AttributeDefinition')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::DynamoDB::Table::AttributeDefinition',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DynamoDB::Table::AttributeDefinition',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::DynamoDB::Table::AttributeDefinitionValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::DynamoDB::Table::AttributeDefinitionValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AttributeName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AttributeType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::DynamoDB::Table {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AttributeDefinitions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::AttributeDefinition', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Conditional');
  has BillingMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GlobalSecondaryIndexes => (isa => 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::GlobalSecondaryIndex', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KeySchema => (isa => 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::KeySchema', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has LocalSecondaryIndexes => (isa => 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::LocalSecondaryIndex', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has PointInTimeRecoverySpecification => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::PointInTimeRecoverySpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProvisionedThroughput => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::ProvisionedThroughput', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SSESpecification => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::SSESpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Conditional');
  has StreamSpecification => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::StreamSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimeToLiveSpecification => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::TimeToLiveSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
