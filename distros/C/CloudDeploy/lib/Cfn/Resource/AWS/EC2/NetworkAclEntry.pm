use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::NetworkAclEntry',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::NetworkAclEntry->new( %$_ ) };

package Cfn::Resource::AWS::EC2::NetworkAclEntry {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::NetworkAclEntry', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::NetworkAclEntry  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has CidrBlock => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Egress => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Icmp => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has NetworkAclId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has PortRange => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Protocol => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has RuleAction => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has RuleNumber => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
