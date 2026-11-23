require 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use File::Spec;
use File::Spec::Functions qw(catfile);
use Cn::Bioinf qw(blood_type);

# t/data/blood.vcf was written by t/data/make_blood_vcf.pl on 2026-11-10; its
# header says what each sample tests. It has a record for every marker of
# share/blood_type_panel.tsv, so nothing in it rests on a marker being absent.
#
# The expected types of its 16 samples are what t/data/blood_reference.py, a
# second implementation of the same rules that shares no code with the module,
# printed under Python 3.14.2 on 2026-11-10, with a min_depth of 7 and of 0,
# and again on 2026-11-16, after it and the module stopped calling a sample RhD
# negative from sites where it has no genotype (BB and OO changed):
#
#   python3 -I t/data/blood_reference.py share/blood_type_panel.tsv t/data/blood.vcf 7
#
# The cases after those are small VCFs written here, which test what that file
# cannot: a marker the file has no record of, a record of RHD's deletion, and
# GRCh38. Their expected values were worked out by hand from the rules in the
# README on 2026-11-10, and each case says which rule it is.
#
# The panel itself was checked against real genomes, which no smoker has: the
# README gives the counts for 1000 Genomes, and for three exomes whose RhD
# types are known from the depth of their reads over RHD.

my $data = catfile($FindBin::Bin, 'data');
my $vcf = catfile($data, 'blood.vcf');
my $dir = tempdir(CLEANUP => 1);
# blood_type prints its report to STDOUT, which TAP is on too; Test::More has
# its own copy of that handle, made as it loaded, so STDOUT can go elsewhere.
open STDOUT, '>', File::Spec->devnull or die "can't send STDOUT to the null device: $!";
sub spew {
	my ($name, @lines) = @_;
	my $f = catfile($dir, $name);
	open my $fh, '>:raw', $f or die $!;
	print {$fh} map { ref $_ ? join("\t", @{ $_ }) . "\n" : "$_\n" } @lines;
	close $fh or die $!;
	$f;
}
sub slurp { open my $fh, '<:raw', $_[0] or die "$_[0]: $!"; local $/; <$fh> }
# What was printed through STDOUT to the file $_[0]. STDOUT is opened in text
# mode, so on Windows each "\n" printed is "\r\n" in the file; reading the file
# in text mode too gives "\n" back, which slurp, being :raw, would not.
sub printed { open my $fh, '<', $_[0] or die "$_[0]: $!"; local $/; <$fh> }
# what $code printed to STDOUT, and what it returned
sub stdout_of {
	my ($code) = @_;
	my $file = catfile($dir, 'stdout.txt');
	open my $save, '>&', \*STDOUT or die $!;
	open STDOUT, '>', $file or die $!;
	my $r = $code->();
	open STDOUT, '>&', $save or die $!;
	my $text = printed($file); # scalar context: an empty file is '', not an empty list
	($text, $r);
}
sub warnings_of {
	my ($code) = @_;
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	$code->();
	@w;
}
# the fields of one sample's answer that the reference prints, in its order
sub answer {
	my ($s) = @_;
	[$s->{type}, @{ $s->{abo} }{qw(genotype phenotype)}, @{ $s->{rhesus} }{qw(genotype phenotype carried)}];
}

