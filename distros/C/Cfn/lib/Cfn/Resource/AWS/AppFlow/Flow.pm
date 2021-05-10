# AWS::AppFlow::Flow generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::AppFlow::Flow->new( %$_ ) };

package Cfn::Resource::AWS::AppFlow::Flow {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'FlowArn' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::PrefixConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::PrefixConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::PrefixConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::PrefixConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PrefixFormat => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PrefixType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::AggregationConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::AggregationConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::AggregationConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::AggregationConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AggregationType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::UpsolverS3OutputFormatConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::UpsolverS3OutputFormatConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::UpsolverS3OutputFormatConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::UpsolverS3OutputFormatConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AggregationConfig => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::AggregationConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FileType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PrefixConfig => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::PrefixConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::S3OutputFormatConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::S3OutputFormatConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::S3OutputFormatConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::S3OutputFormatConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AggregationConfig => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::AggregationConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FileType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PrefixConfig => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::PrefixConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::IdFieldNamesList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::IdFieldNamesList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::IdFieldNamesList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::IdFieldNamesList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IdFieldNamesList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ErrorHandlingConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ErrorHandlingConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::ErrorHandlingConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::ErrorHandlingConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BucketName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BucketPrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FailOnFirstError => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ZendeskSourceProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ZendeskSourceProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::ZendeskSourceProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::ZendeskSourceProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::VeevaSourceProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::VeevaSourceProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::VeevaSourceProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::VeevaSourceProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::UpsolverDestinationProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::UpsolverDestinationProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::UpsolverDestinationProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::UpsolverDestinationProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BucketName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BucketPrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3OutputFormatConfig => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::UpsolverS3OutputFormatConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::TrendmicroSourceProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::TrendmicroSourceProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::TrendmicroSourceProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::TrendmicroSourceProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SnowflakeDestinationProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SnowflakeDestinationProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::SnowflakeDestinationProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::SnowflakeDestinationProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BucketPrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ErrorHandlingConfig => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ErrorHandlingConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IntermediateBucketName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SlackSourceProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SlackSourceProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::SlackSourceProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::SlackSourceProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SingularSourceProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SingularSourceProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::SingularSourceProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::SingularSourceProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ServiceNowSourceProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ServiceNowSourceProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::ServiceNowSourceProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::ServiceNowSourceProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SalesforceSourceProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SalesforceSourceProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::SalesforceSourceProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::SalesforceSourceProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EnableDynamicFieldUpdate => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeDeletedRecords => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SalesforceDestinationProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SalesforceDestinationProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::SalesforceDestinationProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::SalesforceDestinationProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ErrorHandlingConfig => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ErrorHandlingConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IdFieldNames => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::IdFieldNamesList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has WriteOperationType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::S3SourceProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::S3SourceProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::S3SourceProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::S3SourceProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BucketName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BucketPrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::S3DestinationProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::S3DestinationProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::S3DestinationProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::S3DestinationProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BucketName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BucketPrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3OutputFormatConfig => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::S3OutputFormatConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::RedshiftDestinationProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::RedshiftDestinationProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::RedshiftDestinationProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::RedshiftDestinationProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BucketPrefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ErrorHandlingConfig => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ErrorHandlingConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IntermediateBucketName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::MarketoSourceProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::MarketoSourceProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::MarketoSourceProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::MarketoSourceProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::LookoutMetricsDestinationProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::LookoutMetricsDestinationProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::LookoutMetricsDestinationProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::LookoutMetricsDestinationProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::InforNexusSourceProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::InforNexusSourceProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::InforNexusSourceProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::InforNexusSourceProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::GoogleAnalyticsSourceProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::GoogleAnalyticsSourceProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::GoogleAnalyticsSourceProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::GoogleAnalyticsSourceProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::EventBridgeDestinationProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::EventBridgeDestinationProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::EventBridgeDestinationProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::EventBridgeDestinationProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ErrorHandlingConfig => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ErrorHandlingConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::DynatraceSourceProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::DynatraceSourceProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::DynatraceSourceProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::DynatraceSourceProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::DatadogSourceProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::DatadogSourceProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::DatadogSourceProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::DatadogSourceProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::AmplitudeSourceProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::AmplitudeSourceProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::AmplitudeSourceProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::AmplitudeSourceProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Object => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::AppFlow::Flow::TaskPropertiesObject',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::AppFlow::Flow::TaskPropertiesObject',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::AppFlow::Flow::TaskPropertiesObject')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::TaskPropertiesObject',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::TaskPropertiesObject',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::TaskPropertiesObject->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::TaskPropertiesObject {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Value => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SourceConnectorProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SourceConnectorProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::SourceConnectorProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::SourceConnectorProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Amplitude => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::AmplitudeSourceProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Datadog => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::DatadogSourceProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Dynatrace => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::DynatraceSourceProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GoogleAnalytics => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::GoogleAnalyticsSourceProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InforNexus => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::InforNexusSourceProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Marketo => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::MarketoSourceProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3 => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::S3SourceProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Salesforce => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SalesforceSourceProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceNow => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ServiceNowSourceProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Singular => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SingularSourceProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Slack => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SlackSourceProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Trendmicro => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::TrendmicroSourceProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Veeva => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::VeevaSourceProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Zendesk => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ZendeskSourceProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ScheduledTriggerProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ScheduledTriggerProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::ScheduledTriggerProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::ScheduledTriggerProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataPullMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScheduleEndTime => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScheduleExpression => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScheduleStartTime => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TimeZone => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::IncrementalPullConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::IncrementalPullConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::IncrementalPullConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::IncrementalPullConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DatetimeTypeFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::DestinationConnectorProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::DestinationConnectorProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::DestinationConnectorProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::DestinationConnectorProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has EventBridge => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::EventBridgeDestinationProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has LookoutMetrics => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::LookoutMetricsDestinationProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Redshift => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::RedshiftDestinationProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3 => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::S3DestinationProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Salesforce => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SalesforceDestinationProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Snowflake => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SnowflakeDestinationProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Upsolver => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::UpsolverDestinationProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ConnectorOperator',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ConnectorOperator',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::ConnectorOperator->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::ConnectorOperator {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Amplitude => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Datadog => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Dynatrace => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GoogleAnalytics => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InforNexus => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Marketo => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3 => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Salesforce => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceNow => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Singular => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Slack => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Trendmicro => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Veeva => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Zendesk => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::TriggerConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::TriggerConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::TriggerConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::TriggerConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has TriggerProperties => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ScheduledTriggerProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TriggerType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::AppFlow::Flow::Task',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::AppFlow::Flow::Task',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::AppFlow::Flow::Task')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::Task',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::Task',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::Task->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::Task {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConnectorOperator => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::ConnectorOperator', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DestinationField => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourceFields => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TaskProperties => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AppFlow::Flow::TaskPropertiesObject', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TaskType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SourceFlowConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SourceFlowConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::SourceFlowConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::SourceFlowConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConnectorProfileName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectorType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncrementalPullConfig => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::IncrementalPullConfig', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SourceConnectorProperties => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SourceConnectorProperties', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::AppFlow::Flow::DestinationFlowConfig',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::AppFlow::Flow::DestinationFlowConfig',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::AppFlow::Flow::DestinationFlowConfig')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::AppFlow::Flow::DestinationFlowConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::AppFlow::Flow::DestinationFlowConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::DestinationFlowConfig->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::AppFlow::Flow::DestinationFlowConfig {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConnectorProfileName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectorType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DestinationConnectorProperties => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::DestinationConnectorProperties', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::AppFlow::Flow {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DestinationFlowConfigList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AppFlow::Flow::DestinationFlowConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FlowName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has KMSArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SourceFlowConfig => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::SourceFlowConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tasks => (isa => 'ArrayOfCfn::Resource::Properties::AWS::AppFlow::Flow::Task', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TriggerConfig => (isa => 'Cfn::Resource::Properties::AWS::AppFlow::Flow::TriggerConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::AppFlow::Flow - Cfn resource for AWS::AppFlow::Flow

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::AppFlow::Flow.

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
