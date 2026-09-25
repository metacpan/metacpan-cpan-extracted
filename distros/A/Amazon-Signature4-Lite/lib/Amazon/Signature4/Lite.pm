package Amazon::Signature4::Lite;

use strict;
use warnings;

use Digest::SHA qw(sha256_hex hmac_sha256 hmac_sha256_hex);
use MIME::Base64 qw(encode_base64);
use POSIX qw(strftime);
use URI::Escape qw(uri_escape_utf8 uri_unescape);
use Data::Dumper;

our $VERSION   = '1.0.6';
our $GIT_SHA   = '7e3c11129f8deca2d6b9b720993914cc7b9ad559';
our $GIT_DIRTY = '7e3c11129f8deca2d6b9b720993914cc7b9ad559';

my @SERVICE_URL_PATTERNS = (
  qr/(s3)[.]amazonaws[.]com\z/xsm,
  qr/(s3)[.]([^.]+)[.]amazonaws[.]com\z/xsm,
  qr/(s3)[.][^.]+[.]([^.]+)[.]amazonaws[.]com\z/xsm,
  qr/(s3)[-][^.]+[.].+[.]([^.]+)[.]amazonaws[.]com\z/xsm,
  qr/^([[:alnum:]-]+)[.]([^.]+)[.]amazonaws[.]com\z/xsm,  # service.region.amazonaws.com
  qr/^([[:alnum:]-]+)[.]amazonaws[.]com\z/xsm,  # service.amazonaws.com (no region)
);

########################################################################
sub new {
########################################################################
  my ( $class, %args ) = @_;

  die "access_key is required\n" if !$args{access_key};
  die "secret_key is required\n" if !$args{secret_key};
  die "region is required\n"     if !$args{region};

  my $service = $args{service} // 's3';

  my $disable_double_encoding = exists $args{disable_double_encoding} ? $args{disable_double_encoding} : $service eq 's3';

  return bless {
    access_key              => $args{access_key},
    secret_key              => $args{secret_key},
    session_token           => $args{session_token},
    region                  => $args{region},
    service                 => $args{service} // 's3',
    disable_double_encoding => $disable_double_encoding,
  }, $class;
}

########################################################################
sub parse_service_url {
########################################################################
  my ( $class_or_self, %args ) = @_;

  my ( $host,   $service )        = @args{qw(host service)};
  my ( $region, $default_region ) = @args{qw(region default_region)};

  if ( !$service || !$region ) {
    for my $pattern (@SERVICE_URL_PATTERNS) {
      if ( $host =~ $pattern ) {
        $service = $1;
        $region  = $2 || $region || $default_region;
        last;
      }
    }
  }

  $region ||= $default_region;

  return ( $host, $service, $region );
}

