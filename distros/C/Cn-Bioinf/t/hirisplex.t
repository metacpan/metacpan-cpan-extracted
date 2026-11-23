require 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use File::Spec;
use File::Spec::Functions qw(catfile);
use Cn::Bioinf qw(hirisplex_genotypes trait_predict);

# t/data/hirisplex.vcf was written by t/data/make_hirisplex_vcf.pl on
# 2026-10-20; its header says what each record and each sample's genotypes
# cover. Samples A, B and C carry two, one and no copies of every counted
# allele, and E is A with one edge case in five.
#
# The expected genotypes are what t/data/hirisplex_reference.py, a second
# implementation of the same rules reading the same file through cyvcf2
# 0.34.0 under Python 3.14.2, printed on 2026-10-20:
#
#   venv/bin/python -I t/data/hirisplex_reference.py t/data/hirisplex.vcf 7
#
# The expected probabilities are what t/data/trait_reference.py, which applies
# the definition of a multinomial logistic regression to the same genotypes
# and t/data/trait_model.tsv, printed on the same day. That model is made up
# and says so: HIrisPlex-S's own coefficients are not published, and this
# distribution ships no model.
#
# The genotypes of the insertion and lower-case records near the end were
# worked out by hand from the rules on 2026-11-02, and are what
# t/data/hirisplex_reference.py printed for each of them that day.
#
# The CSV that hirisplex_genotypes writes is compared against
# t/data/hirisplexs_template.csv, the webtool's own upload template,
# downloaded from https://hirisplex.erasmusmc.nl/examples/hirisplexs.csv on
# 2026-10-20. That file is the authority for the column names and their order,
# so a panel that drifts from it stops being uploadable.

my $data = catfile($FindBin::Bin, 'data');
my $vcf = catfile($data, 'hirisplex.vcf');
my $model = catfile($data, 'trait_model.tsv');
my $dir = tempdir(CLEANUP => 1);

# The 41 markers in the panel's order, as the webtool's template heads its
# columns; read from the template itself so that the test and the module
# cannot drift apart silently.
my @column = do {
	open my $fh, '<', catfile($data, 'hirisplexs_template.csv') or die "can't read the template: $!";
	my $head = <$fh>;
	close $fh;
	$head =~ s/\r?\n\z//;
	my (undef, @c) = split /,/, $head;
	@c;
};
is scalar @column, 41, 'the webtool template heads 41 marker columns';

# ---- genotypes

my $g = hirisplex_genotypes(vcf => $vcf, report => 0);
is_deeply [sort keys %{ $g }], [qw(A B C E)], 'every sample of the VCF is returned';

is $g->{A}{markers}, 41, 'the panel is 41 markers';
is $g->{A}{called}, 40, 'A was called at 40 of them';
is_deeply $g->{A}{missing}, ['rs3114908'], 'rs3114908, which the file has no record of, is the one missing';

