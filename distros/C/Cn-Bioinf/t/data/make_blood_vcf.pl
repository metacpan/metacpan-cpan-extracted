#!/usr/bin/env perl
# Writes blood.vcf in this directory, for t/blood.t; the tests only read what
# it wrote. Re-run from the distribution root as
#
#   perl t/data/make_blood_vcf.pl
#
# and then t/data/blood_reference.py, as t/blood.t's header says, for the
# expected types. It is built from share/blood_type_panel.tsv, so a refreshed
# panel changes it; read the diff before committing.
#
# The file is on GRCh37, with GRCh37's lengths for chromosomes 1 and 9 in its
# ##contig lines, and has a record for every marker of the panel, so nothing
# in it rests on a marker being absent. Each sample is named for what it
# tests. Its ABO genotypes are given below as copies of the counted allele at
# rs8176719 (the insertion: a working A or B gene), rs8176746 (B) and
# rs41302905 (O2), and its RHD sites as one genotype for all 15, or for the
# first and then the rest:
#
#   AA       2 0 0   sites 1/1          two working genes, neither B
#   AO       1 0 0   sites 0/1, 0/0     RhD positive from one site alone
#   BB       2 2 0   sites ./.          no call at any site
#   BO       1 1 0   sites 0/0          homozygous REF at every site
#   AB       2 1 0   sites 0/1
#   OO       0 0 0   sites 1/1 at DP 3  below the default min_depth
#   OOb      0 1 0   sites 0/0          B's base on a chromosome with the deletion is still O
#   AO2      2 0 1   sites 1/1          O2: an O with no deletion
#   O2O      1 0 1   sites 0/0
#   BO2      2 1 1   sites 0/1
#   BOb      1 2 0   sites 1/1          two B bases and one working gene
#   NCf      . 0 0   sites 1/1          no call at rs8176719
#   NCb      1 . 0   sites 0/0          no call at rs8176746, which a working gene needs
#   HAP      a haploid "1" at rs8176719, which is not a genotype; sites 1/1
#   SHAL     1 0 0 with rs8176719 at DP 3; sites 0/0
#   PHASED   1 1 0 written 1|0 and 0|2; sites 1|1
#
# Three records are written the awkward way, so that the reader is tested on
# them: rs8176746 has two ALTs with the counted T second, so its genotypes
# name allele 2; rs41302905's CHROM is "chr9"; and the first RHD site's is
# "chr1".
use 5.044;
use warnings FATAL => 'all';
use File::Spec;
use FindBin;

my $root = File::Spec->catdir($FindBin::Bin, File::Spec->updir, File::Spec->updir);
open my $in, '<', File::Spec->catfile($root, 'share', 'blood_type_panel.tsv') or die "can't read the panel: $!";
my $head = <$in>;
$head =~ s/\A#//;
chomp $head;
my @cols = split /\t/, $head;
my @marker; # the panel's markers, a hash ref each, in the panel's order
while (defined(my $line = <$in>)) {
	chomp $line;
	my %m;
	@m{@cols} = split /\t/, $line, -1;
	push @marker, \%m unless $m{kind} eq 'region';
}
close $in;
my %abo = map { $_->{role} => $_ } grep { $_->{system} eq 'ABO' } @marker;
my @site = grep { $_->{system} eq 'RHD' } @marker;

# sample => [copies at rs8176719, at rs8176746, at rs41302905, the first RHD
# site's genotype, the other sites' genotype]; a copy count of "." is "./.",
# and the three entries that are not counts are written as they stand
my @sample = (
	[AA     => 2, 0, 0, '1/1', '1/1'],
	[AO     => 1, 0, 0, '0/1', '0/0'],
	[BB     => 2, 2, 0, './.', './.'],
	[BO     => 1, 1, 0, '0/0', '0/0'],
	[AB     => 2, 1, 0, '0/1', '0/1'],
	[OO     => 0, 0, 0, '1/1:3', '1/1:3'],
	[OOb    => 0, 1, 0, '0/0', '0/0'],
	[AO2    => 2, 0, 1, '1/1', '1/1'],
	[O2O    => 1, 0, 1, '0/0', '0/0'],
	[BO2    => 2, 1, 1, '0/1', '0/1'],
	[BOb    => 1, 2, 0, '1/1', '1/1'],
	[NCf    => '.', 0, 0, '1/1', '1/1'],
	[NCb    => 1, '.', 0, '0/0', '0/0'],
	[HAP    => '1', 0, 0, '1/1', '1/1'],
	[SHAL   => '0/1:3', 0, 0, '0/0', '0/0'],
	[PHASED => '1|0', '0|2', 0, '1|1', '1|1'],
);

# The sample field for $copies of the ALT numbered $alt: "GT:DP", at a DP of
# 30 unless the entry brings its own.
sub field {
	my ($copies, $alt) = @_;
	return "$copies:30" if $copies =~ m{[/|]} && $copies !~ /:/;
	return $copies if $copies =~ /:/;
	return './.:30' if $copies eq '.';
	return '1:30' if $copies eq '1' && $alt eq 'haploid';
	return join('/', (0) x (2 - $copies), ($alt) x $copies) . ':30';
}

my @record; # [chromosome number, CHROM as written, POS, REF, ALT, the samples' fields]
{
	my $m = $abo{functional};
	push @record, [9, '9', $m->{b37_pos}, 'T', 'T' . $m->{count_allele}, map { field($_->[1], $_->[0] eq 'HAP' ? 'haploid' : 1) } @sample];
	$m = $abo{B};
	push @record, [9, '9', $m->{b37_pos}, $m->{ref_allele}, "A,$m->{count_allele}", map { field($_->[2], 2) } @sample];
	$m = $abo{O2};
	push @record, [9, 'chr9', $m->{b37_pos}, $m->{ref_allele}, $m->{count_allele}, map { field($_->[3], 1) } @sample];
}
foreach my $k (0 .. $#site) {
	my $m = $site[$k];
	push @record, [1, $k ? '1' : 'chr1', $m->{b37_pos}, $m->{ref_allele}, $m->{count_allele}, map { field($_->[$k ? 5 : 4], 1) } @sample];
}

my $file = File::Spec->catfile($FindBin::Bin, 'blood.vcf');
open my $out, '>', $file or die "can't write $file: $!";
print {$out} "##fileformat=VCFv4.2\n",
	"##contig=<ID=1,length=249250621>\n##contig=<ID=9,length=141213431>\n",
	"##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n",
	"##FORMAT=<ID=DP,Number=1,Type=Integer,Description=\"Read depth\">\n",
	join("\t", '#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT), map { $_->[0] } @sample), "\n";
foreach my $r (sort { $a->[0] <=> $b->[0] || $a->[2] <=> $b->[2] } @record) {
	my (undef, $chrom, $pos, $ref, $alt, @field) = @{ $r };
	print {$out} join("\t", $chrom, $pos, '.', $ref, $alt, '.', 'PASS', '.', 'GT:DP', @field), "\n";
}
close $out or die "can't write $file: $!";
