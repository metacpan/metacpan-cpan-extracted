#!/usr/bin/env perl
# Writes the fixtures of t/orf.t that EMBOSS's getorf makes, and prints the
# other values that t/seq.t and t/orf.t take from EMBOSS, for comparison with
# the literals there. The tests never run this. Run it from the
# distribution's root, with EMBOSS's programs on PATH (6.6.0 when the values
# were frozen, 2026-11-11: Ubuntu's emboss 6.6.0+dfsg-12ubuntu2):
#
#	perl t/data/emboss_reference.pl
#
# Its inputs are t/data/V00294.fa, the E. coli lacI gene that getorf's own
# documentation uses as tembl:v00294, fetched from
# https://www.ebi.ac.uk/ena/browser/api/fasta/V00294 on 2026-11-11, and
# t/data/NC_005816.fna, which is Tests/GenBank/NC_005816.fna of Biopython 1.87.
#
# It writes four files, each getorf's output as it stands:
#
#	t/data/V00294.orf_any.fa     getorf -find 0             (between stops)
#	t/data/V00294.orf_atg.fa     getorf -find 1             (ATG to stop)
#	t/data/NC_005816.orf_any.fa  getorf -find 0 -table 11 -minsize 300
#	t/data/NC_005816.orf_code.fa getorf -find 1 -table 11 -minsize 300
#
# getorf's -table 0, its default, is the standard code with ATG as its only
# start; its -table 11 starts where NCBI's code 11 does.
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);

# What $program prints when run with @args, as lines. EMBOSS writes to the
# file named stdout when asked to.
sub emboss {
	my ($program, @args) = @_;
	open my $fh, '-|', $program, @args, '-auto' or die "can't run $program: $!\n";
	my @lines = <$fh>;
	close $fh or die "$program failed: exit " . ($? >> 8) . "\n";
	chomp @lines;
	@lines;
}

# name => sequence of FASTA @lines, with the names in order
sub records {
	my (@order, %seq);
	foreach my $line (@_) {
		if ($line =~ /\A>(\S+)/) {
			push @order, $1;
			$seq{$1} = '';
		} else {
			$seq{ $order[-1] } .= $line;
		}
	}
	(\@order, \%seq);
}

sub spew {
	my ($file, @lines) = @_;
	open my $fh, '>', $file or die "can't write $file: $!\n";
	print {$fh} map { "$_\n" } @lines;
	close $fh or die "can't write $file: $!\n";
	print "wrote $file\n";
}

my ($lac, $plasmid) = ('t/data/V00294.fa', 't/data/NC_005816.fna');
print "$_\n" for grep { /PACKAGE_STRING/ } emboss('embossversion', '-full');

spew('t/data/V00294.orf_any.fa', emboss('getorf', '-sequence', $lac, '-find', 0, '-outseq', 'stdout'));
spew('t/data/V00294.orf_atg.fa', emboss('getorf', '-sequence', $lac, '-find', 1, '-outseq', 'stdout'));
spew('t/data/NC_005816.orf_any.fa', emboss('getorf', '-sequence', $plasmid, '-find', 0, '-table', 11, '-minsize', 300, '-outseq', 'stdout'));
spew('t/data/NC_005816.orf_code.fa', emboss('getorf', '-sequence', $plasmid, '-find', 1, '-table', 11, '-minsize', 300, '-outseq', 'stdout'));

print "# getorf -minsize 300 of V00294, the example in getorf's documentation\n";
print "$_\n" for grep { /\A>/ } emboss('getorf', '-sequence', $lac, '-minsize', 300, '-outseq', 'stdout');

print "# getorf -minsize 3 -noreverse of ATGAAATAG\n";
my $nine = 't/data/nine.tmp.fa';
spew($nine, '>nine', 'ATGAAATAG');
my @nine = emboss('getorf', '-sequence', $nine, '-minsize', 3, '-noreverse', '-outseq', 'stdout');
unlink $nine or die "can't remove $nine: $!\n";
print "$_\n" for @nine;

print "# fuzznuc -complement: pattern, start, end, strand\n";
foreach my $pattern (qw(GRATYC TTGACA GGNCC AAAAAA)) {
	foreach my $line (emboss('fuzznuc', '-sequence', $plasmid, '-pattern', $pattern, '-complement', '-outfile', 'stdout', '-rformat2', 'excel')) {
		my @f = split /\t/, $line;
		print "$pattern $f[1] $f[2] $f[4]\n" if $f[1] =~ /\A[0-9]+\z/;
	}
}

print "# wordcount -wordsize 3\n";
print join(' ', map { join '=', split /\t/ } sort(emboss('wordcount', '-sequence', $plasmid, '-wordsize', 3, '-outfile', 'stdout'))), "\n";

# transeq writes an X for the one or two bases after the last whole codon,
# which the module drops; the X is taken off before the digest is made
print "# transeq -frame 6 -alternative -table 11: frame, length, SHA-256\n";
my ($order, $frames) = records(emboss('transeq', '-sequence', $plasmid, '-frame', 6, '-alternative', '-table', 11, '-outseq', 'stdout'));
my $bases = 9609; # the plasmid's length
foreach my $i (0 .. 5) {
	my $p = $frames->{ $order->[$i] };
	$p =~ s/X\z// if ($bases - $i % 3) % 3;
	print +($i < 3 ? $i + 1 : -($i - 2)), ' ', length($p), ' ', sha256_hex($p), "\n";
}

print "# revseq: SHA-256 of the reverse complement\n";
(undef, my $rev) = records(emboss('revseq', '-sequence', $plasmid, '-outseq', 'stdout'));
print sha256_hex(join '', values %{ $rev }), "\n";

print "# extractseq -regions 101-130, and 9580-9609\n";
foreach my $region ('101-130', '9580-9609') {
	(undef, my $part) = records(emboss('extractseq', '-sequence', $plasmid, '-regions', $region, '-outseq', 'stdout'));
	print "$region ", join('', values %{ $part }), "\n";
}

print "# geecee\n";
print "$_\n" for grep { !/\A#/ } emboss('geecee', '-sequence', $plasmid, '-outfile', 'stdout');
