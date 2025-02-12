
package AWS::S3::Request::CreateBucket;
use Moose;

use AWS::S3::Signer;

with 'AWS::S3::Roles::Request';

has 'bucket' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'location' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    lazy     => 1,
    required => 0,
    default  => sub { shift->s3->region || $ENV{AWS_REGION} },
);

has '+_expect_nothing' => ( default => 1 );

sub request {
    my $s = shift;

    # By default the bucket is put in us-east-1. But if you _ask_ for
    # us-east-1 you get an error.
    my $xml = q{};
    if ( $s->location && $s->location ne 'us-east-1' ) {
        $xml = <<"XML";
<CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"> 
  <LocationConstraint>@{[ $s->location ]}</LocationConstraint>
</CreateBucketConfiguration>
XML
    }

    my $signer = AWS::S3::Signer->new(
        s3           => $s->s3,
        method       => 'PUT',
        uri          => $s->protocol . '://' . $s->bucket . '.' . $s->endpoint . '/',
        content_type => 'text/plain',
        content_md5  => '',
        content      => \$xml,
    );

    return $s->_send_request(
        $signer->method => $signer->uri => {
            Authorization  => $signer->auth_header,
            Date           => $signer->date,
            'content-type' => 'text/plain',
        },
        $xml
    );
}

__PACKAGE__->meta->make_immutable;
