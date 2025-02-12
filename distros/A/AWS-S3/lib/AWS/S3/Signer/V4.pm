package AWS::S3::Signer::V4;

use strict;
use POSIX 'strftime';
use URI;
use URI::QueryParam;
use URI::Escape;
use Digest::SHA 'sha256_hex', 'hmac_sha256', 'hmac_sha256_hex';
use Date::Parse;
use Carp 'croak';
use HTTP::Request;

# https://webservices.amazon.com/paapi5/documentation/common-request-parameters.html#host-and-region
use constant PAAPI_REGION => {
    qw/
      webservices.amazon.com.au	us-west-2
      webservices.amazon.com.br	us-east-1
      webservices.amazon.ca		us-east-1
      webservices.amazon.fr		eu-west-1
      webservices.amazon.de		eu-west-1
      webservices.amazon.in		eu-west-1
      webservices.amazon.it		eu-west-1
      webservices.amazon.co.jp	us-west-2
      webservices.amazon.com.mx	us-east-1
      webservices.amazon.sg		us-west-2
      webservices.amazon.es		eu-west-1
      webservices.amazon.com.tr	eu-west-1
      webservices.amazon.ae		eu-west-1
      webservices.amazon.co.uk	eu-west-1
      webservices.amazon.com		us-east-1
      /
};

=head1 NAME

AWS::S3::Signer::V4 - Create a version4 signature for Amazon Web Services

