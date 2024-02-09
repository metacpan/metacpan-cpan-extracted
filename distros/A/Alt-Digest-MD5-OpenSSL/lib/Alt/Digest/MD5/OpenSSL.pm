package Alt::Digest::MD5::OpenSSL;

use strict;
use warnings;

our $AUTHORITY = 'cpan:SKIM';
our $VERSION = 0.04;

1;

=pod

=encoding utf8

=head1 NAME

Alt::Digest::MD5::OpenSSL - Alternative Digest::MD5 based on OpenSSL.

=head1 DESCRIPTION

This is a modification of the Digest::MD5 module to remove bundled C code for
MD5 algorithm.

The main intention behind rewriting it to use the OpenSSL library is that the library is audited.

=head1 AUTHORS

The original MD5 interface was written by Neil Winton (N.Winton@axion.bt.co.uk).

The Digest::MD5 module is written by Gisle Aas <gisle@ActiveState.com>.

Michal Josef Špaček did the changes with OpenSSL.

=cut
