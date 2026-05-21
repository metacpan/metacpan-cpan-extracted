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

# DESCRIPTION

A minimal, dependency-free AWS Signature Version 4 implementation for
signing S3 and other AWS API requests. Unlike [AWS::Signature4](https://metacpan.org/pod/AWS%3A%3ASignature4), this
module does not depend on [LWP](https://metacpan.org/pod/LWP) or [HTTP::Request](https://metacpan.org/pod/HTTP%3A%3ARequest) - it works
directly with the plain scalars and hashrefs that [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny) uses.

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
      headers => \%extra_headers,
      payload => $body,
    );

Returns a hashref of HTTP headers including `Authorization`,
`x-amz-date`, `x-amz-content-sha256`, and `host`. Merge these
into your [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny) request headers.

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
