# AWS::WAFRegional::WebACLAssociation generated from spec 5.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::WAFRegional::WebACLAssociation',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::WAFRegional::WebACLAssociation->new( %$_ ) };

package Cfn::Resource::AWS::WAFRegional::WebACLAssociation {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::WAFRegional::WebACLAssociation', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-southeast-1','ap-southeast-2','eu-central-1','eu-north-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-1','us-west-2' ]
  }
}



package Cfn::Resource::Properties::AWS::WAFRegional::WebACLAssociation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has ResourceArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has WebACLId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
