use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::DynamoDB::Table',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::DynamoDB::Table->new( %$_ ) };

package Cfn::Resource::AWS::DynamoDB::Table {
   use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::DynamoDB::Table', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::DynamoDB::Table  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has KeySchema => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has ProvisionedThroughput => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
