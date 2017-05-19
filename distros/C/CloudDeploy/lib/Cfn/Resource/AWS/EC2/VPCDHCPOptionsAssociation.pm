use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::VPCDHCPOptionsAssociation',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::VPCDHCPOptionsAssociation->new( %$_ ) };

package Cfn::Resource::AWS::EC2::VPCDHCPOptionsAssociation {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::VPCDHCPOptionsAssociation', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::VPCDHCPOptionsAssociation  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has DhcpOptionsId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has VpcId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
