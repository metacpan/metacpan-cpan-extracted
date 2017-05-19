use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::SubnetRouteTableAssociation',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::SubnetRouteTableAssociation->new( %$_ ) };

package Cfn::Resource::AWS::EC2::SubnetRouteTableAssociation {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::SubnetRouteTableAssociation', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::SubnetRouteTableAssociation  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has RouteTableId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has SubnetId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
