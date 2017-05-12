package Crypt::Perl::PKCS10::Attribute::challengePassword;

=encoding utf-8

=head1 NAME

Crypt::Perl::PKCS10::Attribute::challengePassword

=head1 SYNOPSIS

    my $chpw = Crypt::Perl::PKCS10::Attribute::challengePassword->new($passwd);

=head1 SECURITY

This attribute stores a phrase B<UNENCRYPTED> in the CSR. Don’t put
anything in here that you consider sensitive!

It’s likely that you don’t need this attribute.
Check with your Certificate Authority to find out for sure sure if
you need to include this in your CSR.

=head1 DESCRIPTION

Instances of this class represent a C<challengePassword> attribute of a
PKCS #10 Certificate Signing Request (CSR).

You probably don’t need to
instantiate this class directly; instead, you can instantiate it
implicitly by listing out arguments to
L<Crypt::Perl::PKCS10>’s constructor. See that module’s
L<SYNOPSIS|Crypt::Perl::PKCS10/SYNOPSIS> for an example.

=cut

use strict;
use warnings;

use parent qw( Crypt::Perl::PKCS10::Attribute );

use constant OID => '1.2.840.113549.1.9.7';

use constant ASN1 => <<END;
    challengePassword ::= CHOICE {
        password UTF8String
    }
END

sub new {
    my ($class, $passwd) = @_;

    return bless \$passwd, $class;
}

sub _encode_params {
    my ($self) = @_;

    return {
        password => "$$self",
    };
}

1;