=head1 SYNOPSIS

 use AWS::S3::Signer::V4;
 use HTTP::Request::Common;
 use LWP;

 my $signer = AWS::S3::Signer::V4->new(-access_key => 'AKIDEXAMPLE',
                                   -secret_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY');
 my $ua     = LWP::UserAgent->new();

 # Example POST request
 my $request = POST('https://iam.amazonaws.com',
		    [Action=>'ListUsers',
		     Version=>'2010-05-08']);
 $signer->sign($request);
 my $response = $ua->request($request);

 # Example GET request
 my $uri     = URI->new('https://iam.amazonaws.com');
 $uri->query_form(Action=>'ListUsers',
		  Version=>'2010-05-08');

 my $url = $signer->signed_url($uri); # This gives a signed URL that can be fetched by a browser
 my $response = $ua->get($url);

=head1 DESCRIPTION

This module implement's Amazon Web Service's Signature version 4
(http://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).

=head1 METHODS

=over 4

=item $signer = AWS::S3::Signer::V4->new(-access_key => $account_id,-secret_key => $private_key);

Create a signing object using your AWS account ID and secret key. You
may also use the temporary security tokens received from Amazon's STS
service, either by passing the access and secret keys derived from the
token, or by passing a VM::EC2::Security::Token produced by the
VM::EC2 module.

Arguments:

 Argument name       Argument Value
 -------------       --------------
 -access_key         An AWS access key (account ID)

 -secret_key         An AWS secret key

 -security_token     A VM::EC2::Security::Token object

 -service            An AWS service

 -region             An AWS region


If a security token is provided, it overrides any values given for
-access_key or -secret_key.

If the environment variables EC2_ACCESS_KEY and/or EC2_SECRET_KEY are
set, their contents are used as defaults for -access_key and
-secret_key.

If -service and/or -region is not provided, they are automtically determined
according to endpoint.

=cut

sub new {
    my $self = shift;
    my %args = @_;

    my ( $id, $secret, $token, $region, $service );
    if ( ref $args{-security_token}
        && $args{-security_token}->can('access_key_id') )
    {
        $id     = $args{-security_token}->accessKeyId;
        $secret = $args{-security_token}->secretAccessKey;
    }

    $id ||= $args{-access_key} || $ENV{EC2_ACCESS_KEY}
      or croak
"Please provide -access_key parameter or define environment variable EC2_ACCESS_KEY";
    $secret ||= $args{-secret_key} || $ENV{EC2_SECRET_KEY}
      or croak
"Please provide -secret_key or define environment variable EC2_SECRET_KEY";
    $region  = $args{-region}  || $ENV{EC2_REGION};
    $service = $args{-service} || $ENV{EC2_SERVICE};

    return bless {
        access_key => $id,
        secret_key => $secret,
        region     => $region,
        region     => $args{-region},
        service    => $args{-service},
        (
            defined( $args{-security_token} )
            ? ( security_token => $args{-security_token} )
            : ()
        ),
      },
      ref $self || $self;
}

sub access_key { shift->{access_key} }
sub secret_key { shift->{secret_key} }

=item $signer->sign($request [,$region] [,$payload_sha256_hex])

Given an HTTP::Request object, add the headers required by AWS and
then sign it with a version 4 signature by adding an "Authorization"
header.

The request must include a URL from which the AWS endpoint and service
can be derived, such as "ec2.us-east-1.amazonaws.com." In some cases
(e.g. S3 bucket operations) the endpoint does not indicate the
region. In this case, the region can be forced by passing a defined
value for $region. The current date and time will be added to the
request using an "X-Amz-Date header." To force the date and time to a
fixed value, include the "Date" header in the request.

The request content, or "payload" is retrieved from the HTTP::Request
object by calling its content() method.. Under some circumstances the
payload is not included directly in the request, but is in an external
file that will be uploaded as the request is executed. In this case,
you must pass a second argument containing the results of running
sha256_hex() (from the Digest::SHA module) on the content.

The method returns a true value if successful. On errors, it will
throw an exception.

=item $url = $signer->signed_url($request)

This method will generate a signed GET URL for the request. The URL
will include everything needed to perform the request.

=cut

sub sign {
    my $self = shift;
    my ( $request, $region, $payload_sha256_hex ) = @_;
    $self->_add_date_header($request);
    $self->_sign( $request, $region, $payload_sha256_hex );
}

=item my $url $signer->signed_url($request_or_uri [,$expires] [,$verb])

Pass an HTTP::Request, a URI object, or just a plain URL string
containing the proper endpoint and parameters needed for an AWS REST
API Call. This method will return an appropriately signed request as a
URI object, which can be shared with non-AWS users for the purpose of,
e.g., accessing an object in a private S3 bucket.

Pass an optional $expires argument to indicate that the URL will only
be valid for a finite period of time. The value of the argument is in
seconds.

Pass an optional verb which is useful for HEAD requests, this defaults to GET.

=cut

sub signed_url {
    my $self = shift;
    my ( $arg1, $expires, $verb ) = @_;
    my ( $request, $uri );

    $verb ||= 'GET';
    $verb = uc($verb);

    my $incorrect_verbs = {
        POST => 1,
        PUT  => 1
    };

    if ( exists( $incorrect_verbs->{$verb} ) ) {
        die "Use AWS::S3::Signer::V4->sign sub for $verb method";
    }

    if ( ref $arg1 && UNIVERSAL::isa( $arg1, 'HTTP::Request' ) ) {
        $request = $arg1;
        $uri     = $request->uri;
        my $content = $request->content;
        $uri->query($content) if $content;
        if ( my $date =
            $request->header('X-Amz-Date') || $request->header('Date') )
        {
            $uri->query_param( 'Date' => $date );
        }
    }

    $uri ||= URI->new($arg1);
    my $date = $uri->query_param_delete('Date')
      || $uri->query_param_delete('X-Amz-Date');
    $request = HTTP::Request->new( $verb => $uri );
    $request->header( 'Date' => $date );
    $uri = $request->uri;    # because HTTP::Request->new() copies the uri!

    return $uri if $uri->query_param('X-Amz-Signature');

    my $scope = $self->_scope($request);

    $uri->query_param( 'X-Amz-Algorithm'  => $self->_algorithm );
    $uri->query_param( 'X-Amz-Credential' => $self->access_key . '/' . $scope );
    $uri->query_param( 'X-Amz-Date'       => $self->_datetime($request) );
    $uri->query_param( 'X-Amz-Expires'    => $expires ) if $expires;
    $uri->query_param( 'X-Amz-SignedHeaders' => 'host' );

# If there was a security token passed, we need to supply it as part of the authorization
# because AWS requires it to validate IAM Role temporary credentials.

    if ( defined( $self->{security_token} ) ) {
        $uri->query_param( 'X-Amz-Security-Token' => $self->{security_token} );
    }

# Since we're providing auth via query parameters, we need to include UNSIGNED-PAYLOAD
# http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html
# it seems to only be needed for S3.

    if ( $scope =~ /\/s3\/aws4_request$/ ) {
        $self->_sign( $request, undef, 'UNSIGNED-PAYLOAD' );
    }
    else {
        $self->_sign($request);
    }

    my ( $algorithm, $credential, $signedheaders, $signature ) =
      $request->header('Authorization') =~
      /^(\S+) Credential=(\S+), SignedHeaders=(\S+), Signature=(\S+)/;
    $uri->query_param_append( 'X-Amz-Signature' => $signature );
    return $uri;
}

sub _add_date_header {
    my $self    = shift;
    my $request = shift;
    my $datetime;
    unless ( $datetime = $request->header('x-amz-date') ) {
        $datetime = $self->_zulu_time($request);
        $request->header( 'x-amz-date' => $datetime );
    }
}

sub _scope {
    my $self = shift;
    my ( $request, $region ) = @_;
    my $host     = $request->uri->host;
    my $datetime = $self->_datetime($request);
    my ($date)   = $datetime =~ /^(\d+)T/;
    my $service;

    ( $service, $region ) = $self->parse_host( $host, $region );

    $service ||= $self->{service} || 's3';
    $region  ||= $self->{region}  || 'us-east-1';    # default
    return "$date/$region/$service/aws4_request";
}

sub parse_host {
    my $self = shift;
    my $host = shift;
    my $region = shift;

    # this entire thing should probably refactored into its own
    # distribution, a la https://github.com/zirkelc/amazon-s3-url

    # https://docs.aws.amazon.com/prescriptive-guidance/latest/defining-bucket-names-data-lakes/faq.html
    # Only lowercase letters, numbers, dashes, and dots are allowed in S3 bucket names.
    # Bucket names must be three to 63 characters in length,
    # must begin and end with a number or letter,
    # and cannot be in an IP address format.
    my $bucket_re = '[a-z0-9][a-z0-9\-\.]{1,61}[a-z0-9]';
    my $domain_re = 'amazonaws\.com';
    my $region_re = '(?:af|ap|ca|eu|il|me|mx|sa|us)-[a-z]+-\d';

    my ( $service, $url_style );

    # listed in order of appearance found in the docs:
    # https://community.aws/content/2biM1C0TkMkvJ2BLICiff8MKXS9/format-and-parse-amazon-s3-url?lang=en
    if ( $host =~ /^(\w+)([-.])($region_re)\.$domain_re/ ) {
        $service = $1;
        $region ||= $3;
        $url_style = $2 eq '-' ? 'regional dash-style' : 'regional dot-style';
    }
    elsif ( $host =~ /^$bucket_re\.($region_re)\.s3\.$domain_re/ ) {
        $service = 's3';
        $region ||= $1;
        $url_style = 'regional virtual-hosted-style';
    }
    elsif ( $host =~ /^s3\.$domain_re/ ) {
        $service = 's3';
        $region  = 'us-east-1';
        $url_style = 'legacy with path-style';
    }
    elsif ( $host =~ /^$bucket_re\.s3\.$domain_re/ ) {
        $service = 's3';
        $region ||= 'us-east-1';
        $url_style = 'legacy with virtual-hosted-style';
    }
    elsif ( $host =~ /^$bucket_re\.s3[\.-]($region_re)\.$domain_re/ ) {
        $service = 's3';
        $region ||= $1;
        $url_style = 'regional virtual-hosted-style';
    }
    elsif ($host =~ /^([\w-]+)\.([\w-]+)\.$domain_re/) {
        $service = $1;
        $region    ||= $2;
        $url_style = 'legacy path-style service';
    }
    elsif ( $host =~ /^([\w-]+)\.$domain_re/ ) {
        $service = $1;
        $region    = 'us-east-1';
        $url_style = 'legacy path-style';
    }
    elsif ( exists PAAPI_REGION->{$host} ) {
        $service = 'ProductAdvertisingAPI';
        $region  = PAAPI_REGION->{$host};
    }

    return ( $service, $region, $url_style );
}

sub _parse_scope {
    my $self  = shift;
    my $scope = shift;
    return split '/', $scope;
}

sub _datetime {
    my $self    = shift;
    my $request = shift;
    return $request->header('x-amz-date') || $self->_zulu_time($request);
}

sub _algorithm { return 'AWS4-HMAC-SHA256' }

sub _sign {
    my $self = shift;
    my ( $request, $region, $payload_sha256_hex ) = @_;
    return if $request->header('Authorization');    # don't overwrite

    my $datetime = $self->_datetime($request);

    unless ( $request->header('host') ) {
        my $host = $request->uri->host;
        $request->header( host => $host );
    }

    my $scope = $self->_scope( $request, $region );
    my ( $date, $service );
    ( $date, $region, $service ) = $self->_parse_scope($scope);

    my $secret_key = $self->secret_key;
    my $access_key = $self->access_key;
    my $algorithm  = $self->_algorithm;

    my ( $hashed_request, $signed_headers ) =
      $self->_hash_canonical_request( $request, $payload_sha256_hex );
    my $string_to_sign =
      $self->_string_to_sign( $datetime, $scope, $hashed_request );
    my $signature =
      $self->_calculate_signature( $secret_key, $service, $region, $date,
        $string_to_sign );
    $request->header( Authorization =>
"$algorithm Credential=$access_key/$scope, SignedHeaders=$signed_headers, Signature=$signature"
    );
}

sub _zulu_time {
    my $self     = shift;
    my $request  = shift;
    my $date     = $request->header('Date');
    my @datetime = $date ? gmtime( str2time($date) ) : gmtime();
    return strftime( '%Y%m%dT%H%M%SZ', @datetime );
}

sub _hash_canonical_request {
    my $self = shift;
    my ( $request, $hashed_payload ) =
      @_;    # (HTTP::Request,sha256_hex($content))
    my $method  = $request->method;
    my $uri     = $request->uri;
    my $path    = $uri->path || '/';
    my @params  = $uri->query_form;
    my $headers = $request->headers;
    $hashed_payload ||= sha256_hex( $request->content );

    # canonicalize query string

    # in the case of the S3 api, but its still expected to be part of a
    # canonical request.
    if (scalar(@params) == 0 && defined($uri->query) && $uri->query ne '') {
        push @params, ($uri->query, '');
    }

    my %canonical;
    while ( my ( $key, $value ) = splice( @params, 0, 2 ) ) {
        $key   = uri_escape($key);
        $value = uri_escape($value);
        push @{ $canonical{$key} }, $value;
    }
    my $canonical_query_string = join '&', map {
        my $key = $_;
        map { "$key=$_" } sort @{ $canonical{$key} }
    } sort keys %canonical;

    # canonicalize the request headers
    my ( @canonical, %signed_fields );
    for my $header ( sort map { lc } $headers->header_field_names ) {
        next if $header =~ /^date$/i;
        my @values = $headers->header($header);

        # remove redundant whitespace
        foreach (@values) {
            next if /^".+"$/;
            s/^\s+//;
            s/\s+$//;
            s/(\s)\s+/$1/g;
        }
        push @canonical, "$header:" . join( ',', @values );
        $signed_fields{$header}++;
    }
    my $canonical_headers = join "\n", @canonical;
    $canonical_headers .= "\n";
    my $signed_headers = join ';', sort map { lc } keys %signed_fields;

    my $canonical_request = join( "\n",
        $method,            $path,           $canonical_query_string,
        $canonical_headers, $signed_headers, $hashed_payload );
    my $request_digest = sha256_hex($canonical_request);

    return ( $request_digest, $signed_headers );
}

sub _string_to_sign {
    my $self = shift;
    my ( $datetime, $credential_scope, $hashed_request ) = @_;
    return join( "\n",
        'AWS4-HMAC-SHA256', $datetime, $credential_scope, $hashed_request );
}

=item $signing_key = AWS::S3::Signer::V4->signing_key($secret_access_key,$service_name,$region,$date)

Return just the signing key in the event you wish to roll your own signature.

=cut

sub signing_key {
    my $self = shift;
    my ( $kSecret, $service, $region, $date ) = @_;
    my $kDate    = hmac_sha256( $date,          'AWS4' . $kSecret );
    my $kRegion  = hmac_sha256( $region,        $kDate );
    my $kService = hmac_sha256( $service,       $kRegion );
    my $kSigning = hmac_sha256( 'aws4_request', $kService );
    return $kSigning;
}

sub _calculate_signature {
    my $self = shift;
    my ( $kSecret, $service, $region, $date, $string_to_sign ) = @_;
    my $kSigning = $self->signing_key( $kSecret, $service, $region, $date );
    return hmac_sha256_hex( $string_to_sign, $kSigning );
}

1;

=back

=head1 SEE ALSO

L<VM::EC2>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Forked by leejo for use in L<AWS::S3>.

Copyright (c) 2014 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

