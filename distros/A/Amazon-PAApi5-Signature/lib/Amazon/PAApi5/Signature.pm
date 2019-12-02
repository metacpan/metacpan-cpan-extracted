package Amazon::PAApi5::Signature;
use strict;
use warnings;
use Carp qw/croak/;
use POSIX qw/strftime/;
use Digest::SHA qw/sha256_hex hmac_sha256 hmac_sha256_hex/;
use Class::Accessor::Lite (
    rw  => [qw/
        access_key
        secret_key
        payload
        resource_path
        operation
        host
        region
        aws_headers
        str_signed_header
    /],
    ro  => [qw/
        service
        http_method
        hmac_algorithm
        aws4_request
        x_amz_date
        current_date
    /],
);

our $VERSION = '0.01';

sub new {
    my $class      = shift;
    my $access_key = shift or croak 'access_key is required';
    my $secret_key = shift or croak 'secret_key is required';
    my $payload    = shift or croak 'payload is required';
    my $opt        = shift || {};

    return bless {
        access_key     => $access_key,
        secret_key     => $secret_key,
        payload        => $payload,
        resource_path  => $opt->{resource_path}  || '/paapi5/searchitems',
        operation      => $opt->{operation}      || 'SearchItems',
        host           => $opt->{host}           || 'webservices.amazon.com',
        region         => $opt->{region}         || 'us-east-1',
        service        => $opt->{service}        || 'ProductAdvertisingAPI',
        http_method    => $opt->{http_method}    || 'POST',
        hmac_algorithm => $opt->{hmac_algorithm} || 'AWS4-HMAC-SHA256',
        aws4_request   => $opt->{aws4_request}   || 'aws4_request',
        x_amz_date     => $class->_get_time_stamp,
        current_date   => $class->_get_date,
        aws_headers    => {},
        str_signed_header => '',
    }, $class;
}

sub req_url {
    my ($self) = @_;

    return sprintf("https://%s%s", $self->host, $self->resource_path);
}

sub _prepare_canonical_url {
    my ($self) = @_;

    my $canonical_url = $self->http_method . "\n";

    $canonical_url .= $self->resource_path . "\n\n";

    my $signed_headers = '';
    for my $key (grep { $_ !~ m!content-type! } sort keys %{$self->aws_headers}) {
        $signed_headers .=  lc($key) . ';';
        $canonical_url .= lc($key) . ':' . $self->aws_headers->{$key} . "\n";
    }

    $canonical_url .= "\n";

    $self->str_signed_header(substr($signed_headers, 0, -1)); # remove ';'
    $canonical_url .= $self->str_signed_header . "\n";

    $canonical_url .= sha256_hex($self->payload);

    return $canonical_url;
}

sub _prepare_string_to_sign {
    my ($self, $canonical_url) = @_;

    return join("\n",
        $self->hmac_algorithm,
        $self->x_amz_date,
        join('/', $self->current_date, $self->region, $self->service, $self->aws4_request),
        sha256_hex($canonical_url),
    );
}

sub _calculate_signature {
    my ($self, $string_to_sign) = @_;

    my $signature_key = $self->_get_signature_key;

    return lc(hmac_sha256_hex($string_to_sign, $signature_key));
}

sub _build_authorization_string {
    my ($self, $signature) = @_;

    return $self->hmac_algorithm . ' '
        . 'Credential=' . join('/', $self->access_key, $self->_get_date, $self->region, $self->service, $self->aws4_request)
        . ',SignedHeaders=' . $self->str_signed_header
        . ',Signature=' . $signature
    ;
}

