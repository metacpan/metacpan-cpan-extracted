package Crypt::Caesar;
use base 'Exporter';
use strict;
use vars qw($VERSION @EXPORT);

$VERSION = '0.01';
@EXPORT = qw(caesar);

my %weight = qw(
    a  7.97  b  1.35  c  3.61  d  4.78  e 12.37  f  2.01  g  1.46  h  4.49
    i  6.39  j  0.04  k  0.42  l  3.81  m  2.69  n  5.92  o  6.96  p  2.91
    q  0.08  r  6.63  s  8.77  t  9.68  u  2.62  v  0.81  w  1.88  x  0.23
    y  2.07  z  0.06
);

$_ = log($_) + log(26/100) for values %weight;

sub caesar ($) {
    my ($string) = @_;
    my $copy = lc $string;
    $copy =~ tr/a-z//cd;
    return $string unless length $copy;
    my $winner = 0;
    my $winscore = 0;
    for my $i (1..26) {
	my $score = 0;
	$copy =~ tr/a-z/b-za/;
	$score += $weight{$_} for split //, $copy;
	if ($score > $winscore) {
	    $winner = $i;
	    $winscore = $score;
	}
    }
    $string =~ tr/A-Za-z/B-ZAb-za/ for 1..$winner;
    return $string;
}
			
1;

=head1 NAME

Crypt::Caesar - Decrypt rot-N strings

=head1 SYNOPSIS

    use Crypt::Caesar;
    print caesar("Vn tjp xvi nzz, do rjmfn.\n");

=head1 DESCRIPTION

This module is based on the caesar utility from the bsdgames package, made by
Stan King and John Eldridge, based on the algorithm suggested by Bob Morris.

The caesar utility attempts to decrypt caesar cyphers using English letter
frequency statistics.

=head2 C<caesar>

This is the only function this package provides. It is exported by default and
prototyped C<($)>.

=head1 AUTHOR

Juerd

=cut

