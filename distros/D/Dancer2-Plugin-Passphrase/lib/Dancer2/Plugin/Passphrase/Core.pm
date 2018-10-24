package Dancer2::Plugin::Passphrase::Core;
use strict;
use warnings;
use Carp qw(croak);
use Digest;
use MIME::Base64 qw(decode_base64 encode_base64);
use Data::Entropy::Algorithms qw(rand_bits rand_int);

# ABSTRACT: Passphrases and Passwords as objects for Dancer2

=head1 NAME

Dancer2::Plugin::Passphrase::Core - Core package for Dancer2::Plugin::Passphrase.

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>

=head1 AUTHOR

Maintainer: Henk van Oers <hvoers@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by James Aitken.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

sub new {
    my $class = shift;
    my @args  = @_;
    return bless { @args == 1 ? %{$args[0]} : @args }, $class;
}

# { algorithm => '...', this => '...' }
sub _merge_options {
    my $self      = shift;
    my $options   = shift;
    my $algorithm = $self->{'algorithm'};
    my $settings  = {};

    # if we got options
    if ($options) {
        $algorithm = delete $options->{'algorithm'};
        $settings =
          defined $options->{$algorithm}
          ? $options->{$algorithm}
          : $self->{$algorithm};
    }

    # Specify empty string to get an unsalted hash
    # Leaving it undefs results in 128 random bits being used as salt
    # bcrypt requires this amount, and is reasonable for other algorithms
    $settings->{'salt'} = rand_bits(128)
      unless defined $settings->{'salt'};

    # RFC 2307 scheme is based on the algorithm, with a prefixed 'S' for salted
    $settings->{'scheme'} = join '', $algorithm =~ /[\w]+/g;
    $settings->{'scheme'} = 'S'. $settings->{'scheme'}
        if $settings->{'salt'};

    if ( $settings->{'scheme'} eq 'SHA1' ) {
        $settings->{'scheme'} = 'SHA';
    } elsif ( $settings->{'scheme'} eq 'SSHA1' ) {
        $settings->{'scheme'} = 'SSHA';
    }

    # Bcrypt requires a cost parameter
    if ( $algorithm eq 'Bcrypt' ) {
        $settings->{'scheme'} = 'CRYPT';
        $settings->{'type'}   = '2a';
        $settings->{'cost'} =
          defined $settings->{'cost'} ? $settings->{'cost'} : 4;
        $settings->{'cost'}   = 31 if $settings->{'cost'} > 31;
        $settings->{'cost'}   = sprintf '%02d', $settings->{'cost'};
    }

    $settings->{'algorithm'} = $algorithm;
    $settings->{'plaintext'} = $self->{'plaintext'};

    return $settings;
}

# From Crypt::Eksblowfish::Bcrypt.
# Bcrypt uses it's own variation on base64
sub _en_bcrypt_base64 {
    my ($octets) = @_;
    my $text = encode_base64($octets, '');
    $text =~ tr{A-Za-z0-9+/=}{./A-Za-z0-9}d;
    return $text;
}


# And the decoder of bcrypt's custom base64
sub _de_bcrypt_base64 {
    my ($text) = @_;
    $text =~ tr{./A-Za-z0-9}{A-Za-z0-9+/};
    $text .= "=" x (3 - (length($text) + 3) % 4);
    return decode_base64($text);
}

