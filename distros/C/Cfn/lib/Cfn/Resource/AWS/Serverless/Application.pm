use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Serverless::Application',
    from 'HashRef',
    via { Cfn::Resource::Properties::AWS::Serverless::Application->new(%$_) };

package Cfn::Resource::AWS::Serverless::Application {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => ( isa => 'Cfn::Resource::Properties::AWS::Serverless::Application', is => 'rw', coerce => 1 );

  sub supported_regions {
    require Cfn::Resource::AWS::Lambda::Function;
    Cfn::Resource::AWS::Lambda::Function->supported_regions;
  }

  sub AttributeList {
    []
  }
}

package Cfn::Resource::Properties::AWS::Serverless::Application {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';

  has Location => ( isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1 );
  has Parameters => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has NotificationArns => ( isa => 'Cfn::Value::ArrayOfPrimitives', is => 'rw', coerce => 1 );
  has Tags => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has TimeoutInMinutes => ( isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1 );
}

1;
