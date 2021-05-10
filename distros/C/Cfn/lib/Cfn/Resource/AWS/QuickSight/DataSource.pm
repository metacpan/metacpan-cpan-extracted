# AWS::QuickSight::DataSource generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::QuickSight::DataSource->new( %$_ ) };

package Cfn::Resource::AWS::QuickSight::DataSource {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','CreatedTime','LastUpdatedTime','Status' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','sa-east-1','us-east-1','us-east-2','us-gov-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::ManifestFileLocation',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::ManifestFileLocation',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::ManifestFileLocation->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::ManifestFileLocation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Bucket => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::TeradataParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::TeradataParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::TeradataParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::TeradataParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Database => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Host => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Port => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::SqlServerParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::SqlServerParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::SqlServerParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::SqlServerParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Database => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Host => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Port => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::SparkParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::SparkParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::SparkParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::SparkParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Host => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Port => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::SnowflakeParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::SnowflakeParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::SnowflakeParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::SnowflakeParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Database => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Host => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Warehouse => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::S3Parameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::S3Parameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::S3Parameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::S3Parameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ManifestFileLocation => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::ManifestFileLocation', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::RedshiftParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::RedshiftParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::RedshiftParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::RedshiftParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ClusterId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Database => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Host => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Port => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::RdsParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::RdsParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::RdsParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::RdsParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Database => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InstanceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::PrestoParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::PrestoParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::PrestoParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::PrestoParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Catalog => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Host => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Port => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::PostgreSqlParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::PostgreSqlParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::PostgreSqlParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::PostgreSqlParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Database => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Host => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Port => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::OracleParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::OracleParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::OracleParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::OracleParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Database => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Host => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Port => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::MySqlParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::MySqlParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::MySqlParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::MySqlParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Database => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Host => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Port => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::MariaDbParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::MariaDbParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::MariaDbParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::MariaDbParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Database => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Host => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Port => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::AuroraPostgreSqlParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::AuroraPostgreSqlParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::AuroraPostgreSqlParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::AuroraPostgreSqlParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Database => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Host => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Port => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::AuroraParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::AuroraParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::AuroraParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::AuroraParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Database => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Host => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Port => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::AthenaParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::AthenaParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::AthenaParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::AthenaParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has WorkGroup => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::AmazonElasticsearchParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::AmazonElasticsearchParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::AmazonElasticsearchParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::AmazonElasticsearchParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Domain => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSource::DataSourceParameters',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSource::DataSourceParameters',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::DataSource::DataSourceParameters')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::DataSourceParameters',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::DataSourceParameters',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::DataSourceParameters->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::DataSourceParameters {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AmazonElasticsearchParameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::AmazonElasticsearchParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AthenaParameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::AthenaParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AuroraParameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::AuroraParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AuroraPostgreSqlParameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::AuroraPostgreSqlParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MariaDbParameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::MariaDbParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has MySqlParameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::MySqlParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OracleParameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::OracleParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PostgreSqlParameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::PostgreSqlParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PrestoParameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::PrestoParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RdsParameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::RdsParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RedshiftParameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::RedshiftParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3Parameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::S3Parameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SnowflakeParameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::SnowflakeParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SparkParameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::SparkParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqlServerParameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::SqlServerParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TeradataParameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::TeradataParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::CredentialPair',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::CredentialPair',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::CredentialPair->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::CredentialPair {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AlternateDataSourceParameters => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSource::DataSourceParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Password => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Username => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::VpcConnectionProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::VpcConnectionProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::VpcConnectionProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::VpcConnectionProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has VpcConnectionArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::SslProperties',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::SslProperties',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::SslProperties->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::SslProperties {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DisableSsl => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSource::ResourcePermission',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSource::ResourcePermission',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::QuickSight::DataSource::ResourcePermission')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::ResourcePermission',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::ResourcePermission',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::ResourcePermission->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::ResourcePermission {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Actions => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Principal => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::DataSourceErrorInfo',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::DataSourceErrorInfo',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::DataSourceErrorInfo->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::DataSourceErrorInfo {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Message => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::DataSourceCredentials',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::DataSourceCredentials',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::DataSourceCredentials->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::QuickSight::DataSource::DataSourceCredentials {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CopySourceArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CredentialPair => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::CredentialPair', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::QuickSight::DataSource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AlternateDataSourceParameters => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSource::DataSourceParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AwsAccountId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Credentials => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::DataSourceCredentials', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DataSourceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DataSourceParameters => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::DataSourceParameters', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ErrorInfo => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::DataSourceErrorInfo', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Permissions => (isa => 'ArrayOfCfn::Resource::Properties::AWS::QuickSight::DataSource::ResourcePermission', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SslProperties => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::SslProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has VpcConnectionProperties => (isa => 'Cfn::Resource::Properties::AWS::QuickSight::DataSource::VpcConnectionProperties', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::QuickSight::DataSource - Cfn resource for AWS::QuickSight::DataSource

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::QuickSight::DataSource.

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
