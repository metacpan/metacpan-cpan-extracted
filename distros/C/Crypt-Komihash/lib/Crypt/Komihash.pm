package Crypt::Komihash;

use strict;
use warnings;
use base qw(Exporter);
require XSLoader;

our $VERSION = '0.08';

XSLoader::load('Crypt::Komihash', $VERSION);

our @EXPORT_OK   = qw(komihash komihash_hex komirand_seed komirand64 get_rdtsc rdtsc_rand64);
our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

sub komihash_hex {
	my ($buf, $seed) = @_;

	$seed ||= 0;

	my $num = komihash($buf, $seed);
	my $ret = sprintf("%016llx", $num);

	return $ret;
}

1;

__END__

=head1 NAME

Crypt::Komihash - Komihash implementation in Perl

=head1 SYNOPSIS

  use Crypt::Komihash qw(komihash komihash_hex komirand_seed komirand64);

  my $input = "Hello world";
  my $seed  = 0;

  my $num     = komihash($input, $seed);     # 3745467240760726046
  my $hex_str = komihash_hex($input, $seed); # 33fa929c7367d21e

  komirand_seed($seed1, $seed2);
  my $rand    = komirand64();

=head1 DESCRIPTION

Komihash is a super fast modern hashing algorithm that converts strings into
64bit integers. Mainly designed for hash-table, hash-map, and bloom-filter
uses. As a bonus, Komihash also includes a pseudo random number generator.

Komihash: L<https://github.com/avaneev/komihash>

B<Note:> This module I<requires> a 64bit CPU

=head1 METHODS

=head3 B<$num = komihash($bytes, $seed = 0)>

returns 64bit integer hash for the given input and seed.

=head3 B<$hex = komihash_hex($bytes, $seed = 0)>

returns hex string hash for the given input and seed.

=head3 B<komirand_seed($seed1, $seed2)>

seed the Komirand PRNG with two 64bit unsigned integers

=head3 B<$num = komirand64()>

returns a random 64bit unsigned integer

=head1 BUGS

Submit issues on Github: L<https://github.com/scottchiefbaker/perl-Crypt-Komihash/issues>

=head1 SEE ALSO

=over

=item *

Crypt::xxHash

=item *

Digest::FarmHash

=item *

Digest::SpookyHash

=item *

Digest::SHA

=back

=head1 AUTHOR

Scott Baker - L<https://www.perturb.org/>
