use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Route53::AliasTarget',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Route53::AliasTarget->new( %$_ ) };

package Cfn::Resource::AWS::Route53::AliasTarget {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Route53::AliasTarget', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::Route53::AliasTarget {
  use Moose;
  extends 'Cfn::Resource::Properties';
  has HostedZoneId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has DNSName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
