use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::InternetGateway',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::InternetGateway->new( %$_ ) };

package Cfn::Resource::AWS::EC2::InternetGateway {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::InternetGateway', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::InternetGateway  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
