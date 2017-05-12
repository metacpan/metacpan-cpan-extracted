package AWS::S3::Roles::BucketAction;
use Moose::Role;
use HTTP::Request;
use AWS::S3::ResponseParser;

with 'AWS::S3::Roles::Request';

sub request {
    my $s = shift;

    my $signer = AWS::S3::Signer->new(
        s3     => $s->s3,
        method => $s->_action,
        uri    => $s->_uri
    );
    $s->_send_request(
        $signer->method => $signer->uri => {
            Authorization => $signer->auth_header,
            Date          => $signer->date,
        }
    );
}    # end request()

1;
