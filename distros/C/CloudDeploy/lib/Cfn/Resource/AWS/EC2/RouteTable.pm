use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::RouteTable',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::RouteTable->new( %$_ ) };

package Cfn::Resource::AWS::EC2::RouteTable {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::RouteTable', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::RouteTable  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has VpcId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
