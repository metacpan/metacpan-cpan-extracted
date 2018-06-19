package Crypt::Perl::X509::Extension::nameConstraints;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::nameConstraints

=head1 SYNOPSIS

    my $usage_obj = Crypt::Perl::X509::Extension::nameConstraints->new(
        permitted => [
            [ dNSName => 'haha.tld', 1, 4 ],    #min, max
        ],
        excluded => [
            [ dNSName => 'fofo.tld', 7 ],
            [ rfc822Name => 'haha@fofo.tld' ],
        ],
    );

=head1 SEE ALSO

L<https://tools.ietf.org/html/rfc5280#section-4.2.1.2>

=cut

use parent qw( Crypt::Perl::X509::Extension );

use Crypt::Perl::X509::GeneralName ();

use constant OID => '2.5.29.30';

use constant CRITICAL => 1;

use constant ASN1 => Crypt::Perl::X509::GeneralName::ASN1() . <<END;
    BaseDistance ::= INTEGER -- (0..MAX)

    GeneralSubtree ::= SEQUENCE {
        base                    ANY,
        minimum         [0]     BaseDistance, -- DEFAULT 0,
        maximum         [1]     BaseDistance OPTIONAL
    }

    -- GeneralSubtrees ::= SEQUENCE SIZE (1..MAX) OF GeneralSubtree
    GeneralSubtrees ::= SEQUENCE OF GeneralSubtree

    nameConstraints ::= SEQUENCE {
        permittedSubtrees       [0]     GeneralSubtrees OPTIONAL,
        excludedSubtrees        [1]     GeneralSubtrees OPTIONAL
    }

END

sub new {
    my ($class, %opts) = @_;

    my %self;

    for my $k ( qw( permitted excluded ) ) {
        my $subtrees_ar = $opts{$k} or next;

        my @subtrees;

        for my $i ( @$subtrees_ar ) {
            my %i_cp = (
                base => Crypt::Perl::X509::GeneralName->new( @{$i}[0, 1] )->encode(),
                minimum => $i->[2] || 0,
                (defined($i->[3]) ? ( maximum => $i->[3] ) : () ),
            );

            push @subtrees, \%i_cp;
        }

        $self{"${k}Subtrees"} = \@subtrees;
    }


    return bless \%self, $class;
}

sub _encode_params {
    my ($self) = @_;

    return { %$self };
}

1;
