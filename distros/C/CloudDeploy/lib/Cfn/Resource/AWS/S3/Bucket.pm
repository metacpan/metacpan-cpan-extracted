use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::S3::Bucket',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::S3::Bucket->new( %$_ ) };

package Cfn::Resource::AWS::S3::Bucket {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::S3::Bucket', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::S3::Bucket  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has AccessControl => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has WebsiteConfiguration => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has BucketName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
}

1;
