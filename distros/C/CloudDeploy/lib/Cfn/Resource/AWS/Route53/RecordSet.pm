use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Route53::RecordSet',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Route53::RecordSet->new( %$_ ) };

package Cfn::Resource::AWS::Route53::RecordSet {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Route53::RecordSet', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::Route53::RecordSet {
  use Moose;
  extends 'Cfn::Resource::Properties';
  has AliasTarget => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Comment => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has HostedZoneId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has HostedZoneName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Name => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Region => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has ResourceRecords => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has SetIdentifier => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has TTL => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Type => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Weight => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
