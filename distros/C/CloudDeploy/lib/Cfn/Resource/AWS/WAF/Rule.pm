use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::WAF::Rule',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::WAF::Rule->new( %$_ ) };

package Cfn::Resource::AWS::WAF::Rule {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::WAF::Rule', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::WAF::Rule {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Predicates => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Name => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has MetricName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
