package Crypt::RSA::Parse::Parser;

use Crypt::RSA::Parse::Convert_ASN1 ();
use Crypt::RSA::Parse::KeyBase ();
use Crypt::RSA::Parse::Private ();
use Crypt::RSA::Parse::Public ();
use Crypt::RSA::Parse::Template ();

our $_BASE64_MODULE;
*_BASE64_MODULE = \$Crypt::RSA::Parse::BASE64_MODULE;

sub new {
    my ($class) = @_;

    my $asn1 = Crypt::RSA::Parse::Convert_ASN1->new();
    $asn1->prepare_or_die( Crypt::RSA::Parse::Template::get_template($class->_TEMPLATE_TYPE()) );

    return bless { _asn1 => $asn1 }, $class;
}

sub _ensure_der {
    my ($pem_or_der_r) = \$_[0];

    if ( $$pem_or_der_r =~ m<\A-> ) {
        _pem_to_der($$pem_or_der_r);
    }

    return;
}

sub _decode_macro {
    my ( $self, $der_r, $macro ) = ( shift, \$_[0], $_[1] );

    my $parser = $self->{'_asn1'}->find_or_die($macro);

    return $parser->decode($$der_r);
}

sub private {
    my ($self, $pem_or_der) = @_;

    _ensure_der($pem_or_der);

    my $parsed = $self->_decode_rsa($pem_or_der) || do {
        my $pkcs8 = $self->_decode_pkcs8($pem_or_der) or do {
            die sprintf( "Failed to parse as either RSA or PKCS8: %s", $self->{'_asn1'}->error() );
        };

        $self->_decode_rsa_within_pkcs8_or_die($pkcs8);
    };

    return $self->_new_private($parsed);
}

#Like private(), but only does PKCS8.
sub private_pkcs8 {
    my ($self, $pem_or_der) = @_;

    _ensure_der($pem_or_der);

    my $pkcs8 = $self->_decode_pkcs8($pem_or_der) or do {
        die sprintf("Failed to parse PKCS8!");
    };

    my $parsed = $self->_decode_rsa_within_pkcs8_or_die($pkcs8);

    return $self->_new_private($parsed);
}

#Checks for RSA format first, then falls back to PKCS8.
sub public {
    my ($self, $pem_or_der) = @_;

    _ensure_der($pem_or_der);

    my $parsed = $self->_decode_rsa_public($pem_or_der) || do {
        my $pkcs8 = $self->_decode_pkcs8_public($pem_or_der) or do {
            die sprintf( "Failed to parse as either RSA or PKCS8: %s", $self->{'_asn1'}->error() );
        };

        $self->_decode_rsa_public_within_pkcs8_or_die($pkcs8);
    };

    return $self->_new_public($parsed);
}

#Like public(), but only does PKCS8.
sub public_pkcs8 {
    my ($self, $pem_or_der) = @_;

    _ensure_der($pem_or_der);

    my $pkcs8 = $self->_decode_pkcs8_public($pem_or_der) or do {
        die sprintf( "Failed to parse PKCS8: %s", $self->{'_asn1'}->error() );
    };

    my $parsed = $self->_decode_rsa_public_within_pkcs8_or_die($pkcs8);

    return $self->_new_public($parsed);
}

#Checks for RSA format first, then falls back to PKCS8.
sub _decode_rsa {
    my ($self, $der_r) = (shift, \$_[0]);

    return $self->_decode_macro( $$der_r, 'RSAPrivateKey' );
}

sub _decode_rsa_public {
    my ($self, $der_r) = (shift, \$_[0]);

    return $self->_decode_macro( $$der_r, 'RSAPublicKey' );
}

sub _decode_rsa_within_pkcs8_or_die {
    my ($self, $pkcs8_hr) = @_;

    return $self->_decode_rsa( $pkcs8_hr->{'privateKey'} ) || do {
        die sprintf("Failed to parse RSA within PKCS8!");
    };
}

sub _decode_rsa_public_within_pkcs8_or_die {
    my ($self, $pkcs8_hr) = @_;

    return $self->_decode_rsa_public( $pkcs8_hr->{'subjectPublicKey'}[0] ) || do {
        die sprintf("Failed to parse RSA within PKCS8!");
    };
}

sub _decode_pkcs8 {
    my ($self, $der_r) = (shift, \$_[0]);

    return $self->_decode_macro( $$der_r, 'PrivateKeyInfo' );
}

sub _decode_pkcs8_public {
    my ($self, $der_r) = (shift, \$_[0]);

    return $self->_decode_macro( $$der_r, 'SubjectPublicKeyInfo' );
}

sub _new_public {
    my ($self, $parsed_hr) = @_;

    local $parsed_hr->{'exponent'} = $parsed_hr->{'publicExponent'};

    return Crypt::RSA::Parse::Public->new($parsed_hr);
}

sub _new_private {
    my ($self, $parsed_hr) = @_;

    return Crypt::RSA::Parse::Private->new($parsed_hr);
}

#Modifies in-place.
sub _pem_to_der {
    local $Cpanel::Format::BASE64_MODULE = $_BASE64_MODULE;
    $_[0] = Crypt::Format::pem2der(@_);

    return;
}

1;
