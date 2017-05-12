
package AWS::S3::Request::DeleteMulti;

use Moose;
use AWS::S3::Signer;
use AWS::S3::ResponseParser;

with 'AWS::S3::Roles::Request';

has 'bucket' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'keys' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

has '_subresource' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    default  => 'delete'
);



has '+_expect_nothing' => ( default => 0 );

sub request {
    my $s = shift;

    my $objects = join "\n", map { "<Object><Key>@{[ $_ ]}</Key></Object>" } @{ $s->keys };

    my $xml = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<Delete>
$objects
</Delete>
XML

    my $signer = AWS::S3::Signer->new(
        s3           => $s->s3,
        method       => 'POST',
        uri          => $s->_uri,
        content      => \$xml,
        content_type => '',
    );

    $s->_send_request(
        $signer->method => $signer->uri => {
            Authorization => $signer->auth_header,
            Date          => $signer->date,
            'content-md5' => $signer->content_md5,
        },
        $xml
    );
}

__PACKAGE__->meta->make_immutable;
