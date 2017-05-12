package Acme::JWT;
use strict;
use warnings;
our $VERSION = '0.04';

use JSON qw/decode_json encode_json/;
use MIME::Base64 qw/encode_base64url decode_base64url/;
use Try::Tiny;
use Digest::SHA qw/hmac_sha256 hmac_sha384 hmac_sha512/;
use Crypt::OpenSSL::RSA;

our $has_sha2;
BEGIN {
    $has_sha2 = 0;
    if (UNIVERSAL::can('Crypt::OpenSSL::RSA', 'use_sha512_hash')) {
        $has_sha2 = 1;
    }
}

sub encode {
    my $self = shift;
    my ($payload, $key, $algorithm) = @_;
    unless (defined($algorithm)) {
        $algorithm = 'HS256';
    }
    unless ($algorithm) {
        $algorithm = 'none';
    }
    my $segments = [];
    my $header = {
        typ => 'JWT',
        alg => $algorithm,
    };
    push(@$segments, encode_base64url(encode_json($header)));
    push(@$segments, encode_base64url(encode_json($payload)));
    my $signing_input = join('.', @$segments);
    unless ($algorithm eq 'none') {
        my $signature = $self->sign($algorithm, $key, $signing_input);
        push(@$segments, encode_base64url($signature));
    } else {
        push(@$segments, '');
    }
    return join('.', @$segments);
}

sub decode {
    my $self = shift;
    my ($jwt, $key, $verify) = @_;
    unless (defined($verify)) {
        $verify = 1;
    }
    my $segments = [split(/\./, $jwt)];
    die 'Not enough or to many segments' unless (@$segments == 2 or @$segments == 3);
    my ($header_segment, $payload_segment, $crypt_segment) = @$segments;
    my $signing_input = join('.', $header_segment, $payload_segment);
    my $header;
    my $payload;
    my $signature;
    try {
        $header = decode_json(decode_base64url($header_segment));
        $payload = decode_json(decode_base64url($payload_segment));
        $signature = decode_base64url($crypt_segment) if ($verify);
    } catch {
        warn $_;
    };
    if ($verify) {
        my $algo = $header->{alg};
        my $hmac = sub {
            my ($algo, $key, $signing_input, $signature) = @_;
            $signature eq $self->sign_hmac($algo, $key, $signing_input);
        };
        my $verify_method = sub {
            my ($algo, $key, $signing_input, $signature) = @_;
            $self->verify_rsa($algo, $key, $signing_input, $signature);
        };
        my $algorithm = {
            HS256 => $hmac,
            HS384 => $hmac,
            HS512 => $hmac,
        };

        if ($has_sha2) {
            $algorithm = {
                %$algorithm,
                (
                    RS256 => $verify_method,
                    RS384 => $verify_method,
                    RS512 => $verify_method,
                ),
            };
        }
        if (exists($algorithm->{$algo})) {
            unless ($algorithm->{$algo}->($algo, $key, $signing_input, $signature)) {
                die 'Signature verifacation failed';
            }
        } else {
            die 'Algorithm not supported';
        }
    }
    return $payload;
}

sub sign {
    my $self = shift;
    my ($algo, $key, $signing_input) = @_;
    my $hmac = sub {
        my ($algo, $key, $signing_input) = @_;
        $self->sign_hmac($algo, $key, $signing_input);
    };
    my $rsa = sub {
        my ($algo, $key, $signing_input) = @_;
        $self->sign_rsa($algo, $key, $signing_input);
    };
    my $algorithm = {
        HS256 => $hmac,
        HS384 => $hmac,
        HS512 => $hmac,
    };
    if ($has_sha2) {
        $algorithm = {
            %$algorithm,
            (
                RS256 => $rsa,
                RS384 => $rsa,
                RS512 => $rsa,
            ),
        };
    }
    unless (exists($algorithm->{$algo})) {
        die 'Unsupported signing method';
    }
    $algorithm->{$algo}->($algo, $key, $signing_input);
}

sub sign_rsa {
    my $self = shift;
    my ($algo, $key, $msg) = @_;
    $algo =~ s/\D+//;
    my $private_key = Crypt::OpenSSL::RSA->new_private_key($key);
    $private_key->can("use_sha${algo}_hash")->($private_key);
    $private_key->sign($msg);
}

sub verify_rsa {
    my $self = shift;
    my ($algo, $key, $signing_input, $signature) = @_;
    $algo =~ s/\D+//;
    my $public_key = Crypt::OpenSSL::RSA->new_public_key($key);
    $public_key->can("use_sha${algo}_hash")->($public_key);
    $public_key->verify($signing_input, $signature);
}

sub sign_hmac {
    my $self = shift;
    my ($algo, $key, $msg) = @_;
    $algo =~ s/\D+//;
    my $method = $self->can("hmac_sha$algo");
    $method->($msg, $key);
}

1;
__END__

=head1 NAME

Acme::JWT - JWT utilities.

=head1 SYNOPSIS

  use Acme::JWT;

=head1 DESCRIPTION

Acme::JWT is provided JWT method.
JWT is JSON Web Token
see http://self-issued.info/docs/draft-jones-json-web-token-06.html

rewrite from ruby version.

=head1 AUTHOR

NAGAYA Shinichiro E<lt>clairvy@gmail.comE<gt>

=head1 SEE ALSO

https://github.com/clairvy/p5-Acme-JWT

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
