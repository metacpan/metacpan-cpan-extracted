package Crypt::Perl::X509::Extension::tlsFeature;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::tlsFeature

=head1 SYNOPSIS

    my $usage_obj = Crypt::Perl::X509::Extension::tlsFeature->new( 5 );

=head1 SEE ALSO

L<https://tools.ietf.org/pdf/rfc7633.pdf>

=cut

use parent qw( Crypt::Perl::X509::Extension );

use constant OID => '1.3.6.1.5.5.7.1.24';

use constant CRITICAL => 0;

use constant ASN1 => <<END;
    tlsFeature ::= SEQUENCE OF INTEGER
END

use Crypt::Perl::X ();

#OpenSSL crypto/x509v3/v3_tlsf.c
my %values = (
    status_request    => 5,
    status_request_v2 => 17,
);

sub new {
    my ($class, @strs) = @_;

    my @ints;
    for my $v (@strs) {
        if (!$values{$v}) {
            die Crypt::Perl::X::create('Generic', "Unknown TLS feature string: “$v”");
        }

        push @ints, $values{$v};
    }

    return bless \@ints, $class;
}

sub _encode_params {
    my ($self) = @_;

    return [ @$self ];
}

1;
