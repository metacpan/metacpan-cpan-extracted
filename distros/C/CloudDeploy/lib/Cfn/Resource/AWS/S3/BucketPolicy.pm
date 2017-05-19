use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::S3::BucketPolicy',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::S3::BucketPolicy->new( %$_ ) };

package Cfn::Resource::AWS::S3::BucketPolicy {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::S3::BucketPolicy', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::S3::BucketPolicy  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has PolicyDocument => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has Bucket => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
