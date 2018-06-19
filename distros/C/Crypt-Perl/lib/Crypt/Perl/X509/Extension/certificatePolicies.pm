package Crypt::Perl::X509::Extension::certificatePolicies;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::certificatePolicies

=head1 SYNOPSIS

    Crypt::Perl::X509::Extension::certificatePolicies->new(
        [ 'domain-validated' ],
        [ '1.3.6.1.4.1.6449.1.2.2.52',
            [ cps => 'http://cps.url' ],
            [ cps => 'http://cps.url2' ],
        ],
        [ '1.2.3.4.5.6.7.8',
            [ unotice => {

                #NB: “Conforming CAs SHOULD NOT use the noticeRef option.”
                noticeRef => {
                    organization => 'FooFoo',
                    noticeNumbers => [ 12, 23, 34 ],
                },

                explicitText => 'apple',
            } ],
        ],
    );

=cut

use parent qw( Crypt::Perl::X509::Extension );

use Crypt::Perl::X ();

use constant OID => '2.5.29.32';

use constant ASN1 => <<END;
    certificatePolicies ::= SEQUENCE OF PolicyInformation

    PolicyInformation ::= SEQUENCE {
        policyIdentifier  OBJECT IDENTIFIER,
        policyQualifiers  SEQUENCE OF PolicyQualifierInfo OPTIONAL
    }

    PolicyQualifierInfo ::= SEQUENCE {
        policyQualifierId   OBJECT IDENTIFIER,
        qualifier           ANY     -- DEFINED BY policyQualifierId
    }

    cpsValue ::= IA5String

    unoticeValue ::= SEQUENCE {
        noticeRef        NoticeReference OPTIONAL,
        explicitText     DisplayText OPTIONAL
    }

    NoticeReference ::= SEQUENCE {
        organization     DisplayText,
        noticeNumbers    SEQUENCE OF INTEGER
    }

    DisplayText ::= CHOICE {
        -- ia5String        IA5String      (SIZE (1..200)),
        -- visibleString    VisibleString  (SIZE (1..200)),
        -- bmpString        BMPString      (SIZE (1..200)),
        utf8String       UTF8String    -- (SIZE (1..200))
    }
END

my %qual_oid = (
    cps => '1.3.6.1.5.5.7.2.1',
    unotice => '1.3.6.1.5.5.7.2.2',
);

my %policy_oid = (
    'domain-validated' => '2.23.140.1.2.1',
    'organization-validated' => '2.23.140.1.2.2',
);

sub new {
    my ($class, @policies) = @_;

    if (!@policies) {
        die Crypt::Perl::X::create('Generic', 'Need policies!');
    }

    return bless \@policies, $class;
}

sub _encode_params {
    my ($self) = @_;

    my @data;

    for my $p (@$self) {
        my ( $p_oid, @quals ) = @$p;

        my $item = {
            policyIdentifier => $policy_oid{$p_oid} || $p_oid,
        };
        push @data, $item;

        if (@quals) {
            my @iquals;
            $item->{'policyQualifiers'} = \@iquals;

            for my $q (@quals) {
                my $q_oid = $q->[0];

                my $asn1 = Crypt::Perl::ASN1->new()->prepare($self->ASN1());
                $asn1 = $asn1->find( "${q_oid}Value" );

                my $val;
                if ( $q_oid eq 'unotice' ) {
                    $val = { %{ $q->[1] } };

                    if ($val->{'noticeRef'}) {
                        $val->{'noticeRef'} = { %{ $val->{'noticeRef'} } };
                        $val->{'noticeRef'}{'organization'} = {
                            utf8String => $val->{'noticeRef'}{'organization'},
                        };
                    }

                    if ($val->{'explicitText'}) {
                        $val->{'explicitText'} = {
                            utf8String => $val->{'explicitText'},
                        };
                    }
                }
                else {
                    $val = $q->[1];
                }

                $val = $asn1->encode( $val );

                push @iquals, {
                    policyQualifierId => $qual_oid{$q_oid},
                    qualifier => $val,
                };
            }
        }
    }

    return \@data;
}

1;
