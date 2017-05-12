package Crypt::OpenSSL::RC4;
use strict;
use warnings;
use Exporter 'import';
our $VERSION = '0.04';
our @EXPORT = qw/RC4/;

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub RC4 {
    if (ref $_[0]) {
        $_[0]->_rc4($_[1]);
    } else {
        my $rc4 = Crypt::OpenSSL::RC4->new($_[0]);
        $rc4->_rc4($_[1]);
    }
}

1;
__END__

=head1 NAME

Crypt::OpenSSL::RC4 - RC4 library based on OpenSSL

=head1 SYNOPSIS

    use Crypt::OpenSSL::RC4;
    # functional style
    my $encrypted = RC4($passphrase, $plaintext);
    my $decrypted = RC4($passphrase, $encrypted);

    # OO style
    my $cipher = Crypt::RC4->new($passphrase);
    my $encrypted = $cipher->RC4($plain_text);

=head1 DESCRIPTION

This module is wrapper class for OpenSSL. The interface is compatible with Crypt::RC4.

This module XS implementation of the RC4 algorithm, developed by RSA Security, Inc. Here is the description from Wikipedia website: http://en.wikipedia.org/wiki/RC4

In cryptography, RC4 (also known as ARC4 or ARCFOUR meaning Alleged RC4, see below) is the most widely-used software stream cipher and is used in popular protocols such as Secure Sockets Layer (SSL) (to protect Internet traffic) and WEP (to secure wireless networks). While remarkable for its simplicity and speed in software, RC4 is vulnerable to attacks when the beginning of the output keystream is not discarded, or a single keystream is used twice; some ways of using RC4 can lead to very insecure cryptosystems such as WEP.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom.gmailE<gt>

=head1 SEE ALSO

L<Crypt::RC4>, L<Crypt::RC4::XS>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
