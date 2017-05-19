use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::WAF::SqlInjectionMatchSet',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::WAF::SqlInjectionMatchSet->new( %$_ ) };

package Cfn::Resource::AWS::WAF::SqlInjectionMatchSet {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::WAF::SqlInjectionMatchSet', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::WAF::SqlInjectionMatchSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has SqlInjectionMatchTuples => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Name => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
