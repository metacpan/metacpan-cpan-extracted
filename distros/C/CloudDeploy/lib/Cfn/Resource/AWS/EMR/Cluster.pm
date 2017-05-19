use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EMR::Cluster',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EMR::Cluster->new( %$_ ) };

package Cfn::Resource::AWS::EMR::Cluster {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EMR::Cluster', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EMR::Cluster  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  #has AdditionalInfo => #JSON OBJECT -> probably just a big string??
  has AdditionalInfo => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Applications => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has BootstrapActions => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Configurations => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Instances => (isa => 'Cfn::Value|Cfn::Value::Function', is => 'rw', coerce => 1, required => 1);
  has JobFlowRole => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has LogUri => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Name => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has ReleaseLabel => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has ServiceRole => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has VisibleToAllUsers => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
