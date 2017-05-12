
package AWS::S3::Request::SetFileContents;

use Moose;
use AWS::S3::Signer;
use AWS::S3::ResponseParser;

with 'AWS::S3::Roles::Request';

has 'bucket' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'file' => (
    is       => 'ro',
    isa      => 'AWS::S3::File',
    required => 1,
);

has 'content_type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    default  => sub { 'binary/octet-stream' },
);

has '+_expect_nothing' => ( default => 0 );

sub request {
    my $s = shift;

    my $contents;
    if ( ref( $s->file->contents ) eq 'CODE' ) {
        $contents = $s->file->contents->();
    } elsif ( ref( $s->file->contents ) eq 'SCALAR' ) {
        $contents = $s->file->contents;
    }    # end if()

    my %other_args = ();
    $other_args{'x-amz-server-side-encryption'} = 'AES256' if $s->file->is_encrypted;

    my $signer = AWS::S3::Signer->new(
        s3           => $s->s3,
        method       => 'PUT',
        uri          => $s->protocol . '://' . $s->bucket . '.' . $s->endpoint . '/' . $s->file->key,
        content_type => $s->content_type,
        content      => $contents,
        headers      => [ 'x-amz-storage-class', $s->file->storage_class ],
    );
    $s->_send_request(
        $signer->method => $signer->uri => {
            Authorization         => $signer->auth_header,
            Date                  => $signer->date,
            'content-type'        => $s->content_type,
            'content-md5'         => $signer->content_md5,
            'x-amz-storage-class' => $s->file->storage_class,
        },
        $$contents
    );
}    # end request()

__PACKAGE__->meta->make_immutable;
