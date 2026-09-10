package Crypt::JWS::OpenSSL::Util::PEM;
$Crypt::JWS::OpenSSL::Util::PEM::VERSION = '0.005';
use Moo;
with qw(
    Crypt::JWS::OpenSSL::Role::Encoder
    Crypt::JWS::OpenSSL::Role::ECEncoder
);
use Crypt::OpenSSL::Random;
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::Bignum::CTX;
use Crypt::OpenSSL::EC;
use Carp qw( croak );
use namespace::clean;

my $ECC_NID_MAP = {
    'ES256' => 415,
    'ES384' => 715,
    'ES512' => 716,
};

has '_version_supports_pkcs8_x509' => ( is => 'lazy' );

sub generate_rsa_key_pair {
    my( $self, $bits) = @_;
    $bits ||= 2048;
    if ($bits < 1024 ) {
        croak 'minimum size of RSA key supported is 1024 bits';
    }
    
    if ($bits > 4096 ) {
        croak 'maximum size of RSA key supported is 4096 bits';
    }
    
    my $rsa = Crypt::OpenSSL::RSA->generate_key($bits);
    
    my ( $private_pem, $public_pem );
    
    if ( $self->_version_supports_pkcs8_x509 ) {
        $private_pem = $rsa->get_private_key_pkcs8_string();
        $public_pem = $rsa->get_public_key_x509_string();
    } else {
        $private_pem = $rsa->get_private_key_string();
        $public_pem = $rsa->get_public_key_string();
    }
    
    return ( wantarray ) ? ( $private_pem, $public_pem ) : [ $private_pem, $public_pem ];
}

sub generate_ecc_key_pair {
    my( $self, $alg) = @_;
    
    $alg ||= 'none';
    
    unless ( $alg =~ m{^ES(256|384|512)$} ) {
        croak qq(invalid alg '$alg' for pem key generation);
    }
    
    my $nid = $ECC_NID_MAP->{$alg};
    
    my $group = Crypt::OpenSSL::EC::EC_GROUP::new_by_curve_name($nid);
    my $ctx   = Crypt::OpenSSL::Bignum::CTX->new();
    my $order = Crypt::OpenSSL::Bignum->zero;
    $group->get_order( $order, $ctx );
    my $eckey = Crypt::OpenSSL::EC::EC_KEY::new();
    $eckey->set_group($group);
    $eckey->generate_key();
    my $d = $eckey->get0_private_key();
    my $p = $eckey->get0_public_key();
    
    my $x = Crypt::OpenSSL::Bignum->new;
    my $y = Crypt::OpenSSL::Bignum->new;
    
    Crypt::OpenSSL::EC::EC_POINT::get_affine_coordinates_GFp($group, $p, $x, $y, $ctx);
    
    my $private_ref = $self->private_ecc_key_der($alg, $x->to_bin, $y->to_bin, $d->to_bin);
    my $private_pem = $self->encode_ecc_private_key_pem($$private_ref);
    my $public_ref  = $self->public_ecc_key_der($alg, $x->to_bin, $y->to_bin);
    my $public_pem =  $self->encode_ecc_public_key_pem($$public_ref);
    
    return ( wantarray ) ? ( $private_pem, $public_pem ) : [ $private_pem, $public_pem ];
}

sub _build__version_supports_pkcs8_x509 {
    my $self = shift;
    my $checkversion = $self->numify_version($Crypt::OpenSSL::RSA::VERSION);
    return ( $checkversion >= 0.38 ) ? 1 : 0;   
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::JWS::OpenSSL::Util::PEM - Utility to generate pem encoded keys.

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Crypt::JWS::OpenSSL::Util::PEM;
  
  my $gen = Crypt::JWS::OpenSSL::Util::PEM->new;
  
  my( $private_rsa_pem, $public_rsa_pem ) = $gen->generate_rsa_key_pair(2048);
  
  my( $private_ecc_pem, $public_ecc_pem ) = $gen->generate_ecc_key_pair('ES384');

=head1 DESCRIPTION

Generate pem encoded keys suitable for algorithms supported by L<Crypt::JWS::OpenSSL>.

=head1 METHODS

=head2 generate_rsa_key_pair($bits)

Returns an array containing private and public keys. In a scalar context, returns a reference to the array.

The keys support signing using algorithms C<RS256, RS384, RS512, PS256, PS384 and PS512>.

=over

=item C<bits>

Accepts bits in the range C<1024> to C<4096>

=back

=head2 generate_ecc_key_pair($algorithm)

Returns an array containing private and public keys. In a scalar context, returns a reference to the array.

The keys support signing using algorithms C<ES256, ES384 and ES512>.

=over

=item C<algorithm>

Accepts an algorithm name to indicate the curve required. C<ES256, ES384 or ES512>.

=back

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson

This library is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

=cut
