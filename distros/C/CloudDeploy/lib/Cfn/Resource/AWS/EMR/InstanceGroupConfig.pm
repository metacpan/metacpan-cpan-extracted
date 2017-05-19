use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig->new( %$_ ) };

package Cfn::Resource::AWS::EMR::InstanceGroupConfig {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EMR::InstanceGroupConfig  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has BidPrice => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Configurations => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has EbsConfigurations => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has InstanceCount => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has InstanceRole => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has InstanceType => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has JobFlowId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1); 
  has Market => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Name => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
