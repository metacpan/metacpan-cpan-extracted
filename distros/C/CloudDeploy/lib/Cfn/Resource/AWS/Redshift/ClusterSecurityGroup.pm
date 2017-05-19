use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Redshift::ClusterSecurityGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Redshift::ClusterSecurityGroup->new( %$_ ) };

package Cfn::Resource::AWS::Redshift::ClusterSecurityGroup {
        use Moose;
        extends 'Cfn::Resource';
        has Properties => (isa => 'Cfn::Resource::Properties::AWS::Redshift::ClusterSecurityGroup', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::Redshift::ClusterSecurityGroup  {
        use Moose;
        use MooseX::StrictConstructor;
        extends 'Cfn::Resource::Properties';
        has Description => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;

