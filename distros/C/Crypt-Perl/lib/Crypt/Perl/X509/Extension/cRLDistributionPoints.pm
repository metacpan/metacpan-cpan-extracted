package Crypt::Perl::X509::Extension::cRLDistributionPoints;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::cRLDistributionPoints

=head1 SEE ALSO

L<https://tools.ietf.org/html/rfc5280#section-4.2.1.13>

=cut

use parent qw( Crypt::Perl::X509::Extension );

use Crypt::Perl::ASN1::BitString ();
use Crypt::Perl::X509::GeneralNames ();
use Crypt::Perl::X509::RelativeDistinguishedName ();

use constant {
    OID => '2.5.29.31',
    CRITICAL => 0,
};

use constant ASN1 => Crypt::Perl::X509::GeneralNames::ASN1() . <<END;

    DistributionPointName ::= CHOICE {
        fullName                     ANY, -- [0] GeneralNames
        nameRelativeToCRLIssuer      ANY -- [1] RelativeDistinguishedName
    }

    DistributionPoint ::= SEQUENCE {
        distributionPoint       [0]     DistributionPointName OPTIONAL,
        reasons                 [1]     BIT STRING OPTIONAL,
        cRLIssuer                       ANY OPTIONAL -- [2] GeneralNames OPTIONAL
    }

    cRLDistributionPoints ::= SEQUENCE OF DistributionPoint
END

my @_ReasonFlags = qw(
    unused
    keyCompromise
    cACompromise
    affiliationChanged
    superseded
    cessationOfOperation
    certificateHold
    privilegeWithdrawn
    aACompromise
);

sub new {
    my ($class, @points) = @_;

    my @self;

    for my $p (@points) {
        my %pp = %$p;
        push @self, \%pp;

        if ( $pp{'distributionPoint'} ) {
            my $dp = $pp{'distributionPoint'};

            if ($dp->{'fullName'}) {
                my $gns = Crypt::Perl::X509::GeneralNames->new( @{ $pp{'distributionPoint'}{'fullName'} } );

                $pp{'distributionPoint'} = {
                    fullName => $gns->encode(),
                };

                substr( $pp{'distributionPoint'}{'fullName'}, 0, 1, "\xa0" );
            }
            elsif ($dp->{'nameRelativeToCRLIssuer'}) {
                my $rdn = Crypt::Perl::X509::RelativeDistinguishedName->new( @{ $dp->{'nameRelativeToCRLIssuer'} } );

                $pp{'distributionPoint'} = {
                    nameRelativeToCRLIssuer => $rdn->encode(),
                };

                substr( $pp{'distributionPoint'}{'nameRelativeToCRLIssuer'}, 0, 1, "\xa1" );
            }
            else {
                my @keys = keys %$dp;
                die Crypt::Perl::X::create('Generic', "Unrecognized “distributionPoint” hash! (@keys)");
            }
        }

        if ( $pp{'reasons'} ) {
            $pp{'reasons'} = Crypt::Perl::ASN1::BitString::encode(
                \@_ReasonFlags,
                $pp{'reasons'},
            );
        }

        if ( $pp{'cRLIssuer'} ) {
            $pp{'cRLIssuer'} = Crypt::Perl::X509::GeneralNames->new( @{ $pp{'cRLIssuer'} } )->encode();
            substr( $pp{'cRLIssuer'}, 0, 1, "\xa2" );
        }
    }

    return bless \@self, $class;
}

sub _encode_params {
    my ($self) = @_;

    return [ @$self ];
}

1;
