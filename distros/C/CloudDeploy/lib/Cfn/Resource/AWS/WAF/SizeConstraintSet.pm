use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::WAF::SizeConstraintSet',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::WAF::SizeConstraintSet->new( %$_ ) };

package Cfn::Resource::AWS::WAF::SizeConstraintSet {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::WAF::SizeConstraintSet', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::WAF::SizeConstraintSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Name => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has SizeConstraints => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, required => 1);
}

1;
