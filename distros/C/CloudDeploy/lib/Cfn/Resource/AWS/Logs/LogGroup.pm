use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Logs::LogGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Logs::LogGroup->new( %$_ ) };

package Cfn::Resource::AWS::Logs::LogGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Logs::LogGroup', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::Logs::LogGroup {
  use Moose;
  extends 'Cfn::Resource::Properties';
  has RetentionInDays => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has LogGroupName => (isa => 'Cfn::Value', is => 'ro', coerce => 1);
}

1;
