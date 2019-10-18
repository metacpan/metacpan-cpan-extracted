# AWS::QLDB::Ledger generated from spec 6.1.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::QLDB::Ledger',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::QLDB::Ledger->new( %$_ ) };

package Cfn::Resource::AWS::QLDB::Ledger {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::QLDB::Ledger', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','eu-west-1','us-east-1','us-east-2','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::QLDB::Ledger {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DeletionProtection => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has PermissionsMode => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
