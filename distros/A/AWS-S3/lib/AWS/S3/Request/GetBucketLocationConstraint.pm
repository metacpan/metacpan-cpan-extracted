
package AWS::S3::Request::GetBucketLocationConstraint;

use Moose;
use AWS::S3::ResponseParser;

with 'AWS::S3::Roles::BucketAction';

has 'bucket' => ( is => 'ro', isa => 'Str', required => 1 );

has '+_action' => ( default => 'GET' );

has '_subresource' => (
  is       => 'ro',
  isa      => 'Str',
  init_arg => undef,
  default  => 'location'
);

has '+_expect_nothing' => ( default => 0 );

__PACKAGE__->meta->make_immutable;
