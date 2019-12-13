# AWS::Lambda::Version generated from spec 9.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Lambda::Version',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Lambda::Version->new( %$_ ) };

package Cfn::Resource::AWS::Lambda::Version {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Lambda::Version', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Version' ]
  }
  sub supported_regions {
    [ 'ap-east-1','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','cn-north-1','cn-northwest-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','me-south-1','sa-east-1','us-east-1','us-east-2','us-gov-east-1','us-gov-west-1','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::Lambda::Version::ProvisionedConcurrencyConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Lambda::Version::ProvisionedConcurrencyConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Lambda::Version::ProvisionedConcurrencyConfigurationValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Lambda::Version::ProvisionedConcurrencyConfigurationValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ProvisionedConcurrentExecutions => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Lambda::Version {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has CodeSha256 => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FunctionName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ProvisionedConcurrencyConfig => (isa => 'Cfn::Resource::Properties::AWS::Lambda::Version::ProvisionedConcurrencyConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
