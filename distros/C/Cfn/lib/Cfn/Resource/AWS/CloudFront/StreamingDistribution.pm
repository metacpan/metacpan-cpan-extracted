# AWS::CloudFront::StreamingDistribution generated from spec 2.25.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution->new( %$_ ) };

package Cfn::Resource::AWS::CloudFront::StreamingDistribution {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'DomainName' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::TrustedSigners',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::TrustedSigners',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::TrustedSignersValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::TrustedSignersValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AwsAccountNumbers => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::S3Origin',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::S3Origin',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::S3OriginValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::S3OriginValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DomainName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OriginAccessIdentity => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::Logging',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::Logging',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::LoggingValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::LoggingValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Bucket => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Prefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::StreamingDistributionConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::StreamingDistributionConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::StreamingDistributionConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::StreamingDistributionConfigValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Aliases => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Comment => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Enabled => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Logging => (isa => 'Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::Logging', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PriceClass => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3Origin => (isa => 'Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::S3Origin', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TrustedSigners => (isa => 'Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::TrustedSigners', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has StreamingDistributionConfig => (isa => 'Cfn::Resource::Properties::AWS::CloudFront::StreamingDistribution::StreamingDistributionConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
