package Business::GoCardless::Utils;

=head1 NAME

Business::GoCardless::Utils

=head1 DESCRIPTION

A role containing gocardless utilities.

=cut

use strict;
use warnings;

use Moo::Role;

use MIME::Base64 qw/ encode_base64 /;
use Digest::SHA qw/ hmac_sha256_hex /;

our $max_legacy_params_size = 1024 * 1024;

=head1 METHODS

=head2 sign_params

Signs the passed params hash using the app secret

    my $signature = $self->sign_params( \%params,$app_secret );

=cut

sub sign_params {
    my ( $self,$params,$app_secret ) = @_;

    return hmac_sha256_hex(
        $self->normalize_params( $params ),
        $app_secret
    );
}

=head2 signature_valid

Checks the signature is valid for the given params hash with the app secret

    if ( ! $self->signature_valid( \%params,$app_secret ) ) {
        # throw an error
    }

A params hash that would flatten to more than
C<$Business::GoCardless::Utils::max_legacy_params_size> bytes of keys and
values (default 1 MiB, 0 for no limit) is not valid, as checking it would
cost time and memory quadratic in its size. An undef or empty secret never
validates a signature.

=cut

sub signature_valid {
    my ( $self,$params,$app_secret,$sig ) = @_;

    # for testing, use live at your own risk
    return 1 if $ENV{GOCARDLESS_SKIP_SIG_CHECK};

    # more than one secret (e.g. when rotating the secret), any can match
    if ( ref( $app_secret ) eq 'ARRAY' ) {
        foreach my $secret ( @{ $app_secret } ) {
            return 1 if $self->signature_valid( $params,$secret,$sig );
        }
        return 0;
    }

    # with no key anyone can compute the signature
    return 0 if ! defined( $app_secret ) || ! length( $app_secret );

    if ( $sig ) { # version > 1 (since we don't have access to ->client here)
        return $sig eq hmac_sha256_hex( $params,$app_secret );
    } else {
        # delete local is 5.12+ only so need to copy hash here
        my $params_copy = { %{ $params } };
        $sig = delete( $params_copy->{signature} );
        return 0 if $max_legacy_params_size
            && _flattened_size( $params_copy,$max_legacy_params_size )
                > $max_legacy_params_size;
        return $sig eq $self->sign_params( $params_copy,$app_secret );
    }
}

=head2 generate_nonce

Generates a random nonce for use with a gocardless request, it being a base64
encoded concatination of the current seconds since epoch + | + rand(256)

    my $nonce = $self->generate_nonce;

=cut

sub generate_nonce {
    my ( $self ) = @_;

    chomp( my $nonce = encode_base64( time . '|' . rand(256) ) );
    return $nonce;
}

=head2 flatten_params

Flattens a hash as specified by the gocardless API. see
https://developer.gocardless.com/#constructing-the-parameter-array

    my $flat_params = $self->flatten_params( \%params );

=cut

sub flatten_params {
    my ( $self,$params ) = @_;

    return [
        map { _flatten_param( $_,$params->{$_} ) }
        sort keys( %{ $params } )
    ];
}

=head2 normalize_params

Normalizes the passed params hash into a string for use in queries to the
gocardless API. Includes param flattening and RFC5849 encoding

    my $query_string = $self->normalize_params( \%params );

=cut

sub normalize_params {
    my ( $self,$params ) = @_;

    return join( '&',
        map { $_->[0] . '=' . $_->[1]  }
        map { [ _rfc5849_encode( $_->[0] ),_rfc5849_encode( $_->[1] ) ] }
        sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] }
        @{ ref( $params ) eq 'HASH'
            ? $self->flatten_params( $params )
            : ( $params // [] )
        }
    );
}

sub _flatten_param { 
    my( $key,$value ) = @_;

    my @r;

    if ( ref( $value ) eq 'HASH' ) {
        foreach my $sub_key ( sort keys( %{ $value } ) ) {
            push( @r,_flatten_param( "$key\[$sub_key\]",$value->{$sub_key} ) );
        } 
    } elsif ( ref( $value ) eq 'ARRAY' ) {
        foreach my $sub_key ( @{ $value } ) {
            push( @r,_flatten_param( "$key\[\]",$sub_key ) );
        } 
    } else {
        push( @r,[ $key,$value ] );
    }

    return @r;
}

# the bytes of the keys (one per hash, array and leaf) and values that
# flatten_params builds, counted until they pass $limit
sub _flattened_size {
    my ( $params,$limit ) = @_;

    my $size = 0;
    my @todo = map { [ length( $_ ),$params->{$_} ] } keys( %{ $params } );

    while ( my $item = pop( @todo ) ) {
        my ( $key_length,$value ) = @{ $item };

        $size += $key_length;
        return $size if $size > $limit;

        if ( ref( $value ) eq 'HASH' ) {
            push( @todo,map { [ $key_length + length( $_ ) + 2,$value->{$_} ] } keys( %{ $value } ) );
        } elsif ( ref( $value ) eq 'ARRAY' ) {
            push( @todo,map { [ $key_length + 2,$_ ] } @{ $value } );
        } else {
            $size += length( $value // '' );
        }
    }

    return $size;
}

sub _rfc5849_encode {
    my ( $str ) = @_;

    $str =~ s#([^-.~_a-z0-9])#sprintf('%%%02X', ord($1))#gei;
    return $str;
}

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
