
package AWS::S3::Request::ListAllMyBuckets;

use Moose;
use AWS::S3::Signer;

with 'AWS::S3::Roles::BucketAction';

has '+_action' => ( default => 'GET' );
has '+_expect_nothing' => ( default => 0 );

__PACKAGE__->meta->make_immutable;