sub headers {
    my ($self) = @_;

    my $aws_headers = $self->aws_headers;

    $aws_headers->{'content-encoding'} = 'amz-1.0';
    $aws_headers->{'content-type'}     = 'application/json; charset=UTF-8';
    $aws_headers->{'host'}             = $self->host;
    $aws_headers->{'x-amz-date'}       = $self->x_amz_date;
    $aws_headers->{'x-amz-target'}     = $self->_build_amz_target;

    my $canonical_url = $self->_prepare_canonical_url;

    my $string_to_sign = $self->_prepare_string_to_sign($canonical_url);

    my $signature = $self->_calculate_signature($string_to_sign);

    $aws_headers->{Authorization} = $self->_build_authorization_string($signature);

    $self->aws_headers($aws_headers);

    return %{$aws_headers};
}

sub headers_as_arrayref {
    return [shift->headers];
}

sub headers_as_hashref {
    return {shift->headers};
}

sub _get_signature_key {
    my ($self) = @_;

    my $k_date    = hmac_sha256($self->current_date, 'AWS4' . $self->secret_key);
    my $k_region  = hmac_sha256($self->region, $k_date);
    my $k_service = hmac_sha256($self->service, $k_region);
    my $k_signing = hmac_sha256($self->aws4_request, $k_service);

    return $k_signing;
}

sub _build_amz_target {
    return 'com.amazon.paapi5.v1.ProductAdvertisingAPIv1.' . shift->operation;
}

sub _get_time_stamp {
    return strftime("%Y%m%dT%H%M%SZ", gmtime()); # 20191128T235650Z
}

sub _get_date {
    return strftime("%Y%m%d", gmtime()); # 20191128
}

sub to_request {
    my ($self) = @_;

    return {
        method  => $self->http_method,
        uri     => $self->req_url,
        headers => $self->headers_as_hashref,
        content => $self->payload,
    };
}

1;

__END__

=encoding UTF-8

=head1 NAME

Amazon::PAApi5::Signature - Amazon Product Advertising API(PA-API) 5.0 Helper


=head1 SYNOPSIS

    use Amazon::PAApi5::Payload;
    use Amazon::PAApi5::Signature;
    use HTTP::Headers;
    use LWP::UserAgent;
    use Data::Dumper;

    my $payload = Amazon::PAApi5::Payload->new(
        'PARTNER_TAG'
    );

    my $sig = Amazon::PAApi5::Signature->new(
        'ACCESS_KEY',
        'SECRET_KEY',
        $payload->to_json({
            Keywords    => 'Perl',
            SearchIndex => 'All',
            ItemCount   => 2,
            Resources   => [qw/
                ItemInfo.Title
            /],
        }),
    );

    my $ua = LWP::UserAgent->new(
        default_headers => HTTP::Headers->new($sig->headers),
    );

    my $res = $ua->post($sig->req_url, Content => $sig->payload);

    warn Dumper($res->status_line, $res->content);


=head1 DESCRIPTION

Amazon::PAApi5::Signature generates a request headers and request body for Amazon Product Advertising API(PA-API) 5.0

<https://webservices.amazon.com/paapi5/documentation/quick-start.html>


=head1 METHODS

=head2 new($access_key, $secret_key, $request_payload, $options)

Constructor

=head2 req_url

Get request URL string

=head2 headers

Get signed HTTP headers as hash

=head3 headers_as_arrayref

=head3 headers_as_hashref

=head2 to_request

Get a hash for HTTP request


=head1 REPOSITORY

=begin html

<a href="https://github.com/bayashi/Amazon-PAApi5-Signature/blob/master/LICENSE"><img src="https://img.shields.io/badge/LICENSE-Artistic%202.0-GREEN.png"></a> <a href="http://travis-ci.org/bayashi/Amazon-PAApi5-Signature"><img src="https://secure.travis-ci.org/bayashi/Amazon-PAApi5-Signature.png"/></a> <a href="https://coveralls.io/r/bayashi/Amazon-PAApi5-Signature"><img src="https://coveralls.io/repos/bayashi/Amazon-PAApi5-Signature/badge.png?branch=master"/></a>

=end html

Amazon::PAApi5::Signature is hosted on github: L<http://github.com/bayashi/Amazon-PAApi5-Signature>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

C<Amazon::PAApi5::Signature> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
