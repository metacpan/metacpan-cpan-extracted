package AWS::S3::Roles::Bucket;

use Moose::Role;

sub bucket_uri {
    my ( $s,$path ) = @_;

    $path      //= $s->bucket;
    my $protocol = $s->s3->secure ? 'https' : 'http';
    my $endpoint = $s->s3->endpoint;
    my $uri = "$protocol://$endpoint/$path";
    if ( $path =~ m{^([^/?]+)(.*)} && $s->is_dns_bucket( $1 ) ) {
        $uri = "$protocol://$1.$endpoint$2";
    }    # end if()

    return $uri;
}

sub is_dns_bucket {
    my ( $s,$bucket ) = @_;

    # https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html
    return 0 if ( length( $bucket ) < 3 or length( $bucket ) > 63 );
    return 0 if $bucket =~ /^(?:\d{1,3}\.){3}\d{1,3}$/;

    # DNS bucket names can contain lowercase letters, numbers, and hyphens
    # so anything outside this range we say isn't a valid DNS bucket
    return $bucket =~ /[^a-z0-9-\.]/ ? 0 : 1;
}

1;
