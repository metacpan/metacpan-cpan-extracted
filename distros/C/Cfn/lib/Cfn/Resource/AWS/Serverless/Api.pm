use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Serverless::Api',
    from 'HashRef',
    via { Cfn::Resource::Properties::AWS::Serverless::Api->new(%$_) };

package Cfn::Resource::AWS::Serverless::Api {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => ( isa => 'Cfn::Resource::Properties::AWS::Serverless::Api', is => 'rw', coerce => 1 );

  sub supported_regions {
    require Cfn::Resource::AWS::Lambda::Function;
    Cfn::Resource::AWS::Lambda::Function->supported_regions;
  }

  sub AttributeList {
    []
  }
}

package Cfn::Resource::Properties::AWS::Serverless::Api {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';

  has Name => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has StageName => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1 );
  has DefinitionUri => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has DefinitionBody => ( isa => 'Cfn::Value::Json', is => 'rw', coerce => 1 );
  has CacheClusterEnabled => ( isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1 );
  has CacheClusterSize => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has Variables      => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has MethodSettings => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has EndpointConfiguration => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has BinaryMediaTypes => ( isa => 'Cfn::Value::ArrayOfPrimitives', is => 'rw', coerce => 1 );
  has Cors => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has Auth => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has MinimumCompressionSize => ( isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1 );
  has AccessLogSetting => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has CanarySetting  => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has TracingEnabled => ( isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1 );
}

1;
