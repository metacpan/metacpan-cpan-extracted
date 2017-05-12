
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
    isa      => 'Str',
    required => 0,
);

has '+_expect_nothing' => ( default => 1 );

sub request {
    my $s = shift;

    if ( $s->location ) {
        my $xml = <<"XML";
<CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"> 
  <LocationConstraint>@{[ $s->location ]}</LocationConstraint> 
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
    } else {
        my $signer = AWS::S3::Signer->new(
            s3     => $s->s3,
            method => 'PUT',
            uri    => $s->protocol . '://' . $s->endpoint . '/' . $s->bucket,
        );
        return $s->_send_request(
            $signer->method => $signer->uri => {
                Authorization => $signer->auth_header,
                Date          => $signer->date,
            }
        );
    }    # end if()
}    # end request()

__PACKAGE__->meta->make_immutable;
