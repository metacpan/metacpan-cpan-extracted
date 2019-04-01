use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Serverless::SimpleTable',
    from 'HashRef',
    via { Cfn::Resource::Properties::AWS::Serverless::SimpleTable->new(%$_) };

package Cfn::Resource::AWS::Serverless::SimpleTable {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => ( isa => 'Cfn::Resource::Properties::AWS::Serverless::SimpleTable', is => 'rw', coerce => 1 );

  sub supported_regions {
    require Cfn::Resource::AWS::Lambda::Function;
    Cfn::Resource::AWS::Lambda::Function->supported_regions;
  }

  sub AttributeList {
    []
  }
}

package Cfn::Resource::Properties::AWS::Serverless::SimpleTable {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';

  has PrimaryKey => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has ProvisionedThroughput => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has Tags      => ( isa => 'Cfn::Value',         is => 'rw', coerce => 1 );
  has TableName => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has SSESpecification => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
}

1;
