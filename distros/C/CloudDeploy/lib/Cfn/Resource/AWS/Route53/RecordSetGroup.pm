use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Route53::RecordSetGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Route53::RecordSetGroup->new( %$_ ) };

package Cfn::Resource::AWS::Route53::RecordSetGroup {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Route53::RecordSetGroup', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::Route53::RecordSetGroup {
  use Moose;
  extends 'Cfn::Resource::Properties';
  has HostedZoneId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has HostedZoneName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has RecordSets => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1, required => 1);
  has Comment => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
