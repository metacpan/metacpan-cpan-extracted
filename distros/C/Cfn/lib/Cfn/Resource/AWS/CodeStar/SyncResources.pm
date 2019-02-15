# AWS::CodeStar::SyncResources generated from spec 1.2.1
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CodeStar::SyncResources',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CodeStar::SyncResources->new( %$_ ) };

package Cfn::Resource::AWS::CodeStar::SyncResources {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CodeStar::SyncResources', is => 'rw', coerce => 1);
  sub _build_attributes {
    [  ]
  }
}



package Cfn::Resource::Properties::AWS::CodeStar::SyncResources {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ProjectId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
