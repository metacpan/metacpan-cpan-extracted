package Crypt::Perl::X509::Extension::subjectKeyIdentifier;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::keyUsage

=head1 SYNOPSIS

    my $usage_obj = Crypt::Perl::X509::Extension::subjectKeyIdentifier->new(
        $subj_key_id    #octet string
    );

=head1 SEE ALSO

L<https://tools.ietf.org/html/rfc5280#section-4.2.1.2>

=cut

use parent qw( Crypt::Perl::X509::Extension );

use Crypt::Perl::X ();

use constant {
    OID => '2.5.29.14',
    CRITICAL => 0,
};

use constant ASN1 => <<END;
    subjectKeyIdentifier ::= OCTET STRING
END

sub new {
    my ($class, $octet_str) = @_;

    if (!length $octet_str) {
        die Crypt::Perl::X::create('Generic', 'Need data!');
    }

    return bless \$octet_str, $class;
}

sub _encode_params {
    my ($self) = @_;

    return $$self;
}

1;
