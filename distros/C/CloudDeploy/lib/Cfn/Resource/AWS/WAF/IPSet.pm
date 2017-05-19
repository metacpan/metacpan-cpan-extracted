use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::WAF::IPSet',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::WAF::IPSet->new( %$_ ) };

package Cfn::Resource::AWS::WAF::IPSet {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::WAF::IPSet', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::WAF::IPSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has IPSetDescriptors => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Name => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
