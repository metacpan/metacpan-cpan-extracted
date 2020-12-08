use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Serverless::HttpApi',
    from 'HashRef',
    via { Cfn::Resource::Properties::AWS::Serverless::HttpApi->new(%$_) };

package Cfn::Resource::AWS::Serverless::HttpApi {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => ( isa => 'Cfn::Resource::Properties::AWS::Serverless::HttpApi', is => 'rw', coerce => 1 );

  sub supported_regions {
    require Cfn::Resource::AWS::Lambda::Function;
    Cfn::Resource::AWS::Lambda::Function->supported_regions;
  }

  sub AttributeList {
    []
  }
}

package Cfn::Resource::Properties::AWS::Serverless::HttpApi {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';

  has AccessLogSettings => ( isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Auth => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has CorsConfiguration => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has DefaultRouteSettings => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has DefinitionBody => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has DefinitionUri => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has Domain => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has FailOnWarnings => ( isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1 );
  has RouteSettings => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has StageName => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has StageVariables => ( isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Tags => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
}

1;
