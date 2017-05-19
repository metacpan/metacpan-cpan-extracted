use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ApiGateway::Stage',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ApiGateway::Stage->new( %$_ ) };

package Cfn::Resource::AWS::ApiGateway::Stage {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ApiGateway::Stage', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::ApiGateway::Stage {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has CacheClusterEnabled => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has CacheClusterSize => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has ClientCertificateId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has DeploymentId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Description => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has MethodSettings => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has RestApiId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has StageName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Variables => (isa => 'Cfn::Value', is => 'rw', coerce => 1);

}

1;
