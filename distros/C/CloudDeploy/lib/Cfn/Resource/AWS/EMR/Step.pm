use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EMR::Step',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EMR::Step->new( %$_ ) };

package Cfn::Resource::AWS::EMR::Step {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EMR::Step', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EMR::Step  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has ActionOnFailure => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has HadoopJarStep => (isa => 'Cfn::Value|Cfn::Value::Function', is => 'rw', coerce => 1, required => 1);
  has JobFlowId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Name => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
