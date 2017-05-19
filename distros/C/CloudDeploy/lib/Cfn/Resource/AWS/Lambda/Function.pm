use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Lambda::Function',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Lambda::Function->new( %$_ ) };

package Cfn::Resource::AWS::Lambda::Function {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Lambda::Function', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::Lambda::Function {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has Code => (isa => 'Cfn::Value|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Description => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has FunctionName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Handler => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has MemorySize => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Role => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Runtime => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Timeout => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has VpcConfig => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
