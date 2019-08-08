# AWS::CodeStar::GitHubRepository generated from spec 5.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CodeStar::GitHubRepository',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CodeStar::GitHubRepository->new( %$_ ) };

package Cfn::Resource::AWS::CodeStar::GitHubRepository {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CodeStar::GitHubRepository', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3','sa-east-1','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::CodeStar::GitHubRepository::S3',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CodeStar::GitHubRepository::S3',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::CodeStar::GitHubRepository::S3Value->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::CodeStar::GitHubRepository::S3Value {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Bucket => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ObjectVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::CodeStar::GitHubRepository::Code',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::CodeStar::GitHubRepository::Code',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::CodeStar::GitHubRepository::CodeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::CodeStar::GitHubRepository::CodeValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3 => (isa => 'Cfn::Resource::Properties::AWS::CodeStar::GitHubRepository::S3', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::CodeStar::GitHubRepository {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Code => (isa => 'Cfn::Resource::Properties::AWS::CodeStar::GitHubRepository::Code', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EnableIssues => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IsPrivate => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RepositoryAccessToken => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RepositoryDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RepositoryName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RepositoryOwner => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
