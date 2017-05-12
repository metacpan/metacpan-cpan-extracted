#!/usr/bin/perl -w
package Asmens::Kodas;
use Exporter;
use strict;

our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/tikras/;
our $VERSION = 0.02;

=head1 NAME

Asmens::Kodas - Lithuanian personal (passport) number checking

=head1 SYNOPSIS

     use Asmens::Kodas qw/tikras/;
     print tikras("38208080214") ? "tinka" : "netinka";

=head1 DESCRIPTION

This module provides a subroutine that runs a few checks which ensure
that Lithuanian personal number (I<asmens kodas>) has a correct checksum
and has sane fields.

=head2 tikras

This subroutine does the actual checking. It returns 1 if the argument can possibly
be a correct Lithuanian personal number. Otherwise it returns 0.

=head1 AUTHOR

Petras Kudaras E<lt>moxliukas@delfi.ltE<gt>

=cut

sub tikras {
	return 0 unless $_[0] =~ /^\d{11}$/;
	my @what = split //, shift;
	return 0 unless $what[0] >= 1 and $what[0] <= 6;
	return 0 unless $what[10] == checksum(@what);
	return 0 unless $what[3] * 10 + $what[4] <= 12;
	return 0 unless $what[5] * 10 + $what[6] <= 31;
	1;
}

sub checksum {
	my $c = $_[0] + $_[1] * 2 + $_[2] * 3 + $_[3] * 4 + $_[4] * 5 + $_[5] * 6;
	$c += $_[6] * 7 + $_[7] * 8 + $_[8] * 9 + $_[9];
	$c = $c % 11;
	return $c unless $c == 10;
	$c = $_[0] * 3 + $_[1] * 4 + $_[2] * 5 + $_[3] * 6 + $_[4] * 7 + $_[5] * 8;
	$c += $_[6] * 9 + $_[7] + $_[8] * 2 + $_[9] * 3;
	$c = $c % 11;
	return $c unless $c == 10;
	return 0;
}
1;
