#!/usr/bin/env perl
# Writes hirisplex.vcf in this directory, for t/hirisplex.t; the tests only
# read what it wrote. Re-run from the distribution root as
#
#   perl t/data/make_hirisplex_vcf.pl
#
# and then t/data/hirisplex_reference.py, as t/hirisplex.t's header says, for
# the expected genotypes. It is built from share/hirisplex_s_panel.tsv, so a
# refreshed panel changes it; read the diff before committing.
#
# The file is on GRCh37, and its ##contig lines give GRCh37's lengths for the
# four chromosomes hirisplex_genotypes tells the build by. Its samples are
#
#   A  two copies of every counted allele
#   B  one copy of every counted allele
#   C  no copy of any counted allele
#   E  A's genotypes, with one edge case in five (see below)
#
# so that a reader that loses the strand, or counts REF where it should count
# ALT, cannot give A, B and C all the right answers. The counted allele is
# written as the ALT of a marker with an odd number and as the REF of one with
# an even number, for the same reason.
#
# Each marker's record, by its number n in the panel:
#
#   n == 25            no record at all, so that a marker the file never
#                      mentions is told from one nobody was called at
#   n == 26            its CHROM carries a "chr" prefix, which is dropped
#   n % 10 == 3        multi-allelic: the counted allele is the second ALT,
#                      so a reader that assumes one ALT counts nothing
#   n % 10 == 7        two records at the position, one ALT each, the second
#                      carrying the counted allele
#   n % 10 == 8        the same, with the first carrying it, so that neither
#                      order of a split site can be the only one that works
#   otherwise          one biallelic record
#
# and sample E's genotype, by the same n:
#
#   n % 5 == 0         "./." -- no call
#   n % 5 == 1         A's genotype at a DP of 3, below the default min_depth
#   n % 5 == 2         a haploid call, which is not a dosage on an autosome
#   n % 5 == 3         A's genotype, phased
#   n % 5 == 4         A's genotype
#
# After the markers come records that must all be passed over: an indel
# sharing marker 2's position, a SNV two bases from marker 4, and a SNV on a
# chromosome the panel does not use.
use 5.044;
use warnings FATAL => 'all';
use File::Spec;

my $here = __FILE__;
$here =~ s{[^/\\]+\z}{};
$here = '.' if $here eq '';

my $panel = do {
	open my $fh, '<', File::Spec->catfile($here, File::Spec->updir, File::Spec->updir, 'share', 'hirisplex_s_panel.tsv')
		or die "can't read the panel: $!\n";
	my $head = <$fh>;
	$head =~ s/\r?\n\z//;
	$head =~ s/\A#//;
	my @cols = split /\t/, $head;
	my @p;
	while (defined(my $line = <$fh>)) {
		$line =~ s/\r?\n\z//;
		next if $line eq '';
		my %m;
		@m{@cols} = split /\t/, $line, -1;
		push @p, \%m;
	}
	close $fh;
	\@p;
};

# An allele of the marker that is not the one counted, taken from the forward
# alleles Ensembl gave, so that REF and ALT are alleles the site really has.
sub other {
	my ($m, $skip) = @_;
	my %skip = map { $_ => 1 } $m->{count_allele}, @{ $skip || [] };
	my ($a) = grep { !$skip{$_} && /\A[ACGT]\z/ } split m{/}, $m->{b38_alleles};
	$a // (grep { !$skip{$_} } qw(A C G T))[0];
}

# E's genotype for a record whose counted allele is at $idx among REF and the
# ALTs, and whose A genotype is $a: the edge case marker $n calls for, and the
# DP to write with it.
sub edge {
	my ($n, $a, $idx) = @_;
	my $r = $n % 5;
	return ('./.', 30) if $r == 0;
	return ($a, 3) if $r == 1;
	return ($idx ? "$idx" : '0', 30) if $r == 2;
	return (join('|', split m{/}, $a), 30) if $r == 3;
	($a, 30);
}

