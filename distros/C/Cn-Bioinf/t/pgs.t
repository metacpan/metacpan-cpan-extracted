require 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin;
use Storable qw(dclone);
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);
use IO::Compress::Gzip qw(gzip $GzipError);
use File::Copy qw(copy);
use Cn::Bioinf qw(pgs_score);
plan skip_all => 'pgs_score runs PLINK 2, which Alien::Bioinf installs, and it is not installed here'
	unless eval { require Alien::Bioinf; -x Alien::Bioinf->plink2 };
# t/data/pgs.vcf and t/data/pgs_weights.txt were written by hand on
# 2026-10-17, the weights in the layout of the PGS Catalog's PGS000138.txt.gz
# (format 2.0). Between them they hold an effect allele that is the ALT, one
# that is the REF, one that is the second of two ALTs, a multi-allelic site
# split into two records, a variant whose alleles disagree with the VCF's
# (rs4, A/G against T/C), one the VCF does not have (rs6), one whose VCF ID is
# "." (rs5), a no-call, a phased genotype, a sample that leaves DP off, and
# chromosomes named "chr1" in the VCF and "1" in the weights.
#
# The expected scores for matching by position are PLINK v2.0.0-a.6.9LM's
# (29 Jan 2025), run on 2026-10-17 as
#
#   plink2 --vcf t/data/pgs.vcf --set-all-var-ids 'chr@:#:$r:$a' --make-pgen --out p
#   plink2 --pfile p --score w.txt 1 2 3 header no-mean-imputation cols=+scoresums --out s
#
# where w.txt is pgs_weights.txt with each variant named by the ID that gave
# its record (the multi-allelic one is chr1:300:G:A, as $a is the first ALT
# alone). It printed
#
#   #IID ALLELE_CT NAMED_ALLELE_DOSAGE_SUM SCORE1_AVG SCORE1_SUM
#   S1   10        3                       0.185      1.85
#   S2   10        4                       0.335      3.35
#   S3    8        6                       0.3375     2.7
#
# and skipped one variant as absent and one for "a mismatching allele code".
# ALLELE_CT is "alleles" here, and SCORE1_AVG is "average". PLINK 2 matches
# on IDs, not positions, so the IDs above stand in for the position matching
# that pgs_score does; and it doesn't check the other allele, which agrees
# with the VCF's wherever the effect allele does in this fixture. The scores
# for matching by ID, and the cases built in this file, were counted by hand.
#
# Since 2026-10-17 pgs_score has PLINK 2 (Alien::Bioinf's v2.0.0-a.7.13LM, of
# 15 Oct 2026) do the scoring, and the values above check that it hands PLINK
# 2 the right records and alleles. Where PLINK 2's counting differs from a
# count by hand -- a haploid call on X -- the case says so.

