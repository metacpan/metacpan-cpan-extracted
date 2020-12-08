use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Serverless::Function',
    from 'HashRef',
    via { Cfn::Resource::Properties::AWS::Serverless::Function->new(%$_) };

package Cfn::Resource::AWS::Serverless::Function {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => ( isa => 'Cfn::Resource::Properties::AWS::Serverless::Function', is => 'rw', coerce => 1 );

  sub supported_regions {
    require Cfn::Resource::AWS::Lambda::Function;
    Cfn::Resource::AWS::Lambda::Function->supported_regions;
  }

  sub AttributeList {
    ['Arn']
  }
}

package Cfn::Resource::Properties::AWS::Serverless::Function {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';

  has Handler => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1 );
  has Runtime => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1 );
  has CodeUri    => ( isa => 'Cfn::Value',         is => 'rw', coerce => 1 );
  has InlineCode => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has FunctionName => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has Description => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has MemorySize => ( isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1 );
  has Timeout    => ( isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1 );
  has Role       => ( isa => 'Cfn::Value::String',  is => 'rw', coerce => 1 );
  has Policies   => ( isa => 'Cfn::Value',          is => 'rw', coerce => 1 );
  has Environment => ( isa => 'Cfn::Value',         is => 'rw', coerce => 1 );
  has VpcConfig   => ( isa => 'Cfn::Value',         is => 'rw', coerce => 1 );
  has Events      => ( isa => 'Cfn::Value',         is => 'rw', coerce => 1 );
  has Tags        => ( isa => 'Cfn::Value',         is => 'rw', coerce => 1 );
  has Tracing     => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has KmsKeyArn   => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has DeadLetterQueue => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has DeploymentPreference => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has Layers => ( isa => 'Cfn::Value::ArrayOfPrimitives', is => 'rw', coerce => 1 );
  has AutoPublishAlias => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has ReservedConcurrentExecutions => ( isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1 );
  has AssumeRolePolicyDocument => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has AutoPublishCodeSha256 => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has EventInvokeConfig => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has PermissionsBoundary => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
  has ProvisionedConcurrencyConfig => ( isa => 'Cfn::Value', is => 'rw', coerce => 1 );
  has VersionDescription => ( isa => 'Cfn::Value::String', is => 'rw', coerce => 1 );
}

1;
