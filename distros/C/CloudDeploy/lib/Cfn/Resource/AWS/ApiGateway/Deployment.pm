use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ApiGateway::Deployment',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ApiGateway::Deployment->new( %$_ ) };

package Cfn::Resource::AWS::ApiGateway::Deployment {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ApiGateway::Deployment', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::ApiGateway::Deployment {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Description => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has RestApiId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has StageDescription => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has StageName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
