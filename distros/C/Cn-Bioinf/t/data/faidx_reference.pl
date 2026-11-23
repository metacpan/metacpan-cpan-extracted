#!/usr/bin/env perl
# Prints what samtools faidx makes of the cases in t/faidx.t, for comparison
# with the literals there. The tests never run this. Run it from the
# distribution's root, with samtools on PATH (1.19.2, using htslib 1.19, when
# the values were frozen, 2026-11-11: Ubuntu's samtools 1.19.2-1build2):
#
#	perl t/data/faidx_reference.pl
#
# t/data/faidx.fa is test/faidx/faidx.fa of htslib 1.25, byte for byte (its
# SHA-256 is in t/faidx.t), and the index t/faidx.t expects for it is that
# directory's faidx.fa.expected.fai. htslib's test/faidx/faidx.tst, which
# drives those tests, carries this notice:
#
#	Copyright (C) 2022 Genome Research Ltd.
#
#	Author: Robert Davies <rmd@sanger.ac.uk>
#
#	Permission is hereby granted, free of charge, to any person obtaining a copy
#	of this software and associated documentation files (the "Software"), to deal
#	in the Software without restriction, including without limitation the rights
#	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#	copies of the Software, and to permit persons to whom the Software is
#	furnished to do so, subject to the following conditions:
#
#	The above copyright notice and this permission notice shall be included in
#	all copies or substantial portions of the Software.
#
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#	DEALINGS IN THE SOFTWARE.
use strict;
use warnings;
use File::Temp qw(tempdir);
use File::Copy qw(copy);
use File::Spec::Functions qw(catfile);

my $dir = tempdir(CLEANUP => 1);
my $fa = catfile($dir, 'faidx.fa');
copy('t/data/faidx.fa', $fa) or die "can't copy t/data/faidx.fa: $!\n";

# What samtools prints when run with @args, on both streams, and how it exited
sub samtools {
	my (@args) = @_;
	my $pid = open my $fh, '-|';
	die "can't fork: $!\n" unless defined $pid;
	if (!$pid) {
		open STDERR, '>&', \*STDOUT or die "can't redirect: $!\n";
		exec 'samtools', @args or die "can't run samtools: $!\n";
	}
	my @lines = <$fh>;
	close $fh;
	(join('', @lines), $? >> 8);
}

print((samtools('--version'))[0] =~ /\A(.*\n.*\n)/);
samtools('faidx', $fa);
print "# the index of faidx.fa\n";
open my $in, '<', "$fa.fai" or die "can't read $fa.fai: $!\n";
print while <$in>;
close $in;

print "# regions: the sequence samtools faidx prints, on one line, and its exit status\n";
foreach my $region (
	'trailingblank2:28-33', 'trailingblank3:4-5', 'bar:4-5', 'foo', 'trailingblank1', 'trailingblank1:30-99', 'trailingblank1:3',
	'trailingblank1:3-', 'trailingblank1:-4', 'trailingblank2:1,0-1,2', 'trailingblank1:33-33', 'trailingblank1:34',
	'trailingblank1:40-50', 'bar:8-9', 'absent', 'trailingblank1:5-3', 'trailingblank1:0-3',
) {
	my ($out, $exit) = samtools('faidx', $fa, $region);
	my $seq = join '', grep { !/\A[>\[]/ } split /\n/, $out;
	print "$region\t\"$seq\"\texit $exit\n";
}

print "# files that cannot be indexed: what samtools faidx says of each\n";
my %bad = (
	'a line longer than the one before' => ">a\nACGT\nAC\nACGT\n",
	'a longer line after the first' => ">a\nAC\nACGT\n",
	'a defline with nothing after it' => ">a\nACGT\n>b\n",
	'text before any defline' => "ACGT\n>a\nACGT\n",
	'two sequences of one name' => ">a\nACGT\n>a\nGG\n",
	'an empty file' => '',
);
foreach my $what (sort keys %bad) {
	my $file = catfile($dir, 'bad.fa');
	unlink "$file.fai";
	open my $out, '>:raw', $file or die "can't write $file: $!\n";
	print {$out} $bad{$what};
	close $out or die "can't write $file: $!\n";
	my ($said, $exit) = samtools('faidx', $file);
	$said =~ s/\Q$dir\E.//g;
	$said =~ s/\n(?=.)/ | /g;
	my $index = '';
	if (open my $fai, '<', "$file.fai") {
		$index = join '', <$fai>;
		close $fai;
		$index =~ s/\n(?=.)/ | /g;
	}
	print "$what: exit $exit\n\t$said" . (length $index ? "\tindex: $index" : '');
}
