use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Redshift::ClusterSecurityGroupIngress',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Redshift::ClusterSecurityGroupIngress->new( %$_ ) };

package Cfn::Resource::AWS::Redshift::ClusterSecurityGroupIngress {
        use Moose;
        extends 'Cfn::Resource';
        has Properties => (isa => 'Cfn::Resource::Properties::AWS::Redshift::ClusterSecurityGroupIngress', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::Redshift::ClusterSecurityGroupIngress  {
        use Moose;
        use MooseX::StrictConstructor;
        extends 'Cfn::Resource::Properties';
        has ClusterSecurityGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
        has CIDRIP => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has EC2SecurityGroupName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has EC2SecurityGroupOwnerId => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;