# The fixtures, as Stats::LikeR's read_table returns them: the VCF as a hash of
# hashes keyed by CHROM:POS:REF:ALT, with each sample's column split into
# <sample>.<FORMAT key> (undef where a sample leaves a key off), and the weights
# as an array of hashes. This stands in for read_table, so that the test needs
# only the module; the block at the end checks it against read_table itself.
sub lines {
	my ($file) = @_;
	open my $fh, '<', $file or die "$file: $!";
	my @lines = map { chomp; $_ } <$fh>;
	close $fh;
	@lines;
}
sub read_vcf {
	my ($file) = @_;
	my ($head, @records) = grep { !/^##/ } lines($file);
	my @cols = split /\t/, substr $head, 1;
	my @samples = @cols[9 .. $#cols];
	my (%vcf, @keys);
	foreach my $line (@records) {
		my %f;
		@f{@cols} = split /\t/, $line;
		my @format = split /:/, $f{FORMAT};
		foreach my $k (@format) {
			push @keys, $k unless grep { $_ eq $k } @keys;
		}
		my %row = map { $_ => $f{$_} } @cols[0 .. 7];
		foreach my $s (@samples) {
			my @v = split /:/, $f{$s};
			@row{ map { "$s.$_" } @format } = @v[0 .. $#format];
		}
		$vcf{ join ':', @f{qw(CHROM POS REF ALT)} } = \%row;
	}
	foreach my $row (values %vcf) {
		foreach my $s (@samples) {
			$row->{"$s.$_"} //= undef foreach @keys;
		}
	}
	\%vcf;
}
sub read_weights {
	my ($file) = @_;
	my ($head, @rows) = grep { !/^#/ } lines($file);
	my @cols = split /\t/, $head;
	[ map { my %r; @r{@cols} = split /\t/; \%r } @rows ];
}
my $vcf = read_vcf("$FindBin::Bin/data/pgs.vcf");
my $weights = read_weights("$FindBin::Bin/data/pgs_weights.txt");
my @fields = qw(alleles average mismatched missing score variants);

# The scores are sums of at most seven products of numbers with one or two
# decimal places, so they differ from the exact decimal by a few units in the
# last place (about 1e-15); PLINK 2 printed them to 6 significant figures, which
# they are exact to. 1e-12 is far above the first and far below the second.
sub score_is {
	my ($got, $want, $name) = @_;
	is_deeply [sort keys %{ $got }], [sort keys %{ $want }], "$name: the samples";
	foreach my $s (sort keys %{ $want }) {
		is_deeply [sort keys %{ $got->{$s} }], \@fields, "$name: $s has every field";
		foreach my $f (@fields) {
			my ($g, $w) = ($got->{$s}{$f}, $want->{$s}{$f});
			if (!defined $w) {
				ok !defined $g, "$name: $s $f is undef";
			} elsif ($f eq 'score' || $f eq 'average') {
				ok defined $g && abs($g - $w) < 1e-12, "$name: $s $f is $w" or diag 'got ' . ($g // 'undef');
			} else {
				is $g, $w, "$name: $s $f";
			}
		}
	}
}
my $plink = {
	S1 => { alleles => 10, average => 0.185,  mismatched => 1, missing => 2, score => 1.85, variants => 5 },
	S2 => { alleles => 10, average => 0.335,  mismatched => 1, missing => 2, score => 3.35, variants => 5 },
	S3 => { alleles => 8,  average => 0.3375, mismatched => 1, missing => 3, score => 2.7,  variants => 4 },
};

# ---- matching by position, in every shape --------------------------------------

my ($vcf_copy, $weights_copy) = (dclone($vcf), dclone($weights));
score_is pgs_score(vcf => $vcf, weights => $weights), $plink, 'hoh and aoh';
is_deeply [$vcf, $weights], [$vcf_copy, $weights_copy], 'the frames given are not changed';
score_is pgs_score(vcf => $vcf, weights => $weights, match => 'position'), $plink, 'match => "position" is the default';
# Weights that list every variant twice put two rows on every record, which
# pgs_score hands PLINK 2's --score in two passes, since it takes one line for
# each record: every count and score is twice PLINK 2's above, and every
# average the same. (Since 2026-11-18 the passes are told apart by a bit for
# each record, where a hash of every record's count did it before; the two
# gave the same here.)
my $twice = { map { my $s = $_; $s => { map { $_ => ($_ eq 'average' ? 1 : 2) * $plink->{$s}{$_} } @fields } } keys %{ $plink } };
score_is pgs_score(vcf => $vcf, weights => [@{ $weights }, @{ $weights }]), $twice, 'every row of weights twice, scored in two passes';

my @vcf_rows = map { $vcf->{$_} } sort keys %{ $vcf };
my @vcf_cols = sort keys %{ $vcf_rows[0] };
my @weight_cols = sort keys %{ $weights->[0] };
# a hash of arrays, and an array of arrays whose first row is the header
sub hoa { my ($rows, $cols) = @_; +{ map { my $c = $_; $c => [map { $_->{$c} } @{ $rows }] } @{ $cols } } }
sub aoa { my ($rows, $cols) = @_; [$cols, map { [@{ $_ }{@{ $cols }}] } @{ $rows }] }
score_is pgs_score(vcf => \@vcf_rows, weights => $weights), $plink, 'aoh VCF';
score_is pgs_score(vcf => hoa(\@vcf_rows, \@vcf_cols), weights => hoa($weights, \@weight_cols)), $plink, 'hoa';
score_is pgs_score(vcf => aoa(\@vcf_rows, \@vcf_cols), weights => aoa($weights, \@weight_cols)), $plink, 'aoa';
score_is pgs_score(vcf => $vcf, weights => { map { $_->{rsID} => $_ } @{ $weights } }), $plink, 'hoh weights';

# ---- files -----------------------------------------------------------------------

{
	my $dir = tempdir(CLEANUP => 1);
	my ($vcf_file, $weights_file) = map { "$FindBin::Bin/data/$_" } 'pgs.vcf', 'pgs_weights.txt';
	score_is pgs_score(vcf => $vcf_file, weights => $weights_file), $plink, 'a VCF file and a scoring file';
	my $gz = catfile($dir, 'pgs_weights.txt.gz');
	gzip($weights_file => $gz) or die "gzip: $GzipError";
	score_is pgs_score(vcf => $vcf, weights => $gz), $plink, 'a gzipped scoring file';
	# a PLINK 2 fileset, made by PLINK 2 itself, its output kept off the TAP
	my $prefix = catfile($dir, 'pgs');
	open my $saved, '>&', \*STDOUT or die $!;
	open STDOUT, '>', catfile($dir, 'plink2.out') or die $!;
	my $rc = system(Alien::Bioinf->plink2, '--vcf', $vcf_file, '--make-pgen', '--out', $prefix);
	open STDOUT, '>&', $saved or die $!;
	is $rc, 0, 'PLINK 2 made a .pgen of the fixture';
	score_is pgs_score(vcf => "$prefix.pgen", weights => $weights_file), $plink, 'a PLINK 2 .pgen';
	# The same fileset with each sample given a family (FID), as a .psam may.
	# Up to 2026-11-16 the scores were keyed by IID alone, so that two samples
	# with one IID in different families were added together: S1's and S2's
	# scores were summed under "S", with -3 variants missing.
	my $fam = catfile($dir, 'fam');
	foreach my $ext (qw(pgen pvar)) {
		copy("$prefix.$ext", "$fam.$ext") or die "copy $prefix.$ext: $!";
	}
	my $psam = sub {
		open my $fh, '>', "$fam.psam" or die "$fam.psam: $!";
		print {$fh} "#FID\tIID\tSEX\n", map { "$_->[0]\t$_->[1]\tNA\n" } @_;
		close $fh or die "$fam.psam: $!";
	};
	$psam->([A => 'S1'], [B => 'S2'], [C => 'S3']);
	score_is pgs_score(vcf => "$fam.pgen", weights => $weights_file), $plink, 'a .psam with families is scored by IID';
	$psam->([A => 'S'], [B => 'S'], [C => 'T']);
	my $merged = eval { pgs_score(vcf => "$fam.pgen", weights => $weights_file) };
	like $@, qr/^pgs_score: "vcf" has two samples whose IID is "S", in families "A" and "B"; the scores are returned by IID, so each sample's must be unique/,
		'two samples with one IID in different families die, rather than having their scores added together';
	score_is pgs_score(vcf => $vcf_file, weights => $weights_file, memory => 640, threads => 1), $plink, 'memory and threads';
}

# ---- matching by ID -----------------------------------------------------------

# rs1, rs2 and rs3 are scored as by position; rs4's alleles disagree; rs5's
# record has the ID "."; rs6 is absent; and rs8's records have no ID.
score_is pgs_score(vcf => $vcf, weights => $weights, match => 'id'), {
	S1 => { alleles => 6, average => -0.025, mismatched => 1, missing => 4, score => -0.15, variants => 3 },
	S2 => { alleles => 6, average => 0.1,    mismatched => 1, missing => 4, score => 0.6,   variants => 3 },
	S3 => { alleles => 4, average => 0.3,    mismatched => 1, missing => 5, score => 1.2,   variants => 2 },
}, 'match => "id"';
{
	# an ID column holding two rsIDs, as a merged dbSNP record can
	my $two = { 'x' => { CHROM => '1', POS => 5, ID => 'rs90;rs91', REF => 'A', ALT => 'G', 'S.GT' => '0/1' } };
	my $got = pgs_score(vcf => $two, weights => [{ rsID => 'rs91', effect_allele => 'G', other_allele => 'A', effect_weight => 2 }], match => 'id');
	is $got->{S}{score}, 2, 'a variant is found by the second of two IDs in a record';
}

# ---- the other columns of a scoring file ------------------------------------------

{
	# A harmonized file's hm_chr and hm_pos are read in place of chr_name and
	# chr_position, which here are wrong; an empty hm_pos is a variant the
	# harmonization couldn't place, and is missing rather than an error.
	my $hm = dclone($weights);
	foreach my $w (@{ $hm }) {
		@{ $w }{qw(hm_chr hm_pos)} = ("chr$w->{chr_name}", $w->{chr_position});
		$w->{chr_position} += 1000;
	}
	my $want = dclone($plink);
	score_is pgs_score(vcf => $vcf, weights => $hm), $want, 'hm_chr and hm_pos are read when present';
	@{ $hm->[5] }{qw(hm_chr hm_pos)} = ('', ''); # rs6, which the VCF doesn't have anyway
	score_is pgs_score(vcf => $vcf, weights => $hm), $want, 'an empty hm_pos is a missing variant';
	# without other_allele, rs4's A is still not among the record's T and C
	my $no_other = [map { my %w = %{ $_ }; delete $w{other_allele}; \%w } @{ $weights }];
	score_is pgs_score(vcf => $vcf, weights => $no_other), $plink, 'without other_allele, only the effect allele has to agree';
	# false flags and empty dosage weights are additive, and are scored
	my $flagged = [map { +{ %{ $_ }, is_dominant => 'False', is_recessive => 0, dosage_2_weight => '' } } @{ $weights }];
	score_is pgs_score(vcf => $vcf, weights => $flagged), $plink, 'is_dominant FALSE and an empty dosage_2_weight are scored';
}

# ---- genotypes and records ----------------------------------------------------

{
	my $w = [
		{ chr_name => 'X',  chr_position => 10, effect_allele => 'T', other_allele => 'A', effect_weight => 1 },
		{ chr_name => '23', chr_position => 20, effect_allele => 'c', other_allele => 'g', effect_weight => 10 },
		{ chr_name => 'MT', chr_position => 30, effect_allele => 'A', other_allele => 'G', effect_weight => 100 },
		{ chr_name => '1',  chr_position => 40, effect_allele => 'C', other_allele => 'T', effect_weight => 1000 },
		{ chr_name => '1',  chr_position => 50, effect_allele => 'T', other_allele => 'C', effect_weight => 10000 },
	];
	my $v = {
		# haploid in M, diploid in F
		a => { CHROM => 'chrX', POS => 10, ID => '.', REF => 'A', ALT => 'T', 'M.GT' => '1',   'F.GT' => '1/1' },
		# lower case, and named by PLINK's 23; M's call is partly missing
		b => { CHROM => 'X',    POS => 20, ID => '.', REF => 'G', ALT => 'C', 'M.GT' => './1', 'F.GT' => '0|1' },
		# UCSC's chrM; F's FORMAT had no GT
		c => { CHROM => 'chrM', POS => 30, ID => '.', REF => 'G', ALT => 'A', 'M.GT' => '1',   'F.GT' => undef },
		# a site with no ALT, which a VCF of every site writes: two copies of
		# the effect allele where it is the REF, none where it is the other
		d => { CHROM => 'chr1', POS => 40, ID => '.', REF => 'C', ALT => '.', 'M.GT' => '0/0', 'F.GT' => '0/0' },
		e => { CHROM => 'chr1', POS => 50, ID => '.', REF => 'C', ALT => '.', 'M.GT' => '0/0', 'F.GT' => '.' },
	};
	# PLINK 2 reads X only once told the build (here hg19, whose
	# pseudo-autosomal region 1 starts at 60,001, after both of these), and
	# then counts a haploid call on X of a sample of unknown sex, as every
	# sample is here, as homozygous: 2 copies and 2 alleles. On MT it is 1 of each.
	# M: 2 copies of T at X:10, a missing call at X:20, 1 copy of A at MT:30, 2
	# of C at 1:40 and none of T at 1:50, from 2 + 1 + 2 + 2 alleles.
	# F: 2 copies of T, 1 of C at X:20, no GT at MT:30, 2 of C at 1:40, and a
	# missing call at 1:50, from 2 + 2 + 2 alleles.
	score_is pgs_score(vcf => $v, weights => $w, build => 'hg19'), {
		M => { alleles => 7, average => 2102 / 7, mismatched => 0, missing => 1, score => 2102, variants => 4 },
		F => { alleles => 6, average => 2012 / 6, mismatched => 0, missing => 2, score => 2012, variants => 3 },
	}, 'haploid calls, part calls, no GT, records with no ALT, and chromosome names';
	{
		local $@;
		ok !eval { pgs_score(vcf => $v, weights => $w); 1 }, 'without "build", variants on X die';
		like $@, qr/^pgs_score: "weights" has variants on X, which PLINK 2 reads only when "build" says where/, 'and say why';
	}
	my $none = { a => { CHROM => '1', POS => 40, ID => '.', REF => 'C', ALT => 'T', 'N.GT' => './.' } };
	score_is pgs_score(vcf => $none, weights => [$w->[3]]), {
		N => { alleles => 0, average => undef, mismatched => 0, missing => 1, score => 0, variants => 0 },
	}, 'average is undef for a sample with no called alleles';
}

{
	# An effect allele with no other allele, which both records at chr1:800
	# (A/C and A/G) agree with: chr1:800:A:C is used, whose 0/1 is S1's one A
	# (A/G's 0/0 would be two), whichever order the rows come in.
	my $w = [{ chr_name => '1', chr_position => 800, effect_allele => 'A', effect_weight => 1 }];
	my $want = {
		S1 => { alleles => 2, average => 0.5, mismatched => 0, missing => 0, score => 1, variants => 1 },
		S2 => { alleles => 2, average => 1,   mismatched => 0, missing => 0, score => 2, variants => 1 },
		S3 => { alleles => 2, average => 1,   mismatched => 0, missing => 0, score => 2, variants => 1 },
	};
	score_is pgs_score(vcf => \@vcf_rows, weights => $w), $want, 'of two records that agree, the first by CHROM:POS:REF:ALT is used';
	score_is pgs_score(vcf => [reverse @vcf_rows], weights => $w), $want, 'and the order of the rows does not decide it';
}
{
	# Records with a field undef, which must match nothing and raise no
	# "uninitialized" warning (which this file's FATAL warnings would make a
	# death), and a record with no ALT whose REF is neither of the variant's
	# alleles, which disagrees. No variant agrees in any of these calls, so
	# each carps, as the warnings section below checks; that carp is muted here.
	local $SIG{__WARN__} = sub {};
	my $w = [{ rsID => 'rs1', chr_name => '1', chr_position => 10, effect_allele => 'A', other_allele => 'G', effect_weight => 1 }];
	my $v = [
		{ CHROM => undef,  POS => 10,    ID => undef, REF => 'A',   ALT => 'G',   'S.GT' => '0/1' },
		{ CHROM => 'chr1', POS => undef, ID => undef, REF => 'A',   ALT => 'G',   'S.GT' => '0/1' },
		{ CHROM => 'chr1', POS => 10,    ID => undef, REF => undef, ALT => 'G',   'S.GT' => '0/1' },
		{ CHROM => 'chr1', POS => 10,    ID => undef, REF => 'A',   ALT => undef, 'S.GT' => '0/1' },
		{ CHROM => 'chr1', POS => 10,    ID => undef, REF => 'T',   ALT => '.',   'S.GT' => '0/0' },
	];
	score_is pgs_score(vcf => $v, weights => $w), {
		S => { alleles => 0, average => undef, mismatched => 1, missing => 1, score => 0, variants => 0 },
	}, 'undef fields match nothing, and a record with no ALT and another REF disagrees';
	score_is pgs_score(vcf => $v, weights => $w, match => 'id'), {
		S => { alleles => 0, average => undef, mismatched => 0, missing => 1, score => 0, variants => 0 },
	}, 'and an undef ID is no ID';
	$v->[3]{ALT} = 'G';
	$v->[3]{'S.GT'} = '';
	score_is pgs_score(vcf => $v, weights => $w), {
		S => { alleles => 0, average => undef, mismatched => 0, missing => 1, score => 0, variants => 0 },
	}, 'an empty GT is a missing call';
}
{
	# A score whose only chromosome the VCF lacks. PLINK 2 then drops every
	# record by --chr and exits 7 ("All 2 variant(s) in --vcf file excluded by
	# --chr"), not 13, and pgs_score died of it rather than scoring every
	# variant missing, as it does when only the positions are absent.
	my @warned;
	local $SIG{__WARN__} = sub { push @warned, $_[0] };
	my $v = [
		{ CHROM => '1', POS => 100, ID => 'rs1', REF => 'A', ALT => 'G', 'S1.GT' => '0/1', 'S2.GT' => '0/0' },
		{ CHROM => '1', POS => 200, ID => 'rs2', REF => 'C', ALT => 'T', 'S1.GT' => '0/0', 'S2.GT' => '1/1' },
	];
	my $w = [{ chr_name => '2', chr_position => 100, effect_allele => 'G', effect_weight => 2 }];
	my $empty = { alleles => 0, average => undef, mismatched => 0, missing => 1, score => 0, variants => 0 };
	score_is pgs_score(vcf => $v, weights => $w), { S1 => $empty, S2 => $empty },
		'a score on a chromosome the VCF lacks is every variant missing, and does not die of exit 7 from PLINK 2';
	like $warned[0], qr/^pgs_score: none of the 1 variants of "weights" was found in "vcf"/, 'and it warns as any score that matches nothing';
}

# ---- warnings -------------------------------------------------------------------

{
	my @warned;
	local $SIG{__WARN__} = sub { push @warned, $_[0] };
	my $got = pgs_score(vcf => $vcf, weights => $weights);
	is $got->{S1}{variants}, 5, 'a probe that matches';
	is_deeply \@warned, [], 'and a good match does not warn';
	# every position moved on one base, as the wrong build would leave them
	my $shifted = [map { +{ %{ $_ }, chr_position => $_->{chr_position} + 1 } } @{ $weights }];
	$got = pgs_score(vcf => $vcf, weights => $shifted);
	is $got->{S1}{variants}, 0, 'weights on positions the VCF lacks score nothing';
	like shift(@warned), qr/^pgs_score: none of the 7 variants of "weights" was found in "vcf" with its alleles; check that the two are on the same genome build/,
		'and say so';
	# rs1, rs2, rs3 and rs8 on the other strand, so that they disagree with the
	# VCF as rs4 already does, and only rs5 (C/G, which reads the same on either
	# strand) agrees
	my $flipped = dclone($weights);
	foreach my $w (@{ $flipped }[0, 1, 2, 6]) {
		tr/ACGT/TGCA/ foreach @{ $w }{qw(effect_allele other_allele)};
	}
	$got = pgs_score(vcf => $vcf, weights => $flipped);
	is $got->{S1}{mismatched}, 5, 'variants on the other strand disagree';
	like shift(@warned), qr/^pgs_score: the alleles disagree at 5 of the 6 variants of "weights" found in "vcf"; check that the two are on the same genome build/,
		'and more disagreeing than agreeing is warned about';
	is_deeply \@warned, [], 'and nothing else was warned';
}

# Found by review on 2026-11-10, and failing against the code of that day: a
# failure of PLINK 2 was raised again with croak, which gave the message a
# second "at ... line", after the "End time:" that PLINK 2 ends every run with.
# The period after the line number is optional, since Carp before 1.25 (perl
# 5.12.5's) writes none.
{
	my $dir = tempdir(CLEANUP => 1);
	my $bad = catfile($dir, 'bad.vcf');
	open my $fh, '>', $bad or die "$bad: $!";
	print {$fh} "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS1\n1\tabc\t.\tA\tG\t.\t.\t.\tGT\t0/1\n";
	close $fh or die "$bad: $!";
	eval { pgs_score(vcf => $bad, weights => $weights) };
	like $@, qr/\Apgs_score: .+ failed \(exit [0-9]+\): Error: Invalid POS on line 3 of --vcf file\. at \Q${\ __FILE__}\E line [0-9]+\.?\n\z/,
		"a failure of PLINK 2 ends with its error and the caller's line, once";
}

# ---- against Stats::LikeR's read_table ------------------------------------------

SKIP: {
	skip 'Stats::LikeR is not installed', 3 unless eval { require Stats::LikeR; 1 };
	my $rt_vcf = Stats::LikeR::read_table("$FindBin::Bin/data/pgs.vcf");
	is_deeply $rt_vcf, $vcf, 'read_table reads the VCF as read_vcf does';
	my $rt_weights = Stats::LikeR::read_table("$FindBin::Bin/data/pgs_weights.txt", sep => "\t");
	is_deeply $rt_weights, $weights, 'and the weights';
	score_is pgs_score(vcf => $rt_vcf, weights => $rt_weights), $plink, 'read_table\'s frames';
}

done_testing;
