package Crypt::OpenSSL::PBKDF2;

use strict;
use Carp;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
use AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = qw( derive derive_bin );

$VERSION = '0.04';

bootstrap Crypt::OpenSSL::PBKDF2 $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Crypt::OpenSSL::PBKDF2 - wrapper for PBKDF2 keys derivation function of the OpenSSL library

=head1 SYNOPSIS

  use Crypt::OpenSSL::PBKDF2;

  $key1 = Crypt::OpenSSL::PBKDF2::derive($pass, $salt, $salt_len, $iter, $key_len);
  $key2 = Crypt::OpenSSL::PBKDF2::derive_bin($pass_bin, $pass_len, $salt, $salt_len, $iter, $key_len);

=head1 DESCRIPTION

Crypt::OpenSSL::PBKDF2 provides the ability to derive a key from a passphrase using OpenSSL library's PBKDF2 function

=head2 EXPORT

None by default.

=head1 Static Methods

=over 2

=item derive

This function returns a derived key that is supposed to be cryptographically strong.
The key will be generated from a passphrase B<$pass>, a salt block B<$salt> (usually binary data) of a given length B<$salt_len>, and a number of iterations B<$iter> (usually > 1000, suggested 4096). If the salt is empty (null) the salt length must be 0. The output is a binary data string of requested length B<$out_len>; the derive function croaks if any error occurs.

=item derive_bin

This function is like B<derive>, but accepts a binary password B<$pass_bin> of a given length B<$pass_len>. It's useful if you want to use an already hashed password for password. If password length is set to -1, then the password is assumed to be a string (like B<derive>) and length is automatically calculated; if used this way binary password are not allowed (or will be truncated on the first NUL occurrence).

=back 

=head1 SUPPORT

To get some help or report bugs you should try the forum on the offical project site at

L<http://www.opendiogene.it>

or you may try to contact the author.

=head1 AUTHOR

Riccardo Scussat - OpenDiogene Project E<lt>rscussat@dsplabs.netE<gt>

=head1 LICENSE

Crypt::OpenSSL::PBKDF2 is free software; you may redistribute it
and/or modify it under the terms of GNU GPLv2 (or later version) or Artistic License.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 COPYRIGHT

Copyright 2009-2015 R.Scussat - OpenDiogene Project.
=cut
