package Crypt::Perl::X509::Extension::extKeyUsage;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::extKeyUsage

=cut

use parent qw( Crypt::Perl::X509::Extension );

use Crypt::Perl::X ();

use constant OID => '2.5.29.37';

use constant ASN1 => <<END;
    extKeyUsage ::= SEQUENCE OF KeyPurposeId

    KeyPurposeId ::= OBJECT IDENTIFIER
END

use constant {
    OID_serverAuth => '1.3.6.1.5.5.7.3.1',
    OID_clientAuth => '1.3.6.1.5.5.7.3.2',
    OID_codeSigning => '1.3.6.1.5.5.7.3.3',
    OID_emailProtection => '1.3.6.1.5.5.7.3.4',
    OID_timeStamping => '1.3.6.1.5.5.7.3.8',
    OID_OCSPSigning => '1.3.6.1.5.5.7.3.9',
};

sub new {
    my ($class, @purposes) = @_;

    if (!@purposes) {
        die Crypt::Perl::X::create('Generic', 'Need purposes!');
    }

    return bless \@purposes, $class;
}

sub _encode_params {
    my ($self) = @_;

    my $data = [
        map {
            if ( !$self->can("OID_$_") ) {
                die( Crypt::Perl::X::create('Generic', "Unknown usage: “$_”") ),
            }

            $self->can("OID_$_")->();
        } @$self,
    ];

    return $data;
}

1;