# A, B and C carry two, one and no copies of every counted allele; rs3114908
# is in no record, so nobody has a genotype for it.
foreach my $s (qw(A B C)) {
	my $want = $s eq 'A' ? 2 : $s eq 'B' ? 1 : 0;
	my @wrong = grep { ($g->{$s}{genotype}{$_} // -1) != $want }
		grep { $_ ne 'rs3114908_T' } @column;
	is scalar @wrong, 0, "$s has $want copies of the counted allele at all 40 markers"
		or diag 'wrong at: ' . join ', ', map { "$_=" . (defined $g->{$s}{genotype}{$_} ? $g->{$s}{genotype}{$_} : 'undef') } @wrong;
	is $g->{$s}{genotype}{'rs3114908_T'}, undef, "$s has no genotype at rs3114908";
}

# E, marker by marker, from hirisplex_reference.py. Its edge cases are, by the
# marker's number n in the panel: n % 5 == 0 a "./." call, 1 a DP of 3 (below
# the default min_depth of 7), 2 a haploid call, 3 a phased call, 4 a plain
# one, so that only the last two are genotypes.
my @e = qw(NA NA 2 2 NA NA NA 2 2 NA NA NA 2 2 NA NA NA 2 2 NA
           NA NA 2 2 NA NA NA 2 2 NA NA NA 2 2 NA NA NA 2 2 NA NA);
is scalar @e, 41, 'the expected genotypes of E cover the whole panel';
my @e_wrong = grep {
	my $want = $e[$_] eq 'NA' ? undef : $e[$_];
	my $got = $g->{E}{genotype}{ $column[$_] };
	defined $want != defined $got || (defined $want && $want != $got)
} 0 .. $#column;
is scalar @e_wrong, 0, 'E has a genotype only where its call is diploid and deep enough'
	or diag 'wrong at: ' . join ', ', map { $column[$_] } @e_wrong;
is $g->{E}{called}, 16, 'E was called at 16 markers';

# The manual refuses an eye prediction without HERC2 rs12913832, which is
# marker 20 and so one of E's "./." calls, and a hair prediction without all
# 11 MC1R markers, of which E keeps several.
is $g->{$_}{eye}, 1, "$_ allows an eye prediction" foreach qw(A B C);
is $g->{E}{eye}, 0, 'E allows no eye prediction: HERC2 rs12913832 is a no-call';
is $g->{E}{hair}, 1, 'E still allows a hair prediction: not all 11 MC1R markers are missing';
is $g->{$_}{skin}, 1, "$_ allows a skin prediction" foreach qw(A B C E);

# min_depth 0 counts the genotypes E has at a DP of 3, which are the markers
# whose number is 1 modulo 5: markers 1, 6, 11, 16, 21, 26, 31, 36 and 41, so
# nine more than the 16 counted above. hirisplex_reference.py prints the same
# 25 when it is run with a min_depth of 0.
my $deep = hirisplex_genotypes(vcf => $vcf, min_depth => 0, report => 0);
is $deep->{E}{called}, 25, 'min_depth 0 counts E\'s genotypes of DP 3 as well';
is $deep->{A}{called}, 40, 'min_depth 0 leaves A, whose genotypes are all of DP 30, alone';

# ---- the same markers found by rs number

my $by_id = hirisplex_genotypes(vcf => $vcf, match => 'id', report => 0);
foreach my $s (qw(A B C E)) {
	is_deeply $by_id->{$s}{genotype}, $g->{$s}{genotype}, "matching by rs number finds the same genotypes for $s";
}

# An ID may be several names, which the VCF specification separates with
# semicolons (VCFv4.2, section 1.4.1, field 3). Up to 2026-11-10 only the first
# was looked at, so a record whose rs number came second matched nothing; this
# failed against the code of that day. The genotypes expected are those of the
# file as it is, which is the same records.
{
	open my $in, '<', $vcf or die "$vcf: $!";
	my $text = do { local $/; <$in> };
	close $in;
	my $changed = $text =~ s/^([^#\t][^\t]*\t[0-9]+\t)(rs[0-9]+)\t/$1foo;$2;bar\t/mg;
	cmp_ok $changed, '>=', 41, 'a record of every marker has its rs number put between two other names';
	my $listed = catfile($dir, 'listed.vcf');
	open my $out, '>', $listed or die "$listed: $!";
	print {$out} $text;
	close $out or die "$listed: $!";
	my $got = hirisplex_genotypes(vcf => $listed, match => 'id', report => 0);
	is_deeply $got->{$_}{genotype}, $by_id->{$_}{genotype}, "an rs number that is not the first name of its ID is still found, for $_" foreach qw(A B C E);
}

# ---- the webtool's CSV

my $csv = catfile($dir, 'out.csv');
hirisplex_genotypes(vcf => $vcf, file => $csv, report => 0);
open my $fh, '<', $csv or die "can't read $csv: $!";
my @wrote = <$fh>;
close $fh;
chomp @wrote;
open my $tfh, '<', catfile($data, 'hirisplexs_template.csv') or die "can't read the template: $!";
my $template = <$tfh>;
close $tfh;
$template =~ s/\r?\n\z//;
is $wrote[0], $template, 'the CSV header is the webtool\'s own template, column for column';
is scalar @wrote, 5, 'the CSV holds a header and the four samples';
is $wrote[1], 'A,' . join(',', map { $_ eq 'rs3114908_T' ? 'NA' : 2 } @column), 'A\'s row counts 2 everywhere but the missing marker';
like $wrote[4], qr/\AE,NA,NA,2,2,NA,/, 'E\'s row writes NA where it has no genotype';

# ---- trait_predict

# From t/data/trait_reference.py. The two differ only in that _softmax takes
# the largest linear predictor out before exp(), so they should agree to the
# 12 decimal places the reference prints; 1e-12 is that precision, not a
# tolerance chosen to make anything pass.
my $tol = 1e-12;
my %expect = (
	A => { eye => { blue => 0.024093768287, intermediate => 0.178030205506, brown => 0.797876026207 },
	       hair_shade => { light => 0.904650535101, dark => 0.095349464899 } },
	B => { eye => { blue => 0.186323723226, intermediate => 0.307195885718, brown => 0.506480391056 },
	       hair_shade => { light => 0.731058578630, dark => 0.268941421370 } },
	C => { eye => { blue => 0.628531719212, intermediate => 0.231223897622, brown => 0.140244383166 },
	       hair_shade => { light => 0.437823499114, dark => 0.562176500886 } },
	E => { eye => { blue => 0.383651731191, intermediate => 0.383651731191, brown => 0.232696537619 },
	       hair_shade => { light => 0.437823499114, dark => 0.562176500886 } },
);

my $p = trait_predict(genotypes => $g, model => $model, report => 0);
is_deeply [sort keys %{ $p }], [qw(A B C E)], 'every sample is predicted';

foreach my $s (qw(A B C)) {
	foreach my $t (qw(eye hair_shade)) {
		my @off = grep { abs($p->{$s}{$t}{p}{$_} - $expect{$s}{$t}{$_}) > $tol } sort keys %{ $expect{$s}{$t} };
		is scalar @off, 0, "$s $t probabilities are the reference's"
			or diag join ', ', map { "$_: got $p->{$s}{$t}{p}{$_}, want $expect{$s}{$t}{$_}" } @off;
		my $sum = 0;
		$sum += $_ foreach values %{ $p->{$s}{$t}{p} };
		cmp_ok abs($sum - 1), '<', $tol, "$s $t probabilities sum to 1";
	}
}

is $p->{A}{eye}{call}, 'brown', 'A, carrying two copies of every counted allele, is called brown-eyed by this made-up model';
is $p->{C}{eye}{call}, 'blue', 'C, carrying none, is called blue-eyed by it';
is $p->{A}{eye}{markers}, 2, 'the model\'s eye categories use two markers between them';
is $p->{A}{eye}{called}, 2, 'A has a genotype for both';
is_deeply $p->{A}{eye}{missing}, [], 'so none is missing';
is $p->{A}{eye}{refused}, undef, 'and the prediction is not refused';

# E is refused an eye prediction, by the rule hirisplex_genotypes applied, and
# still gets one for a trait that rule says nothing about.
is_deeply $p->{E}{eye}{p}, {}, 'E gets no eye probabilities';
is $p->{E}{eye}{call}, undef, 'and no eye call';
like $p->{E}{eye}{refused}, qr/HIrisPlex-S rules refuse it/, 'with a reason that names the rule';
is $p->{E}{hair_shade}{call}, 'dark', 'E is still given a hair_shade call';
is $p->{E}{hair_shade}{called}, 0, 'from no marker at all, its one marker being a no-call';
is_deeply $p->{E}{hair_shade}{missing}, ['rs1805007_T'], 'which is named';

# force predicts it anyway, and then E's two markers give blue and
# intermediate the same linear predictor, 0.5.
my $forced = trait_predict(genotypes => $g, model => $model, force => 1, report => 0);
is $forced->{E}{eye}{refused}, undef, 'force => 1 refuses nothing';
foreach my $c (sort keys %{ $expect{E}{eye} }) {
	cmp_ok abs($forced->{E}{eye}{p}{$c} - $expect{E}{eye}{$c}), '<', $tol, "forced, E's eye $c probability is the reference's";
}

# trait_predict takes a plain hash of marker => dosage too, which is what a
# caller who has genotypes from somewhere else has; without the flags
# hirisplex_genotypes sets, nothing is refused.
my $plain = trait_predict(genotypes => { X => { 'rs12913832_T' => 0, 'rs16891982_C' => 0, 'rs1805007_T' => 0 } },
	model => $model, report => 0);
foreach my $c (sort keys %{ $expect{C}{eye} }) {
	cmp_ok abs($plain->{X}{eye}{p}{$c} - $expect{C}{eye}{$c}), '<', $tol,
		"a plain hash of genotypes predicts eye $c as the same dosages do through hirisplex_genotypes";
}

# The MC1R 86insA (rs312262906, at b37 16:89985751) is counted only from an ALT
# that is REF with one A put in, however the indel is anchored. Any ALT longer
# than REF used to count, so an MNV or a symbolic <INS> was taken for it. And
# bases are compared regardless of case, as CHROM is, where a lower-case REF or
# ALT used to match nothing and leave the marker 0 copies. rs11547464, at
# 16:89986091, counts A.
{
	my $n = 0;
	my $one = sub {
		my (@records) = @_;
		my $file = catfile($dir, 'ins' . ++$n . '.vcf');
		open my $fh, '>', $file or die "can't write $file: $!";
		print {$fh} "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS\n";
		print {$fh} join("\t", @{ $_ }[0, 1], '.', @{ $_ }[2, 3], '.', 'PASS', '.', 'GT', $_->[4]), "\n" foreach @records;
		close $fh or die "can't write $file: $!";
		hirisplex_genotypes(vcf => $file, build => 'b37', min_depth => 0, report => 0)->{S}{genotype};
	};
	is $one->([16, 89985751, 'AA', 'AAA', '1/1'])->{'rs312262906_A'}, 2, 'the insertion, anchored on AA, counts 2 copies of 1/1';
	is $one->([16, 89985751, 'C', 'CA', '0/1'])->{'rs312262906_A'}, 1, 'and anchored on another base, 1 copy of 0/1';
	is $one->([16, 89985751, 'A', 'AT,AA', '0/2'])->{'rs312262906_A'}, 1, 'and as the second ALT, after an insertion of T';
	is $one->([16, 89985751, 'AC', 'GTT', '1/1'])->{'rs312262906_A'}, 0, 'an MNV longer than its REF is not the insertion, where it used to count 2';
	is $one->([16, 89985751, 'A', '<INS>', '1/1'])->{'rs312262906_A'}, 0, 'nor is a symbolic <INS>';
	is $one->([16, 89985751, 'A', 'AAA', '1/1'])->{'rs312262906_A'}, 0, 'nor an insertion of two As';
	my $lower = $one->([16, 89985751, 'a', 'aa', '0/1'], [16, 89986091, 'a', 'g', '0/1']);
	is $lower->{'rs312262906_A'}, 1, 'a lower-case insertion counts';
	is $lower->{'rs11547464_A'}, 1, 'and a lower-case REF of the counted allele, where it used to count 0';
}

done_testing();
