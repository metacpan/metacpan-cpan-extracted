
package AWS::S3::Request::DeleteBucket;

use Moose;
use AWS::S3::ResponseParser;

with 'AWS::S3::Roles::BucketAction';

has '+_action' => ( default => 'DELETE' );
has 'bucket' => ( is => 'ro', isa => 'Str', required => 1 );

has '+_expect_nothing' => ( default => 1 );

__PACKAGE__->meta->make_immutable;
