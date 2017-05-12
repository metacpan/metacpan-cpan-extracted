package Crypt::RSA::Parse::Convert_ASN1;

use parent 'Convert::ASN1';

sub prepare_or_die {
    my ( $self, $asn1_r ) = ( $_[0], \$_[1] );

    my $ret = $self->prepare($$asn1_r);

    if ( !defined $ret ) {
        die sprintf( "Failed to prepare ASN.1 description: %s", $self->error() );
    }

    return $ret;
}

sub find_or_die {
    my ( $self, $macro ) = @_;

    return $self->find($macro) || do {
        die sprintf( "Failed to find ASN.1 macro “$macro”: %s", $self->error() );
    };
}

1;
