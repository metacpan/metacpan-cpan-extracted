# AWS::SageMaker::CodeRepository generated from spec 6.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SageMaker::CodeRepository',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SageMaker::CodeRepository->new( %$_ ) };

package Cfn::Resource::AWS::SageMaker::CodeRepository {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::CodeRepository', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'CodeRepositoryName' ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::SageMaker::CodeRepository::GitConfig',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SageMaker::CodeRepository::GitConfig',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::SageMaker::CodeRepository::GitConfigValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::SageMaker::CodeRepository::GitConfigValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Branch => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has RepositoryUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SecretArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::SageMaker::CodeRepository {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has CodeRepositoryName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has GitConfig => (isa => 'Cfn::Resource::Properties::AWS::SageMaker::CodeRepository::GitConfig', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
