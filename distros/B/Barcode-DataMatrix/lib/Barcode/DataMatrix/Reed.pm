package Barcode::DataMatrix::Reed;

=head1 NAME

Barcode::DataMatrix::Reed - Renamed version of Algorithm::DataMatrix::Reed

=head1 DESCRIPTION

This is just a renamed version of Algorithm::DataMatrix::Reed
by Mons Anderson
from http://code.google.com/p/perl-ex/

For a rough explanation of the structure of this code, see
L<https://en.wikiversity.org/wiki/Reed%E2%80%93Solomon_codes_for_coders#Reed.E2.80.93Solomon_codes>.
Note that the link is not the basis of the implementation (this is unknown),
however it helps explain how Reed-Solomon encoding is implemented and hence
how the code below works.

=cut

use strict;
use warnings;
use Carp;

=head2 DEBUG

Control whether or not debugging output is printed.

=cut

sub DEBUG { 0 }

=head2 mult (x, y)

Multiply two Galois field element values and return the result.

=cut

sub mult {
	my ($x, $y) = @_;
	return 0 unless $x * $y;
	return $Barcode::DataMatrix::Constants::GFI[($Barcode::DataMatrix::Constants::GFL[$x] + $Barcode::DataMatrix::Constants::GFL[$y]) % 255];
}

=head2 encode (ai, j)

Encode the message array and return it.

=cut

sub encode {
	my ($ai,$j) = @_;
	my $i = @$ai;
	for (0..$#$ai) {
		( $ai->[$_] & 0xFF ) != $ai->[$_] and warn("number $ai->[$_] at index $_ is not a byte size"), $ai->[$_] = $ai->[$_] & 0xFF;
	}
	warn "CalcReed: ai [@$ai], $j\n" if DEBUG;

	my $p = exists $Barcode::DataMatrix::Constants::POLY{$j} ? $Barcode::DataMatrix::Constants::POLY{$j} : $Barcode::DataMatrix::Constants::POLY{68};
	warn "CalcReed: poly [@$p]\n" if DEBUG;

	@$ai[ $i .. $i + $j - 1 ] = (0) x $j;
	for my $l(0 .. $i - 1) {
		my $word0 = ($ai->[$i] ^ $ai->[$l]);
		for my $i1 (0 .. $j - 2) {
			$ai->[$i + $i1] = ( $ai->[$i + $i1 + 1] ^ mult($word0, $p->[$i1]) );
		}
		$ai->[$i+$j-1] = mult($word0, $p->[$j - 1]);
	}
	warn "CalcReed: result [@$ai]\n" if DEBUG;
	return $ai;
}

1;
