
package AWS::S3::Request::SetBucketPolicy;

use Moose;
use AWS::S3::Signer;
use AWS::S3::ResponseParser;
use JSON::XS;

with 'AWS::S3::Roles::Request';

has 'bucket' => ( is => 'ro', isa => 'Str', required => 1 );

has '_subresource' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    default  => 'policy'
);

has 'policy' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    required => 1,

    # Evan Carroll 6/14/2012
    # COMMENTED THIS OUT, not sure if it ever worked on VSO
    # Must be able to decode the JSON string:
    # where => sub {
    #     eval { decode_json( $_ ); 1 };
    # }
);

has '+_expect_nothing' => ( default => 1 );

sub request {
    my $s = shift;

    my $signer = AWS::S3::Signer->new(
        s3           => $s->s3,
        method       => 'PUT',
        uri          => $s->_uri,
        content      => \$s->policy,
        content_type => '',
        content_md5  => '',
    );

    #warn "SetPolicy.string_to_sign(" . $signer->string_to_sign . ")";
    $s->_send_request(
        $signer->method => $signer->uri => {
            Authorization => $signer->auth_header,
            Date          => $signer->date,
        },
        $s->policy
    );
}    # end request()

__PACKAGE__->meta->make_immutable;
