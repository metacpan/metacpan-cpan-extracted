package Crypt::Perl::PKCS10::Attributes;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::PKCS10::Attributes - CSR “attributes” collection

=head1 SYNOPSIS

    #Each object passed should be an instance of a subclass of
    #Crypt::Perl::PKCS10::Attribute (NB: not this class!)
    my $attrs = Crypt::Perl::PKCS10::Attributes->new( @ATTR_OBJS );

    #...or:

    my $attrs = Crypt::Perl::PKCS10::Attributes->new(
        [ $attr_type1 => \@args1 ],
        [ $attr_type2 => \@args2 ],
    );

    #...for example:

    my $attrs = Crypt::Perl::PKCS10::Attributes->new(
        [ challengePassword => 'iNsEcUrE' ],
    );

=head1 DESCRIPTION

Instances of this class represent the “attributes” collection in a
PKCS #10 Certificate Signing Request.

You probably don’t need to
instantiate this class directly; instead, you can instantiate it
implicitly by listing out arguments to
L<Crypt::Perl::PKCS10>’s constructor. See that module’s
L<SYNOPSIS|Crypt::Perl::PKCS10/SYNOPSIS> for an example.

The following X.509 extensions are supported:

=over 4

=item * L<extensionRequest|Crypt::Perl::X509::Attribute::extensionRequest>

=item * L<challengePassword|Crypt::Perl::X509::Attribute::challengePassword>
(Note that this attribute does B<NOT> encrypt anything; don’t encode any
values that are sensitive data!)

=back

=cut

use Try::Tiny;

use Crypt::Perl::X ();

use parent qw(
    Crypt::Perl::ASN1::Encodee
);

use constant ASN1 => <<END;
    Attributes ::= SET OF Attribute
    Attribute ::= SEQUENCE {
      type   OBJECT IDENTIFIER,
      values SET OF ANY
    }
END

my $ATTR_BASE = 'Crypt::Perl::PCKS10::Attribute';

sub new {
    my ($class, @attrs) = @_;

    for my $attr (@attrs) {
        if (!try { $attr->isa($ATTR_BASE) }) {
            if ( 'ARRAY' eq ref $attr ) {
                my $module = $attr->[0];
                my $class = "Crypt::Perl::PKCS10::Attribute::$module";
                Module::Load::load($class);
                $attr = $class->new( @{$attr}[ 1 .. $#$attr ] );
            }
            else {
                die Crypt::Perl::X::create('Generic', "Attribute must be ARRAY reference or instance of $ATTR_BASE, not “$attr”!");
            }
        }
    }

    return bless \@attrs, $class;
}

*structure = \&_encode_params;

sub _encode_params {
    my ($self) = @_;

    return [
        map {
            {
                type => $_->OID(),
                values => [ $_->encode() ],
            },
        } @$self
    ];
}

1;
