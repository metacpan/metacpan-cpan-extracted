use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::WAF::ByteMatchSet',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::WAF::ByteMatchSet->new( %$_ ) };

package Cfn::Resource::AWS::WAF::ByteMatchSet {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::WAF::ByteMatchSet', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::WAF::ByteMatchSet {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has ByteMatchTuples => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Name => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