# GRCh37's and GRCh38's lengths of chromosome 1, which the build is told by
my @b37 = ('##fileformat=VCFv4.2', '##contig=<ID=1,length=249250621>');
my @b38 = ('##fileformat=VCFv4.2', '##contig=<ID=1,length=248956422>');
sub columns { ['#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT), @_] }

# ---- a file with a record for every marker

# sample => [type, ABO genotype, ABO phenotype, RhD genotype, RhD phenotype,
# RHD sites carried], as t/data/blood_reference.py printed them for a
# min_depth of 7
my @expect = (
	[AA     => 'A+',  'AA', 'A',  'D.', 'positive', 15],
	[AO     => 'A+',  'AO', 'A',  'D.', 'positive', 1],
	[BB     => undef, 'BB', 'B',  undef, undef, 0],
	[BO     => 'B-',  'BO', 'B',  'dd', 'negative', 0],
	[AB     => 'AB+', 'AB', 'AB', 'D.', 'positive', 15],
	[OO     => undef, 'OO', 'O',  undef, undef, 0],
	[OOb    => 'O-',  'OO', 'O',  'dd', 'negative', 0],
	[AO2    => 'A+',  'AO', 'A',  'D.', 'positive', 15],
	[O2O    => 'O-',  'OO', 'O',  'dd', 'negative', 0],
	[BO2    => 'B+',  'BO', 'B',  'D.', 'positive', 15],
	[BOb    => 'B+',  'BO', 'B',  'D.', 'positive', 15],
	[NCf    => undef, undef, undef, 'D.', 'positive', 15],
	[NCb    => undef, undef, undef, 'dd', 'negative', 0],
	[HAP    => undef, undef, undef, 'D.', 'positive', 15],
	[SHAL   => undef, undef, undef, 'dd', 'negative', 0],
	[PHASED => 'B+',  'BO', 'B',  'D.', 'positive', 15],
);

my $b = blood_type(vcf => $vcf, report => 0);
is_deeply [sort keys %{ $b }], [sort map { $_->[0] } @expect], 'every sample of the VCF is returned';
foreach my $e (@expect) {
	my ($name, @want) = @{ $e };
	is_deeply answer($b->{$name}), \@want, "$name: " . join(', ', 'type ' . ($want[0] // 'none'), 'ABO ' . ($want[1] // 'none'), 'RhD ' . ($want[3] // 'none'));
}

# every answer has the same keys, whichever way it was reached
foreach my $name (map { $_->[0] } @expect) {
	is_deeply [sort keys %{ $b->{$name} }], [qw(abo rhesus type)], "$name: has abo, rhesus and type";
	is_deeply [sort keys %{ $b->{$name}{abo} }], [qw(assumed_ref genotype markers phenotype why)], "$name: abo's keys";
	is_deeply [sort keys %{ $b->{$name}{rhesus} }], [qw(basis carried deleted genotype listed phenotype sites why)], "$name: rhesus's keys";
}

is_deeply $b->{BO2}{abo}{markers}, { rs8176719 => 2, rs8176746 => 1, rs41302905 => 1 }, 'the copies of each ABO marker are returned, by rs number';
is_deeply $b->{NCb}{abo}{markers}, { rs8176719 => 1, rs8176746 => undef, rs41302905 => 0 }, 'and undef for a marker with no genotype';
is_deeply $b->{AA}{abo}{assumed_ref}, [], 'no marker is taken as REF when the file has a record of each';
is $b->{AA}{abo}{why}, undef, 'a sample with an ABO type has no "why"';
like $b->{NCf}{abo}{why}, qr/^no genotype at rs8176719: the call is missing, is not diploid, or has a DP below 7$/, 'a no-call at rs8176719 is why NCf has no ABO type';
like $b->{NCb}{abo}{why}, qr/^no genotype at rs8176746: /, 'a no-call at rs8176746 is why NCb has none, since a working gene may be B';
like $b->{HAP}{abo}{why}, qr/^no genotype at rs8176719: /, 'a haploid call is not a genotype';
is $b->{AA}{rhesus}{basis}, 'sites', 'RhD is told from the RHD sites';
is $b->{AA}{rhesus}{sites}, 15, 'of which the panel has 15';
is $b->{AA}{rhesus}{listed}, 15, 'and the file a record of each';
is $b->{AA}{rhesus}{deleted}, undef, 'with no record of a deletion';
is $b->{BO}{rhesus}{why}, undef, 'a sample with an RhD type has no "why"';
# Up to 2026-11-16 a sample with no ALT at any RHD site was RhD negative even
# when it had no genotype at any of them either, so that BB's no-calls and OO's
# calls below min_depth (15 homozygous ALTs at DP 3) were both "dd".
is $b->{BB}{rhesus}{carried}, 0, 'BB carries no ALT at an RHD site';
is $b->{BB}{rhesus}{why}, 'no genotype at any of the 15 RHD sites the file has a record of: the calls are missing, are not diploid, or have a DP below 7',
	'and with no genotype at any of them it has no RhD type, rather than being called negative';
like $b->{OO}{rhesus}{why}, qr/^no genotype at any of the 15 RHD sites /, 'nor has OO, whose calls there are all below min_depth';
is $b->{BO}{rhesus}{phenotype}, 'negative', 'while BO, homozygous REF at every site, is still negative';

# min_depth: OO's sites and SHAL's rs8176719 are at a DP of 3
{
	my $all = blood_type(vcf => $vcf, min_depth => 0, report => 0);
	is_deeply answer($all->{OO}), ['O+', 'OO', 'O', 'D.', 'positive', 15], 'min_depth => 0 counts OO\'s shallow RHD sites';
	is_deeply answer($all->{SHAL}), ['A-', 'AO', 'A', 'dd', 'negative', 0], 'and SHAL\'s shallow rs8176719';
	is_deeply answer($all->{AB}), answer($b->{AB}), 'and leaves a sample of DP 30 as it was';
	my $three = blood_type(vcf => $vcf, min_depth => 3, report => 0);
	is $three->{SHAL}{type}, 'A-', 'a DP equal to min_depth is counted';
	my $four = blood_type(vcf => $vcf, min_depth => 4, report => 0);
	is $four->{SHAL}{type}, undef, 'and one below it is not';
}

# the file may come first, unnamed
is_deeply blood_type($vcf, report => 0), $b, 'blood_type($file, %options) is blood_type(vcf => $file, %options)';

# ---- the report

{
	my ($out, $r) = stdout_of(sub { blood_type(vcf => $vcf) });
	is_deeply $r, $b, 'the report changes nothing that is returned';
	my @line = split /\n/, $out;
	is $line[0], "blood_type: $vcf", 'the report names the file';
	like $line[1], qr/^ABO from rs8176719 \(O's deletion\), rs8176746 \(B\) and rs41302905 \(O2\); RhD from 15 sites of RHD, or a record of the gene's deletion; matched by position on b37; genotypes of DP below 7 not counted$/,
		'and says what it read, on which build, and at what depth';
	like $line[2], qr/^sample +type +ABO +ABO genotype +RhD +RhD genotype +RHD sites$/, 'the table\'s heading';
	like $line[3], qr/^AA +A\+ +A +AA +positive +D\. +15\/15$/, 'the first sample of the file is the first row';
	like $line[14], qr/^NCf +- +- +- +positive +D\. +15\/15$/, 'a sample with no ABO type has "-" for it';
	is_deeply [map { (split ' ')[0] } @line[3 .. 18]], [map { $_->[0] } @expect], 'every sample has a row, in the file\'s order';
	is scalar(grep { / has no ABO type: / } @line), 4, 'and each of the four with no ABO type a line saying why';
	is scalar(grep { / has no RhD type: / } @line), 2, 'as do the two with no RhD type';
	like $line[5], qr/^BB +- +B +BB +- +- +0\/15$/, 'a sample with an ABO type and no RhD type has "-" for the type and RhD';
	like $out, qr/^NCb has no ABO type: no genotype at rs8176746: /m, 'and the report says why a sample has no type';
	unlike $out, qr/taken as homozygous/, 'nothing is said to be taken as REF when nothing was';
	($out) = stdout_of(sub { blood_type(vcf => $vcf, report => 0) });
	is $out, '', 'report => 0 prints nothing';
}

# ---- a file of one sample's variants: a marker with no record

# The usual file: only the sites where the sample carries an ALT allele. The
# sample has one working gene (a record of rs8176719's insertion, 0/1) and no
# record of the B or O2 marker, which are read as homozygous REF, so it is AO.
# It has a record on chromosome 1 but none at an RHD site, so every site is
# read as REF and it is RhD negative.
{
	my $own = spew('own.vcf', @b37, columns('S'),
		[qw(1 1000 . A G . PASS . GT:DP 0/1:30)],
		[qw(9 136132908 . T TC . PASS . GT:DP 0/1:30)]);
	my $r = blood_type(vcf => $own, report => 0)->{S};
	is_deeply answer($r), ['A-', 'AO', 'A', 'dd', 'negative', 0], 'a file of one sample\'s variants: AO from the insertion alone, and RhD negative from no site';
	is_deeply $r->{abo}{assumed_ref}, [qw(rs8176746 rs41302905)], 'and it names the markers it took as REF';
	is_deeply $r->{abo}{markers}, { rs8176719 => 1, rs8176746 => 0, rs41302905 => 0 }, 'which count as no copies';
	is $r->{rhesus}{listed}, 0, 'the file has a record of no RHD site';
	my ($out) = stdout_of(sub { blood_type(vcf => $own) });
	like $out, qr/^not in the file, and taken as homozygous for the reference allele: rs8176746, rs41302905, 15 of the 15 RHD sites$/m,
		'the report says what was taken as REF';

	# assume_ref => 0: a marker with no record has no genotype
	$r = blood_type(vcf => $own, assume_ref => 0, report => 0)->{S};
	is_deeply answer($r), [undef, undef, undef, undef, undef, 0], 'assume_ref => 0: neither type is told from a missing record';
	is $r->{abo}{why}, 'the file has no record of rs8176746, and "assume_ref" is 0', 'and abo says which record it lacked';
	like $r->{rhesus}{why}, qr/^the file has no record of rs[0-9]+, and "assume_ref" is 0$/, 'as rhesus does';
	is_deeply $r->{abo}{assumed_ref}, [], 'and nothing is listed as taken as REF';
	is $r->{rhesus}{basis}, undef, 'a sample with no RhD type has no basis for one';
}

# The reference genome carries O's deletion, so somebody who is OO has no
# record at any ABO marker. The file has an indel elsewhere on chromosome 9,
# so it could have shown the insertion, and its absence is read as OO.
{
	my $oo = spew('oo.vcf', @b37, columns('S'),
		[qw(1 1000 . A G . PASS . GT 0/1)],
		[qw(9 5000 . AT A . PASS . GT 0/1)]);
	my $r = blood_type(vcf => $oo, report => 0)->{S};
	is_deeply answer($r), ['O-', 'OO', 'O', 'dd', 'negative', 0], 'no record at any ABO marker, in a file with an indel on chromosome 9, is OO';
	is_deeply $r->{abo}{assumed_ref}, [qw(rs8176719 rs8176746 rs41302905)], 'with all three markers taken as REF';
}

# A file of SNVs only cannot hold the insertion, so its absence says nothing,
# and no ABO type is given, where reading it as REF would call everybody O.
{
	my $snv = spew('snv.vcf', @b37, columns('S'),
		[qw(1 1000 . A G . PASS . GT 0/1)],
		[qw(9 5000 . A G . PASS . GT 0/1)],
		[qw(9 136131322 . G T . PASS . GT 0/1)]);
	my $r = blood_type(vcf => $snv, report => 0)->{S};
	is $r->{abo}{genotype}, undef, 'a file of SNVs only gives no ABO type, rather than OO';
	is $r->{abo}{why}, 'the file has no record of rs8176719, an insertion, and no allele longer than one base on chromosome 9, so it holds SNVs only and could not show it',
		'and says that it could not have shown the insertion';
	is $r->{abo}{markers}{rs8176746}, 1, 'its B marker is still read';
	is $r->{rhesus}{phenotype}, 'negative', 'and its RhD type still told';
	is $r->{type}, undef, 'with no ABO type there is no type';
}

# A file with no record on a marker's chromosome was not called there, and
# nothing is read into the absence.
{
	my $nine = spew('nine.vcf', @b37, columns('S'), [qw(9 136132908 . T TC . PASS . GT 1/1)]);
	my $r;
	my @w = warnings_of(sub { $r = blood_type(vcf => $nine, report => 0)->{S} });
	is $r->{abo}{genotype}, 'AA', 'a file of chromosome 9 alone gives an ABO type';
	is $r->{rhesus}{phenotype}, undef, 'and no RhD type, rather than RhD negative';
	is $r->{rhesus}{why}, 'the file has no record on chromosome 1', 'saying that it has nothing on chromosome 1';
	is scalar(@w), 0, 'without a warning, since one of the two could be told';

	my $other = spew('other.vcf', @b37, columns('S'), [qw(2 1000 . A G . PASS . GT 0/1)]);
	@w = warnings_of(sub { $r = blood_type(vcf => $other, report => 0)->{S} });
	is_deeply answer($r), [undef, undef, undef, undef, undef, 0], 'a file with nothing on chromosome 1 or 9 gives no type';
	is scalar(@w), 1, 'and one warning';
	like $w[0], qr/^blood_type: "vcf" \Q$other\E has no record on chromosome 1 or 9, matched by position on b37, so no blood type can be told; check that it is the build the file is on at \Q${\ __FILE__}\E line \d+\.?\n\z/,
		'which says so, at the caller\'s line';
}

# ---- a record of RHD's deletion

# 1000 Genomes' phase 3 writes the deletion as 1:25592642 <CN0>, END=25661222,
# with <CN2> for a duplication. A sample's copies of <CN0> are its genotype:
# none is DD, one Dd and two dd. S3 carries the duplication, which is not a
# deletion, and has no <CN0>. S4 has no call of it, so falls back on the sites.
{
	my @samples = qw(S0 S1 S2 S3 S4);
	my $del = spew('deletion.vcf', @b37, columns(@samples),
		# split, not qw, which warns of the comma in the ALT
		[split ' ', '1 25592642 . T <CN0>,<CN2> . PASS END=25661222;SVTYPE=CNV GT 0|0 0|1 1|1 2|0 .|.']);
	my $r = blood_type(vcf => $del, report => 0);
	is_deeply [map { $r->{$_}{rhesus}{genotype} } @samples], [qw(DD Dd dd DD dd)], 'a record of the deletion gives DD, Dd and dd';
	is_deeply [map { $r->{$_}{rhesus}{phenotype} } @samples], [qw(positive positive negative positive negative)], 'of which only dd is negative';
	is_deeply [map { $r->{$_}{rhesus}{deleted} } @samples], [0, 1, 2, 0, undef], 'and the copies deleted are returned';
	is_deeply [map { $r->{$_}{rhesus}{basis} } @samples], [qw(deletion deletion deletion deletion sites)], 'a sample with no call of it is told from the sites';

	# The deletion's record outranks the sites: S carries an ALT at an RHD site
	# (the panel's first on GRCh37, 1:25604252 A>G) and two copies of the deletion.
	my $both = spew('both.vcf', @b37, columns('S'),
		[qw(1 25592642 . T <CN0> . PASS END=25661222 GT 1|1)],
		[qw(1 25604252 . A G . PASS . GT 0/1)]);
	my $s = blood_type(vcf => $both, report => 0)->{S};
	is_deeply [@{ $s->{rhesus} }{qw(genotype basis carried)}], ['dd', 'deletion', 1], 'the deletion\'s record outranks an ALT at an RHD site';

	# <DEL> with SVLEN, and deletions that leave part of the gene (1:25598884-25656936)
	foreach my $case (
		['<DEL> with END',            [qw(1 25592000 . N <DEL> . PASS SVTYPE=DEL;END=25662000 GT 0/1)], 'Dd', 'deletion'],
		['<DEL> with SVLEN',          [qw(1 25592000 . N <DEL> . PASS SVTYPE=DEL;SVLEN=-70000 GT 0/1)], 'Dd', 'deletion'],
		['<DEL:ME> with END',         [qw(1 25592000 . N <DEL:ME> . PASS END=25662000 GT 1/1)], 'dd', 'deletion'],
		['one that covers the gene exactly', [qw(1 25598884 . N <DEL> . PASS END=25656936 GT 0/1)], 'Dd', 'deletion'],
		['one that starts inside the gene',  [qw(1 25598885 . N <DEL> . PASS END=25662000 GT 1/1)], 'dd', 'sites'],
		['one that ends inside the gene',    [qw(1 25592000 . N <DEL> . PASS END=25656935 GT 1/1)], 'dd', 'sites'],
		['one whose SVLEN is too short',     [qw(1 25592000 . N <DEL> . PASS SVLEN=-1000 GT 1/1)], 'dd', 'sites'],
		['one with no END or SVLEN',         [qw(1 25592000 . N <DEL> . PASS SVTYPE=DEL GT 1/1)], 'dd', 'sites'],
		['a duplication',                    [qw(1 25592000 . N <DUP> . PASS END=25662000 GT 1/1)], 'dd', 'sites'],
	) {
		my ($name, $record, $genotype, $basis) = @{ $case };
		my $f = spew('sv.vcf', @b37, columns('S'), $record);
		my $got = blood_type(vcf => $f, report => 0)->{S}{rhesus};
		is_deeply [@{ $got }{qw(genotype basis)}], [$genotype, $basis], "$name is read from the $basis";
	}
}

# ---- GRCh38

# The same sample on GRCh38: rs8176719 at 9:133257521 and the B marker at
# 9:133255935, both heterozygous, so BO; and an ALT at the panel's first RHD
# site, 1:25277761 A>G, so RhD positive. On GRCh37's coordinates the same
# records are nowhere near a marker.
{
	my @records = ([qw(1 25277761 . A G . PASS . GT 0/1)], [qw(9 133255935 . G T . PASS . GT 0/1)], [qw(9 133257521 . T TC . PASS . GT 0/1)]);
	my $f38 = spew('b38.vcf', @b38, columns('S'), @records);
	my $r = blood_type(vcf => $f38, report => 0)->{S};
	is_deeply answer($r), ['B+', 'BO', 'B', 'D.', 'positive', 1], 'GRCh38 is told from the header\'s ##contig length, and its positions used';
	my ($out) = stdout_of(sub { blood_type(vcf => $f38) });
	like $out, qr/matched by position on b38;/, 'and the report names the build';
	my $bare = spew('bare.vcf', '##fileformat=VCFv4.2', columns('S'), @records);
	is_deeply answer(blood_type(vcf => $bare, build => 'hg38', report => 0)->{S}), ['B+', 'BO', 'B', 'D.', 'positive', 1], 'build => hg38 names it for a header with no lengths';
	is_deeply answer(blood_type(vcf => $bare, build => 'b38', report => 0)->{S}), ['B+', 'BO', 'B', 'D.', 'positive', 1], 'as b38 does';
	is_deeply answer(blood_type(vcf => $f38, build => 'hg19', report => 0)->{S}), ['O-', 'OO', 'O', 'dd', 'negative', 0],
		'build => hg19 overrides the header, and finds no marker at GRCh37\'s positions';
}

done_testing;
