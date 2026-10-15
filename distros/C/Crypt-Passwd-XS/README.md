# NAME

Crypt::Passwd::XS - Full XS implementation of common crypt() algorithms

# SYNOPSIS

    use Crypt::Passwd::XS;

    my $plaintext = 'secret';
    my $salt      = '$1$1234';
    my $crypted   = Crypt::Passwd::XS::crypt( $plaintext, $salt );

# DESCRIPTION

This module provides several common crypt() schemes as full XS implementations.
It allows you to validate crypted passwords that were hashed using a scheme
that the system's native crypt() implementation does not support.

## Description of functions

The **crypt()** function handles all supported crypt methods using the standard
salt prefix system for determinging the crypt type.

The **unix\_md5\_crypt()** function performs a MD5 crypt regardless of the salt
prefix.

The **apache\_md5\_crypt()** function performs a APR1 crypt regardless of the salt
prefix.

The **unix\_des\_crypt()** funtion performs a traditional DES crypt regardless of
the salt prefix.

The **unix\_sha256\_crypt()** function performs a SHA256 crypt regardless of the
salt prefix.

The **unix\_sha512\_crypt()** function performs a SHA512 crypt regardless of the
salt prefix.

The **unix\_yescrypt\_crypt()** function performs a yescrypt (`$y$`) crypt
regardless of the salt prefix. The salt must be a full `$y$` setting such as
`$y$j9T$PKXc3hCOSyMqdaEQArI62/` (a complete stored hash is also accepted).
Generating new settings is not supported. It returns an empty string for a
malformed setting, a non-`$y$` setting (including scrypt `$7$`), and any
setting this module does not support: `p` greater than 1, a ROM or
hash-upgrade (`g`) parameter, `r` greater than 32, or a cost budget
`128 * r * N * (t + 1)` above 1 GiB. That covers every setting libxcrypt
generates, up to `$y$jFT$` (`t` = 0), which allocates 1 GiB and takes about a
second and a half. Peak memory is `128 * r * N` plus `384 * r` bytes and
12 KiB, so at most about 1 GiB plus 24 KiB. The default cost,
`$y$j9T$`, needs 16 MiB. Callers that check hashes an untrusted party can
write should limit how many checks run at once.

# TODO

The blowfish and Sun crypt() schemes are currently unsupported.

# AUTHOR

John Lightsey, <jd@cpanel.net>

# COPYRIGHT AND LICENSE

Copyright (C) 2011 cPanel, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

The following files are adapted from other sources (primarily DragonFly BSD.)
See the copyright notices in these files for full details:

crypt\_to64.c - copyright 1991 University of California

crypt\_to64.h - copyright 1991 University of California

des.c - copyright 1994 David Burren, Geoffrey M. Rehmet, Mark R V Murray

md5.c - copyright 1999, 2000, 2002 Aladdin Enterprises

md5.h - copyright 1999, 2000, 2002 Aladdin Enterprises

md5crypt.c - copyright Poul-Henning Kamp

md5crypt.h - copyright Poul-Henning Kamp

sha256crypt.c - public domain reference implementation by Ulrich Drepper

sha512crypt.c - public domain reference implementation by Ulrich Drepper

The yescrypt implementation is Openwall's yescrypt 1.1.0
([https://www.openwall.com/yescrypt/](https://www.openwall.com/yescrypt/)) by Alexander Peslyak, including SHA-256
and scrypt code by Colin Percival. The files are yescrypt.h, yescrypt-opt.c,
yescrypt-common.c, yescrypt-platform.c, sha256.c, sha256.h, insecure\_memzero.c,
insecure\_memzero.h and sysendian.h. They are lightly modified (each change is marked `cpx:`) and
are used under the BSD 2-clause terms in their headers; see the `Copyright`
file for the notices.
