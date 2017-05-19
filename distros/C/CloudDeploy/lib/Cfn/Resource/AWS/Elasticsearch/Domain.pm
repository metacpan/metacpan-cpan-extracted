use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Elasticsearch::Domain->new( %$_ ) };

package Cfn::Resource::AWS::Elasticsearch::Domain {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Elasticsearch::Domain', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::Elasticsearch::Domain {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has AccessPolicies => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has AdvancedOptions => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has DomainName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has EBSOptions => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has ElasticsearchClusterConfig => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has SnapshotOptions => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Tags => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
