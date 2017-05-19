use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::ECS::Cluster',
  from 'HashRef',
  via { Cfn::Resource::Properties::AWS::ECS::Cluster->new( %$_ ) };

package Cfn::Resource::AWS::ECS::Cluster {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ECS::Cluster', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::ECS::Cluster  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
}

1;
