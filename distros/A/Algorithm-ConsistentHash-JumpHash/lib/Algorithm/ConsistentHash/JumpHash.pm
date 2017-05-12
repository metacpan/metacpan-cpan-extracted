package Algorithm::ConsistentHash::JumpHash;
use 5.008001;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.05';

require XSLoader;
XSLoader::load('Algorithm::ConsistentHash::JumpHash', $VERSION);

use Exporter 'import';
our @EXPORT_OK = qw(jumphash_numeric jumphash_siphash);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

1;
__END__

=head1 NAME

Algorithm::ConsistentHash::JumpHash - The jump consistent hash algorithm

=head1 SYNOPSIS

  use Algorithm::ConsistentHash::JumpHash qw(jumphash_numeric jumphash_siphash);
  
  my $bucket_num = jumphash_siphash($item_key, $nbuckets);

=head1 DESCRIPTION

The jump consistent hash algorithm is, according to its authors, "a fast, minimal memory,
consistent hashing algorithm." It's usable in most situations where a ring based
consistent hashing algorithm such as Ketama would have been used except that
it only supports numbered buckets (shards). The time complexity of the
algorithm is less than C<<O(ln(num_buckets))>>.

The string-key implementation currently uses the SipHash string hash function.

=head2 EXPORT

All functions documented below can be exported to your namespace using
standard Exporter semantics.

=head1 FUNCTIONS

=head2 jumphash_siphash

Given a string as key, and the number of buckets (or the number of shards), computes
and returns the id of the bucket that the key falls into. Buckets are numbered
from 0.

Uses SipHash to compute a 64bit integer from the string before using jumphash to
compute the bucket.

=head2 jumphash_numeric

As jumphash_siphash, takes a key and a number of buckets and computes and returns
the id of the bucket that the key falls into. However, the SipHash step is
skipped and the key needs to be a (64bit) unsigned integer.

=head1 CAVEATS

64bit. Portability?

=head1 SEE ALSO

The jumphash note at L<http://arxiv.org/pdf/1406.2294.pdf>. Much recommended read, great fun.

SipHash string hash function: L<http://en.wikipedia.org/wiki/SipHash>

For alternative consistent hash algorithms/implementations, search CPAN, but here's some:

L<Algorithm::ConsistentHash::CHash>

L<Algorithm::ConsistentHash::Ketama>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

