use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CloudFront::Distribution',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CloudFront::Distribution->new( %$_ ) };

package Cfn::Resource::AWS::CloudFront::Distribution {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CloudFront::Distribution', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::CloudFront::Distribution {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has DistributionConfig => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
