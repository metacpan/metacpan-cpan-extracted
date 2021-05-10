# AWS::DynamoDB::Table generated from spec 34.0.0
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
    [ 'af-south-1','ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-south-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
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
       return Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::ProvisionedThroughput->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::ProvisionedThroughput {
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
       return Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::Projection->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::Projection {
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
       return Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::KeySchema->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::KeySchema {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AttributeName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KeyType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DynamoDB::Table::ContributorInsightsSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DynamoDB::Table::ContributorInsightsSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::ContributorInsightsSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::ContributorInsightsSpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DynamoDB::Table::TimeToLiveSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DynamoDB::Table::TimeToLiveSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::TimeToLiveSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::TimeToLiveSpecification {
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
       return Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::StreamSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::StreamSpecification {
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
       return Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::SSESpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::SSESpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has KMSMasterKeyId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SSEEnabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SSEType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DynamoDB::Table::PointInTimeRecoverySpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DynamoDB::Table::PointInTimeRecoverySpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::PointInTimeRecoverySpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::PointInTimeRecoverySpecification {
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
       return Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::LocalSecondaryIndex->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::LocalSecondaryIndex {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IndexName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KeySchema => (isa => 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::KeySchema', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Projection => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::Projection', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::DynamoDB::Table::KinesisStreamSpecification',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::DynamoDB::Table::KinesisStreamSpecification',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::KinesisStreamSpecification->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::KinesisStreamSpecification {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has StreamArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::GlobalSecondaryIndex->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::GlobalSecondaryIndex {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ContributorInsightsSpecification => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::ContributorInsightsSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
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
       return Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::AttributeDefinition->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::DynamoDB::Table::AttributeDefinition {
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
  has ContributorInsightsSpecification => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::ContributorInsightsSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GlobalSecondaryIndexes => (isa => 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::GlobalSecondaryIndex', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KeySchema => (isa => 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::KeySchema', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has KinesisStreamSpecification => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::KinesisStreamSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LocalSecondaryIndexes => (isa => 'ArrayOfCfn::Resource::Properties::AWS::DynamoDB::Table::LocalSecondaryIndex', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has PointInTimeRecoverySpecification => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::PointInTimeRecoverySpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ProvisionedThroughput => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::ProvisionedThroughput', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SSESpecification => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::SSESpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StreamSpecification => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::StreamSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimeToLiveSpecification => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table::TimeToLiveSpecification', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::DynamoDB::Table - Cfn resource for AWS::DynamoDB::Table

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::DynamoDB::Table.

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
