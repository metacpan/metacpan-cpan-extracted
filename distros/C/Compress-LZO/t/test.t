#! /usr/bin/env perl
##
## vi:ts=4
##
##---------------------------------------------------------------------------##
##
## This file is part of the LZO real-time data compression library.
##
## Copyright (C) 1998-2002 Markus Franz Xaver Johannes Oberhumer
## All Rights Reserved.
##
## The LZO library is free software; you can redistribute it and/or
## modify it under the terms of the GNU General Public License as
## published by the Free Software Foundation; either version 2 of
## the License, or (at your option) any later version.
##
## The LZO library is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with the LZO library; see the file COPYING.
## If not, write to the Free Software Foundation, Inc.,
## 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
##
## Markus F.X.J. Oberhumer
## <markus@oberhumer.com>
## http://www.oberhumer.com/opensource/lzo/
##
##---------------------------------------------------------------------------##


use Compress::LZO;


# /***********************************************************************
# // a very simple test driver...
# ************************************************************************/

sub ok {
	my ($no, $ok) = @_;
	## $total++;
	## $totalBad++ unless $ok;
	print "ok $no\n" if $ok;
	print "not ok $no\n" unless $ok;
}


sub test {
	my ($no, $src, $level) = @_;
	$level = 1 unless $level;

	my $a0 = Compress::LZO::adler32($src);
	my $c =  Compress::LZO::compress($src, $level);
	my $u1 = Compress::LZO::decompress($c);
	my $a1 = Compress::LZO::adler32($u1);
	my $o =  Compress::LZO::optimize($c);
	my $u2 = Compress::LZO::decompress($o);
	my $a2 = Compress::LZO::adler32($u2);

	## printf STDERR "%6d -> %6d (%6d)\n", length($src), length($c), length($o);

	&ok($no, defined($a0) && defined($a1) && defined($a2) &&
			 defined($c) && defined($u1) && defined($u2) && defined($o) &&
			 $src eq $u1 && $src eq $u2 && $a0 eq $a1 && $a0 eq $a2);
}


sub main {
	## printf STDERR "LZO version %s (0x%x), %s\n", LZO_VERSION_STRING, LZO_VERSION, LZO_VERSION_DATE;

	print "1..7\n";
	$i = 1;
	# compress some simple strings
	&test($i++, "aaaaaaaaaaaaaaaaaaaaaaaa");
	&test($i++, "abcabcabcabcabcabcabcabc");
	&test($i++, "abcabcabcabcabcabcabcabc", 9);
	&test($i++, " " x 131072);
	&test($i++, "");
	&test($i++, 1234567);		# integer
	&test($i++, 3.1415e10);		# double
}


&main();

