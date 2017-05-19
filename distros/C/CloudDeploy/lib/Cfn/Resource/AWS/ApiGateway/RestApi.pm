use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ApiGateway::RestApi',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::ApiGateway::RestApi->new( %$_ ) };

package Cfn::Resource::AWS::ApiGateway::RestApi {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ApiGateway::RestApi', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::ApiGateway::RestApi {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Body => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has BodyS3Location => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has CloneFrom => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Description => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has FailOnWarnings => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Name => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Parameters => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