########################################################################
sub sign {
########################################################################
  my ( $self, %args ) = @_;

  my $method       = uc( $args{method} // 'GET' );
  my $url          = $args{url} or die "url is required\n";
  my $headers      = $args{headers} // {};
  my $payload      = $args{payload} // q{};
  my $payload_hash = $args{payload_hash};

  my $add_sha256_header = $args{add_sha256_header} // 1;

  # parse url into components
  my ( $scheme, $host, $path, $query ) = $url =~ m{\A(https?)://([^/?#]+)([^?#]*)(?:[?]([^#]*))?\z}xsm;

  $path = $path || '/';
  $query //= q{};

  # timestamps
  my $now      = $args{time} // time;
  my $datetime = strftime( '%Y%m%dT%H%M%SZ', gmtime($now) );
  my ($date)   = $datetime =~ /\A(\d{8})/xsm;

  # payload hash
  $payload_hash //= sha256_hex( ref $payload ? ${$payload} : $payload );

  # canonical headers - must include host and x-amz-date at minimum
  my %sign_headers = (
    %{$headers},
    'host'       => $host,
    'x-amz-date' => $datetime,
    $add_sha256_header ? ( 'x-amz-content-sha256' => $payload_hash ) : (),
  );

  $sign_headers{'x-amz-security-token'} = $self->{session_token}
    if $self->{session_token};

  # sort and build canonical headers string
  my @header_keys    = sort { lc($a) cmp lc($b) } keys %sign_headers;
  my $canon_headers  = join q{}, map { lc($_) . ':' . $sign_headers{$_} . "\n" } @header_keys;
  my $signed_headers = join ';', map { lc($_) } @header_keys;

  # canonical query string - sort by encoded key then encoded value
  my $canon_query = q{};
  if ($query) {
    my @pairs = map {
      join '=', map { uri_escape_utf8( uri_unescape($_) ) } split /=/xsm, $_, 2
      }
      sort { $a cmp $b }
      split /&/xsm, $query;
    $canon_query = join '&', @pairs;
  }

  # canonical request path.
  #
  # SigV4 encodes the path segment TWICE for every service EXCEPT S3,
  # which is encoded ONCE. The caller supplies a URL whose path is
  # already percent-encoded once, so for S3 we use it verbatim; for all
  # other services we apply the second encoding via _encode_path.
  # Re-encoding an already-encoded S3 key (e.g. %23 -> %2523) is what
  # produces SignatureDoesNotMatch on keys with reserved characters.
  my $canon_path = $self->{disable_double_encoding} ? $path : _encode_path($path);

  my $canon_request = join "\n", $method, $canon_path, $canon_query, $canon_headers, $signed_headers, $payload_hash;

  # credential scope
  my $service = $self->{service};
  my $region  = $self->{region};
  my $scope   = "$date/$region/$service/aws4_request";

  # string to sign
  my $string_to_sign = join "\n", 'AWS4-HMAC-SHA256', $datetime, $scope, sha256_hex($canon_request);

  # signing key - HMAC chain
  my $signing_key = hmac_sha256( 'aws4_request',
    hmac_sha256( $service, hmac_sha256( $region, hmac_sha256( $date, "AWS4${\$self->{secret_key}}" ) ) ) );

  # signature
  my $signature = hmac_sha256_hex( $string_to_sign, $signing_key );

  # authorization header
  my $authorization = sprintf
    'AWS4-HMAC-SHA256 Credential=%s/%s, SignedHeaders=%s, Signature=%s',
    $self->{access_key}, $scope, $signed_headers, $signature;

  # return merged headers ready for HTTP::Tiny
  return { %sign_headers, 'Authorization' => $authorization, };
}

########################################################################
sub _encode_path {
########################################################################
  my ($path) = @_;

  # encode each segment individually, preserving slashes
  return join '/', map { uri_escape_utf8($_) } split m{/}xsm, $path, -1;
}

1;

__END__

=head1 NAME

Amazon::Signature4::Lite - Lightweight AWS Signature Version 4 signing

=head1 SYNOPSIS

  use Amazon::Signature4::Lite;

  my $signer = Amazon::Signature4::Lite->new(
    access_key    => $access_key_id,
    secret_key    => $secret_access_key,
    session_token => $session_token,   # optional, for STS/IAM roles
    region        => 'us-east-1',
    service       => 's3',             # default
  );

  my $signed = $signer->sign(
    method  => 'PUT',
    url     => 'https://s3.amazonaws.com/my-bucket/my-key',
    headers => { 'Content-Type' => 'application/gzip' },
    payload => $content,
  );

  # $signed is a hashref of headers ready for HTTP::Tiny:
  # Authorization, x-amz-date, x-amz-content-sha256,
  # x-amz-security-token (if session_token provided), host

  # For streamed content, supply a precomputed SHA-256 hash instead of #
  # passing the complete payload to the signer.

  my $signed = $signer->sign(
    method       => 'PUT',
    url          => 'https://s3.amazonaws.com/my-bucket/my-key',
    headers      => { 'Content-Type' => 'application/octet-stream', 'Content-Length' => $content_length, },
    payload_hash => $payload_hash,
  );

=head1 DESCRIPTION

A minimal, dependency-free AWS Signature Version 4 implementation for
signing S3 and other AWS API requests. Unlike L<AWS::Signature4>, this
module does not depend on L<LWP> or L<HTTP::Request> - it works
directly with the plain scalars and hashrefs that L<HTTP::Tiny> uses.

For large or streamed request bodies, callers may provide a precomputed
SHA-256 payload hash, allowing the request to be signed without holding
the complete payload in memory.

=head1 METHODS

=head2 new(%args)

  my $signer = Amazon::Signature4::Lite->new(
    access_key => $key,
    secret_key => $secret,
    region     => 'us-east-1',
  );

Required: C<access_key>, C<secret_key>, C<region>.
Optional: C<session_token> (for temporary credentials), C<service>
(defaults to C<s3>).

=head2 sign(%args)

  my $headers = $signer->sign(
    method  => 'GET',
    url     => $url,
    headers => %extra_headers,
    payload => $body,
  );

Signs an AWS request and returns a hash reference containing the HTTP
headers required for the request.

Arguments:

=over 4

=item method

HTTP request method. Defaults to C<GET>.

=item url

The complete request URL. Required.

=item headers

Optional hash reference containing additional request headers to include
in the signature.

=item payload

The request body. The SHA-256 hash used in the canonical request is
calculated from this value.

If neither C<payload> nor C<payload_hash> is supplied, the payload is
treated as an empty string.

=item payload_hash

An optional precomputed SHA-256 hash of the request body.

When supplied, C<payload_hash> is used directly in the canonical request
and, by default, as the value of the C<x-amz-content-sha256> header. The
C<payload> value is not hashed.

This is useful when the request body will be streamed and holding the
complete payload in memory solely for signing would be undesirable. The
caller is responsible for ensuring that C<payload_hash> corresponds
exactly to the content that will be transmitted.

my $headers = $signer->sign(
method       => 'PUT',
url          => $url,
headers      => %extra_headers,
payload_hash => $sha256,
);

=item add_sha256_header

Controls whether C<x-amz-content-sha256> is included in the returned
headers. Defaults to true.

=item time

Optional Unix timestamp used when generating the signing timestamp.
When omitted, the current time is used. This is primarily useful for
testing or applications that need to control the signing time.

=back

The returned hash reference includes C<Authorization>, C<x-amz-date>,
C<host>, and, by default, C<x-amz-content-sha256>. It also includes
C<x-amz-security-token> when the signer was constructed with a session
token.

The returned hash reference can be passed directly as the headers for an
L<HTTP::Tiny> request.

=head2 parse_service_url(%args)

  my ($host, $service, $region) = Amazon::Signature4::Lite->parse_service_url(
    host           => 's3.us-east-2.amazonaws.com',
    default_region => 'us-east-1',
  );

Extracts service name and region from an AWS endpoint URL. Can be
called as a class or instance method.

I<Note: The patterns used for parsing are S3/AWS endpoint focused, not
a general URL parser.>

=head1 DEPENDENCIES

All dependencies are Perl core modules (since 5.10) or already
required by distributions in the Amazon::* toolchain:

=over 4

=item * L<Digest::SHA> (core since 5.10)

=item * L<MIME::Base64> (core)

=item * L<POSIX> (core)

=item * L<URI::Escape>

=back

=head1 SEE ALSO

L<AWS::Signature4>, L<Signer::AWSv4>, L<Amazon::S3::Lite>

=cut
