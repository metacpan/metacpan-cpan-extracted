use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::WAF::WebACL',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::WAF::WebACL->new( %$_ ) };

package Cfn::Resource::AWS::WAF::WebACL {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::WAF::WebACL', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::WAF::WebACL {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has DefaultAction => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has MetricName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Name => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Rules => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
