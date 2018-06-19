package Crypt::Perl::X509::Extension::subjectDirectoryAttributes;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::subjectDirectoryAttributes

=head1 NOTES

This module is B<EXPERIMENTAL>.

Are you sure you need this extension? Because OpenSSL doesn’t
seem to pay it much regard: C<man 5 x509v3_config> doesn’t
mention it, and I can’t find any certificates that use it.
Also, despite the fact that this module, as best I can tell,
implements the extension as it’s consistently described everywhere
I’ve found, OpenSSL doesn’t render this module’s output cleanly.
(i.e., when using the C<-text> flag of C<openssl x509>). Maybe there’s
a mistake in this module’s ASN.1 logic? It’s not complicated, so
I’m not sure what would be wrong.

In the absence of a parser against which to test this module’s
output, I’m a bit perplexed. Please drop me a line if you can shed
light on the situation.

=head1 SEE ALSO

L<https://tools.ietf.org/html/rfc5280#section-4.2.1.8>

=cut

use parent qw( Crypt::Perl::X509::Extension );

use Crypt::Perl::X509::Name ();

use constant {
    OID => '2.5.29.9',
    CRITICAL => 0,
};

use constant ASN1 => <<END;
    AttributeValue ::= ANY -- DEFINED BY AttributeType

    Attribute ::= SEQUENCE {
        type    OBJECT IDENTIFIER,
        values  SET OF AttributeValue -- at least one value is required
    }

    subjectDirectoryAttributes ::= SEQUENCE OF Attribute
END

sub new {
    my ($class, @attrs) = @_;

    my @self;

    for my $a_ar (@attrs) {
        my @cur = @$a_ar;

        my $type = shift @cur;

        $_ = Crypt::Perl::X509::Name::encode_string( $type, $_ ) for @cur;

        push @self, {
            type => Crypt::Perl::X509::Name::get_OID($type),
            values => \@cur,
        };
    }

    return bless \@self, $class;
}

sub _encode_params {
    my ($self) = @_;

    return [ @$self ];
}

1;
