
package AWS::S3::Request::GetFileInfo;

use Moose;
use AWS::S3::Signer;
use AWS::S3::ResponseParser;

with 'AWS::S3::Roles::BucketAction';

has 'bucket' => ( is => 'ro', isa => 'Str', required => 1 );
has 'key' => ( is => 'ro', isa => 'Str', required => 1 );

has '+_action' => ( default => 'HEAD' );
has '+_expect_nothing' => ( default => 0 );

__PACKAGE__->meta->make_immutable;
