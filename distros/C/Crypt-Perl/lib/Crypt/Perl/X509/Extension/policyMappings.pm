package Crypt::Perl::X509::Extension::policyMappings;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::policyMappings - X.509 policyMappings extension

=head1 SEE ALSO

L<https://tools.ietf.org/html/rfc5280#section-4.2.1.5>

=cut

use parent qw( Crypt::Perl::X509::Extension );

use constant {
    OID => '2.5.29.33',
    OID_anyPolicy => '2.5.29.32.0',
    CRITICAL => 1,
};

use constant ASN1 => <<END;
    policyMappings ::= SEQUENCE OF SEQUENCE {
        issuerDomainPolicy  OBJECT IDENTIFIER,
        subjectDomainPolicy OBJECT IDENTIFIER
    }
END

sub new {
    my ($class, @mappings) = @_;

    my @self;

    for my $m_hr (@mappings) {
        my %cur;

        for my $k ( qw( issuer subject ) ) {
            next if !defined $m_hr->{$k};

            my $oid = $class->can("OID_$m_hr->{$k}");
            $oid &&= $oid->();
            $oid ||= $m_hr->{$k};

            $cur{"${k}DomainPolicy"} = $oid;
        }

        push @self, \%cur;
    }

    return bless \@self, $class;
}

sub _encode_params {
    my ($self) = @_;

    return [ @$self ];
}

1;
