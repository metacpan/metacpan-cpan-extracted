# AWS::CodeStar::SeedRepository generated from spec 1.2.1
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CodeStar::SeedRepository',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CodeStar::SeedRepository->new( %$_ ) };

package Cfn::Resource::AWS::CodeStar::SeedRepository {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CodeStar::SeedRepository', is => 'rw', coerce => 1);
  sub _build_attributes {
    [  ]
  }
}



package Cfn::Resource::Properties::AWS::CodeStar::SeedRepository {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has CodeCommitRepositoryURL => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has DefaultBranchName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has ProjectTemplateId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
