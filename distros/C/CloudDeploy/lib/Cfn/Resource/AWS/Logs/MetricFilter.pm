use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Logs::MetricFilter',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Logs::MetricFilter->new( %$_ ) };

package Cfn::Resource::AWS::Logs::MetricFilter {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Logs::MetricFilter', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::Logs::MetricFilter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has FilterPattern => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has LogGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has MetricTransformations => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;
