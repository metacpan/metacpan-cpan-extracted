use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::WAF::XssMatchSet',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::WAF::XssMatchSet->new( %$_ ) };

package Cfn::Resource::AWS::WAF::XssMatchSet {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::WAF::XssMatchSet', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::WAF::XssMatchSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Name => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has XssMatchTuples => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
