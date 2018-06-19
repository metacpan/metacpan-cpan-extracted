package Crypt::Perl::X509::Extension::policyConstraints;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::policyConstraints

=head1 SYNOPSIS

    my $usage_obj = Crypt::Perl::X509::Extension::policyConstraints->new(
        requireExplicitPolicy => 4,
        inhibitPolicyMapping => 6,
    );

=head1 SEE ALSO

L<https://tools.ietf.org/html/rfc5280#section-4.2.1.11>

=cut

use parent qw( Crypt::Perl::X509::Extension );

use constant OID => '2.5.29.36';

use constant CRITICAL => 1;

use constant ASN1 => <<END;
    SkipCerts ::= INTEGER

    policyConstraints ::= SEQUENCE {
        requireExplicitPolicy           [0] SkipCerts OPTIONAL,
        inhibitPolicyMapping            [1] SkipCerts OPTIONAL
    }
END

sub new {
    my ($class, %opts) = @_;

    return bless \%opts, $class;
}

sub _encode_params {
    my ($self) = @_;

    return { %$self };
}

1;
