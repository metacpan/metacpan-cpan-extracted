
package AWS::S3::Request::GetBucketPolicy;

use Moose;
use AWS::S3::ResponseParser;

with 'AWS::S3::Roles::BucketAction';

has '+_action' => ( default => 'GET' );

has 'bucket' => ( is => 'ro', isa => 'Str', required => 1 );

has '_subresource' => (
  is       => 'ro',
  isa      => 'Str',
  init_arg => undef,
  default  => 'policy'
);

has '+_expect_nothing' => ( default => 0 );

__PACKAGE__->meta->make_immutable;