my @record; # [chrom, pos, id, ref, alt, A, B, C, E, E's DP]
foreach my $m (@{ $panel }) {
	my $n = $m->{n};
	next if $n == 25;
	my $chrom = $n == 26 ? "chr$m->{b37_chrom}" : $m->{b37_chrom};
	my ($pos, $id, $count) = (@{ $m }{qw(b37_pos rsid count_allele)});
	if ($m->{kind} eq 'insertion') {
		# the MC1R 86insA: what is counted is the allele longer than REF
		my @gt = ('1/1', '0/1', '0/0');
		my ($e, $dp) = edge($n, '1/1', 1);
		push @record, [$chrom, $pos, $id, 'A', 'AA', @gt, $e, $dp];
		next;
	}
	my $other = other($m);
	if ($n % 10 == 3) {
		# multi-allelic: REF, a third allele, then the counted allele
		my $third = other($m, [$other]);
		my ($e, $dp) = edge($n, '2/2', 2);
		push @record, [$chrom, $pos, $id, $other, "$third,$count", '2/2', '0/2', '0/0', $e, $dp];
	} elsif ($n % 10 == 7 || $n % 10 == 8) {
		# two records at one position, only one of them carrying the counted
		# allele; which comes first depends on n
		my $third = other($m, [$other]);
		my ($e, $dp) = edge($n, '1/1', 1);
		my @carries = ($chrom, $pos, $id, $other, $count, '1/1', '0/1', '0/0', $e, $dp);
		my @not     = ($chrom, $pos, $id, $other, $third, '0/0', '0/0', '0/0', '0/0', 30);
		push @record, $n % 10 == 7 ? (\@not, \@carries) : (\@carries, \@not);
		next;
	} elsif ($n % 2) {
		my ($e, $dp) = edge($n, '1/1', 1);
		push @record, [$chrom, $pos, $id, $other, $count, '1/1', '0/1', '0/0', $e, $dp];
	} else {
		my ($e, $dp) = edge($n, '0/0', 0);
		push @record, [$chrom, $pos, $id, $count, $other, '0/0', '0/1', '1/1', $e, $dp];
	}
}

# Records that must all be passed over.
my ($two) = grep { $_->{n} == 2 } @{ $panel };
my ($four) = grep { $_->{n} == 4 } @{ $panel };
push @record,
	[$two->{b37_chrom}, $two->{b37_pos}, 'skip_indel', 'AT', 'A', '1/1', '1/1', '1/1', '1/1', 30],
	[$four->{b37_chrom}, $four->{b37_pos} + 2, 'skip_near', 'G', 'A', '1/1', '1/1', '1/1', '1/1', 30],
	[7, 1000000, 'skip_chrom', 'G', 'A', '1/1', '1/1', '1/1', '1/1', 30];

# GRCh37's lengths, from Ensembl's /info/assembly/homo_sapiens on
# grch37.rest.ensembl.org, read 2026-10-20: every chromosome the panel uses,
# the four hirisplex_genotypes tells the build by, and chromosome 7, which the
# last record is on so that a record off the panel is passed over.
my %length = (1 => 249250621, 5 => 180915260, 6 => 171115067, 7 => 159138663, 9 => 141213431,
	11 => 135006516, 12 => 133851895, 14 => 107349540, 15 => 102531392, 16 => 90354753, 20 => 63025520);

my $out = File::Spec->catfile($here, 'hirisplex.vcf');
open my $fh, '>', $out or die "can't write $out: $!\n";
print {$fh} "##fileformat=VCFv4.2\n";
print {$fh} "##contig=<ID=$_,length=$length{$_}>\n" foreach sort { $a <=> $b } keys %length;
print {$fh} "##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n",
	"##FORMAT=<ID=DP,Number=1,Type=Integer,Description=\"Read depth\">\n",
	join("\t", '#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT A B C E)), "\n";
# sorted as a VCF is, by chromosome and then position, with the two records of
# a split site kept in the order they were made
my $i = 0;
foreach my $r (sort { ($a->[0] =~ /([0-9]+)/)[0] <=> ($b->[0] =~ /([0-9]+)/)[0] || $a->[1] <=> $b->[1] || $a->[10] <=> $b->[10] }
	map { [@{ $record[$_] }, $_] } 0 .. $#record) {
	print {$fh} join("\t", @{ $r }[0 .. 4], '.', '.', '.', 'GT:DP',
		(map { "$_:30" } @{ $r }[5 .. 7]), "$r->[8]:$r->[9]"), "\n";
}
close $fh or die "can't write $out: $!\n";
print "wrote $out: ", scalar @record, " records\n";