# Extracts the settings from an RFC 2307 string
sub _extract_settings {
    my ($self, $rfc2307_string) = @_;
    my $settings = {};

    my ($scheme, $rfc_settings) = ($rfc2307_string =~ m/^{(\w+)}(.*)/s);

    unless ($scheme && $rfc_settings) {
        croak "An RFC 2307 compliant string must be passed to matches()";
    }

    if ($scheme eq 'CRYPT') {
        if ($rfc_settings =~ m/^\$2(?:a|x|y)\$/) {
            $scheme = 'Bcrypt';
            $rfc_settings =~ m{\A\$(2a|2x|2y)\$([0-9]{2})\$([./A-Za-z0-9]{22})}x;

            @{$settings}{qw<type cost salt>} = ( $1, $2, _de_bcrypt_base64($3) );
        } else {
            croak "Unknown CRYPT format";
        }
    }

    my $scheme_meta = {
        'MD5'     => { algorithm => 'MD5',     octets => 128 / 8 },
        'SMD5'    => { algorithm => 'MD5',     octets => 128 / 8 },
        'SHA'     => { algorithm => 'SHA-1',   octets => 160 / 8 },
        'SSHA'    => { algorithm => 'SHA-1',   octets => 160 / 8 },
        'SHA224'  => { algorithm => 'SHA-224', octets => 224 / 8 },
        'SSHA224' => { algorithm => 'SHA-224', octets => 224 / 8 },
        'SHA256'  => { algorithm => 'SHA-256', octets => 256 / 8 },
        'SSHA256' => { algorithm => 'SHA-256', octets => 256 / 8 },
        'SHA384'  => { algorithm => 'SHA-384', octets => 384 / 8 },
        'SSHA384' => { algorithm => 'SHA-384', octets => 384 / 8 },
        'SHA512'  => { algorithm => 'SHA-512', octets => 512 / 8 },
        'SSHA512' => { algorithm => 'SHA-512', octets => 512 / 8 },
        'Bcrypt'  => { algorithm => 'Bcrypt',  octets => 128 / 8 },
    };

    $settings->{'scheme'}    = $scheme;
    $settings->{'algorithm'} = $scheme_meta->{$scheme}{algorithm};
    $settings->{'plaintext'} = $self->{'plaintext'};;

    if ( !defined $settings->{'salt'} ) {
        $settings->{'salt'} = substr(
            decode_base64($rfc_settings),
            $scheme_meta->{$scheme}{octets},
        );
    }

    return $settings;
}

sub _calculate_hash {
    my ( $self, $settings ) = @_;
    my $hasher = Digest->new( $settings->{'algorithm'} );
    my ( $hash, $rfc2307 );

    if ( $settings->{'algorithm'} eq 'Bcrypt' ) {
        $hasher->add( $settings->{'plaintext'} );
        $hasher->salt( $settings->{'salt'} );
        $hasher->cost( $settings->{'cost'} );

        $hash    = $hasher->digest;
        $rfc2307 = '{CRYPT}$'
                 . $settings->{'type'} . '$'
                 . $settings->{'cost'} . '$'
                 . _en_bcrypt_base64( $settings->{'salt'} )
                 . _en_bcrypt_base64($hash);
    } else {
        $hasher->add( $settings->{'plaintext'} );
        $hasher->add( $settings->{'salt'} );

        $hash    = $hasher->digest;
        $rfc2307 = '{' . $settings->{'scheme'} . '}'
                 . encode_base64(
                       $hash . $settings->{'salt'},
                       ''
                   );
    }

    return Dancer2::Plugin::Passphrase::Hashed->new(
        hash    => $hash,
        rfc2307 => $rfc2307,
        %{$settings},
    );
}

sub generate {
    my $self     = shift;
    my $options  = shift;
    my $settings = $self->_merge_options($options);

    return $self->_calculate_hash($settings);
}

sub generate_random {
    my ($self, $options) = @_;

    # Default is 16 URL-safe base64 chars. Supported everywhere and a reasonable length
    my $length  = $options->{length}  || 16;
    my $charset = $options->{charset} || ['a'..'z', 'A'..'Z', '0'..'9', '-', '_'];

    return join '', map { @$charset[rand_int scalar @$charset] } 1..$length;
}

sub matches {
    my ($self, $stored_hash) = @_;

    my $settings = $self->_extract_settings($stored_hash);
    my $new_hash = $self->_calculate_hash($settings)->rfc2307;

    return ($new_hash eq $stored_hash) ? 1 : undef;
}

1;
