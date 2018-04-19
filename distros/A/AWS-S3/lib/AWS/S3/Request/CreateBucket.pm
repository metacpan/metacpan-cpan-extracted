
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
    required => 0,
    lazy     => 1,

    # https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUT.html
    # "By default, the bucket is created in the US East (N. Virginia) region."
    default  => sub { 'us-east-1' },
);

has '+_expect_nothing' => ( default => 1 );

sub request {
    my $s = shift;

    my $xml = <<"XML";
<CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"> 
  <LocationConstraint>@{[ $s->location || 'us-east-1' ]}</LocationConstraint> 
</CreateBucketConfiguration>
XML

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
