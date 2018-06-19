package Crypt::Perl::X509::InfoAccessBase;

use strict;
use warnings;

use parent qw( Crypt::Perl::X509::Extension );

use Crypt::Perl::X509::GeneralName ();
use Crypt::Perl::X ();

use constant ASN1 => Crypt::Perl::X509::GeneralName::ASN1() . <<END;
    InfoAccess ::= SEQUENCE OF AccessDescription

    AccessDescription ::= SEQUENCE {
        accessMethod    OBJECT IDENTIFIER,
        accessLocation  ANY -- GeneralName
    }
END

use constant {
    asn1_macro => 'InfoAccess',
    CRITICAL => 0,
};

sub new {
    my ($class, @accessDescrs) = @_;

    if (!@accessDescrs) {
        die Crypt::Perl::X::create('Generic', 'Need access descriptions!');
    }

    return bless \@accessDescrs, $class;
}

sub _encode_params {
    my ($self) = @_;

    my $data = [
        map {
            $self->can("OID_$_->[0]") or die( Crypt::Perl::X::create('Generic', "Unknown method: “$_->[0]”") );

            {
                accessMethod => $self->can("OID_$_->[0]")->(),
                accessLocation => Crypt::Perl::X509::GeneralName->new( @{$_}[1,2] )->encode(),
            }
        } @$self,
    ];

    return $data;
}

1;
