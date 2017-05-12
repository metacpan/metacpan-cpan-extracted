# $Id: DSA.pm,v 1.2 2001/08/28 23:05:37 btrott Exp $

1;
__END__

=head1 NAME

Crypt::Keys::Private::DSA - DSA private key drivers

=head1 SYNOPSIS

This document describes the format of the key data returned from
DSA private keyfile drivers.

=head1 DESCRIPTION

All I<Crypt::Keys::Private::DSA> drivers (no matter the encoding)
will return a data structure containing the same format. That
structure will be a reference to a hash, containing a key C<Data>;
the value of the key C<Data> is another hash reference, which
contains the actual key data. This hash reference has the following
keys:

=over 4

=item * p

=item * q

=item * g

=item * pub_key

=item * priv_key

These fields should all be self-explanatory. They are standard parts
of a private DSA key. I<pub_key> and I<priv_key> are also referred to
as I<y> and I<x>, respectively.

=back

=head1 AUTHOR & COPYRIGHTS

Please see the Crypt::Keys manpage for author, copyright,
and license information.

=cut
