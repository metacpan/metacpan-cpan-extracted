use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::DHCPOptions',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::DHCPOptions->new( %$_ ) };

package Cfn::Resource::AWS::EC2::DHCPOptions {
   use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::DHCPOptions', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::DHCPOptions  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has DomainName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has DomainNameServers => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has NetbiosNameServers => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has NetbiosNodeType => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has NtpServers => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
