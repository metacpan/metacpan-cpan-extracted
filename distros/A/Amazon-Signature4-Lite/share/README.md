# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [METHODS](#methods)
  * [new(%args)](#new%args)
  * [sign(%args)](#sign%args)
  * [parse\_service\_url(%args)](#parse\service\url%args)
* [DEPENDENCIES](#dependencies)
* [SEE ALSO](#see-also)
# NAME

Amazon::Signature4::Lite - Lightweight AWS Signature Version 4 signing

# SYNOPSIS

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

# DESCRIPTION

A minimal, dependency-free AWS Signature Version 4 implementation for
signing S3 and other AWS API requests. Unlike [AWS::Signature4](https://metacpan.org/pod/AWS%3A%3ASignature4), this
module does not depend on [LWP](https://metacpan.org/pod/LWP) or [HTTP::Request](https://metacpan.org/pod/HTTP%3A%3ARequest) - it works
directly with the plain scalars and hashrefs that [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny) uses.

For large or streamed request bodies, callers may provide a precomputed
SHA-256 payload hash, allowing the request to be signed without holding
the complete payload in memory.

# METHODS

## new(%args)

    my $signer = Amazon::Signature4::Lite->new(
      access_key => $key,
      secret_key => $secret,
      region     => 'us-east-1',
    );

Required: `access_key`, `secret_key`, `region`.
Optional: `session_token` (for temporary credentials), `service`
(defaults to `s3`).

## sign(%args)

    my $headers = $signer->sign(
      method  => 'GET',
      url     => $url,
      headers => %extra_headers,
      payload => $body,
    );

Signs an AWS request and returns a hash reference containing the HTTP
headers required for the request.

Arguments:

- method

    HTTP request method. Defaults to `GET`.

- url

    The complete request URL. Required.

- headers

    Optional hash reference containing additional request headers to include
    in the signature.

- payload

    The request body. The SHA-256 hash used in the canonical request is
    calculated from this value.

    If neither `payload` nor `payload_hash` is supplied, the payload is
    treated as an empty string.

- payload\_hash

    An optional precomputed SHA-256 hash of the request body.

    When supplied, `payload_hash` is used directly in the canonical request
    and, by default, as the value of the `x-amz-content-sha256` header. The
    `payload` value is not hashed.

    This is useful when the request body will be streamed and holding the
    complete payload in memory solely for signing would be undesirable. The
    caller is responsible for ensuring that `payload_hash` corresponds
    exactly to the content that will be transmitted.

    my $headers = $signer->sign(
    method       => 'PUT',
    url          => $url,
    headers      => %extra\_headers,
    payload\_hash => $sha256,
    );

- add\_sha256\_header

    Controls whether `x-amz-content-sha256` is included in the returned
    headers. Defaults to true.

- time

    Optional Unix timestamp used when generating the signing timestamp.
    When omitted, the current time is used. This is primarily useful for
    testing or applications that need to control the signing time.

The returned hash reference includes `Authorization`, `x-amz-date`,
`host`, and, by default, `x-amz-content-sha256`. It also includes
`x-amz-security-token` when the signer was constructed with a session
token.

The returned hash reference can be passed directly as the headers for an
[HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny) request.

## parse\_service\_url(%args)

    my ($host, $service, $region) = Amazon::Signature4::Lite->parse_service_url(
      host           => 's3.us-east-2.amazonaws.com',
      default_region => 'us-east-1',
    );

Extracts service name and region from an AWS endpoint URL. Can be
called as a class or instance method.

_Note: The patterns used for parsing are S3/AWS endpoint focused, not
a general URL parser._

# DEPENDENCIES

All dependencies are Perl core modules (since 5.10) or already
required by distributions in the Amazon::\* toolchain:

- [Digest::SHA](https://metacpan.org/pod/Digest%3A%3ASHA) (core since 5.10)
- [MIME::Base64](https://metacpan.org/pod/MIME%3A%3ABase64) (core)
- [POSIX](https://metacpan.org/pod/POSIX) (core)
- [URI::Escape](https://metacpan.org/pod/URI%3A%3AEscape)

# SEE ALSO

[AWS::Signature4](https://metacpan.org/pod/AWS%3A%3ASignature4), [Signer::AWSv4](https://metacpan.org/pod/Signer%3A%3AAWSv4), [Amazon::S3::Lite](https://metacpan.org/pod/Amazon%3A%3AS3%3A%3ALite)
