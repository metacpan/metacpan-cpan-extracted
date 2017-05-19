use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ApiGateway::Method',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ApiGateway::Method->new( %$_ ) };

package Cfn::Resource::AWS::ApiGateway::Method {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ApiGateway::Method', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::ApiGateway::Method {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has ApiKeyRequired => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has AuthorizationType => (isa => 'Cfn::Value', is => 'rw', coerce => 1); #Required: Yes. If you specify the AuthorizerId property, specify CUSTOM for this property.
  has AuthorizerId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has HttpMethod => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Integration => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has MethodResponses => (isa =>  'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has RequestModels => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has RequestParameters => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has ResourceId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has RestApiId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
