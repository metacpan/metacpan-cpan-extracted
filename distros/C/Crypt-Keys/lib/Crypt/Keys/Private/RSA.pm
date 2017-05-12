# $Id: RSA.pm,v 1.1 2001/07/12 16:23:52 btrott Exp $

1;
__END__

=head1 NAME

Crypt::Keys::Private::RSA - RSA private key drivers

=head1 SYNOPSIS

This document describes the format of the key data returned from
RSA private keyfile drivers.

=head1 DESCRIPTION

All I<Crypt::Keys::Private::RSA> drivers (no matter the encoding)
will return a data structure containing the same format. That
structure will be a reference to a hash, containing a key C<Data>;
the value of the key C<Data> is another hash reference, which
contains the actual key data. This hash reference has the following
keys:

=over 4

=item * n

=item * e

=item * d

=item * p

=item * q

These fields should all be self-explanatory. They are standard parts
of a private RSA key.

=item * dp

Equal to C<d mod (p-1)>.

=item * dq

Equal to C<d mod (q-1)>.

=item * iqmp

Equal to C<inverse of q mod p>.

These last three fields are used in the Chinese Remainder Theorem.

=back

=head1 AUTHOR & COPYRIGHTS

Please see the Crypt::Keys manpage for author, copyright,
and license information.

=cut
