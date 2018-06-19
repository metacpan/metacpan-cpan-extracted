package Crypt::Perl::PKCS10::Attribute::extensionRequest;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::PKCS10::Attribute::extensionRequest - CSR “extensionRequest” attribute

=head1 SYNOPSIS

    #Each object passed should be an instance of a subclass of
    #Crypt::Perl::X509::Extension
    my $exreq = Crypt::Perl::PKCS10::Attribute::extensionRequest->new( @EXTN_OBJS );

    #...or:

    my $exreq = Crypt::Perl::PKCS10::Attribute::extensionRequest->new(
        [ $extn_type1 => @args1 ],
        [ $extn_type2 => @args2 ],
    );

    #...for example:

    my $exreq = Crypt::Perl::PKCS10::Attribute::extensionRequest->new(
        [ 'subjectAltName',
            [ dNSName => 'foo.com' ],
            [ dNSName => 'haha.tld' ],
        ],
    );

=head1 DESCRIPTION

Instances of this class represent an C<extensionRequest> attribute of a
PKCS #10 Certificate Signing Request (CSR).

You probably don’t need to
instantiate this class directly; instead, you can instantiate it
implicitly by listing out arguments to
L<Crypt::Perl::PKCS10>’s constructor. See that module’s
L<SYNOPSIS|Crypt::Perl::PKCS10/SYNOPSIS> for an example.

Look in the L<Crypt::Perl> distribution’s
C<Crypt::Perl::X509::Extension> namespace for supported extensions.

=cut

use parent qw(
    Crypt::Perl::PKCS10::Attribute
    Crypt::Perl::X509::Extensions
);

use constant OID => '1.2.840.113549.1.9.14';

use constant asn1_macro => 'Extensions';

1;
