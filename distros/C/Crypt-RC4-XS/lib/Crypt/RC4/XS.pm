package Crypt::RC4::XS;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(RC4);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Crypt::RC4::XS', $VERSION);


1;
__END__

=head1 NAME

Crypt::RC4::XS - Perl implementation of the RC4 encryption algorithm

=head1 SYNOPSIS

  use Crypt::RC4::XS;
  # Functional Style
  my $encrypted = RC4($passphrase, $plaintext);
  my $decrypted = RC4($passphrase, $encrypted);
  
  # OO Style
  my $cipher = Crypt::RC4->new($passphrase);
  my $encrypted = $cipher->RC4($plain_text);

=head1 DESCRIPTION

This module XS implementation of the RC4 algorithm, developed by RSA Security, Inc. Here is the description from Wikipedia website:

In cryptography, RC4 (also known as ARC4 or ARCFOUR meaning Alleged RC4, see below) is the most widely-used software stream cipher and is used in popular protocols such as Secure Sockets Layer (SSL) (to protect Internet traffic) and WEP (to secure wireless networks). While remarkable for its simplicity and speed in software, RC4 is vulnerable to attacks when the beginning of the output keystream is not discarded, or a single keystream is used twice; some ways of using RC4 can lead to very insecure cryptosystems such as WEP.


=head2 EXPORT

=over 4

=item RC4()

=back

=head1 SEE ALSO

L<Crypt::RC4>

=head1 AUTHOR

Hiroyuki OYAMA, E<lt>oyama@module.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
