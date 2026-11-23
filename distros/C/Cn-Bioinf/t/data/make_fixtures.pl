#!/usr/bin/env perl
# Regenerates query.fa, subjects.fa, hits.json and nr.json in this directory; the tests
# only read what it wrote. Re-run from the distribution root, with Alien::Bioinf
# installed, as
#
#   perl t/data/make_fixtures.pl
#
# DEG20010421.fa is ~/identify.target/cryptococcus/fa/clustal.DEG20010421.input.fa
# (copied 2026-09-29): S.cerevisiae DEG20010421 and its three C.neoformans hits,
# with a few gaps left in from an earlier alignment, which are stripped here.
# hits.json is blastp 2.17.0+ (-outfmt 15) of S.cerevisiae against a database of
# the three C.neoformans sequences plus two made-up subjects that exercise
# get_best_alignment_hit's awkward cases:
#   - JEC21's sequence again under H99's defline: two hits with one title,
#     which the old hash-keyed version silently merged;
#   - S.cerevisiae residues 1-150 and 301-450 joined by 60 random residues
#     (srand 20260929), which blastp reports as one hit with two hsps.
# nr.json (added 2026-10-17) is blastp 2.17.0+ (-outfmt 15) of a made-up
# 52-residue query against a made-up two-record database built with
# -parse_seqids, whose first record carries two deflines joined by ^A, as
# NCBI's nr does for one sequence deposited under two accessions. blastp
# reports that hit with two descriptions, which get_best_alignment_hit died on
# up to 2026-10-17.
use strict;
use warnings;
use FindBin;
use Alien::Bioinf;

chdir $FindBin::Bin or die "$FindBin::Bin: $!";
my (%seq, $name);
open my $in, '<', 'DEG20010421.fa' or die $!;
while (<$in>) {
	chomp;
	if (/^>(.+)/) { $name = $1; next }
	(my $s = $_) =~ tr/-//d;
	$seq{$name} .= $s;
}
close $in;
srand 20260929;
my @aa = split //, 'ACDEFGHIKLMNPQRSTVWY';
my $filler = join '', map { $aa[int rand @aa] } 1 .. 60;
my $q = $seq{'S.cerevisiae'};
open my $s, '>', 'subjects.fa' or die $!;
print {$s} ">$_\n$seq{$_}\n" foreach qw(C.neoformans.B.3501A C.neoformans.grubii.H99 C.neoformans.JEC21);
print {$s} ">C.neoformans.grubii.H99\n$seq{'C.neoformans.JEC21'}\n";
print {$s} '>S.cerevisiae.chimera' . "\n" . substr($q, 0, 150) . $filler . substr($q, 300, 150) . "\n";
close $s;
open my $qf, '>', 'query.fa' or die $!;
print {$qf} ">S.cerevisiae\n$q\n";
close $qf;
# The databases are named relative to this directory, which is the working
# directory since the chdir above: blastp copies -db into its JSON as
# "search_target", and up to 2026-11-11 the fixtures so held the absolute path
# of the maintainer's copy.
my $db = 'subjects.db';
system(Alien::Bioinf->blast('makeblastdb'), '-in', 'subjects.fa', '-dbtype', 'prot', '-out', $db) == 0 or die 'makeblastdb failed';
system(Alien::Bioinf->blast('blastp'), '-query', 'query.fa', '-db', $db, '-outfmt', 15, '-out', 'hits.json') == 0 or die 'blastp failed';
unlink glob "$db.*";

my $nr_seq = 'MKVLAAGIVGLLLAQSAFAQEEKKTEVLNVGSTPYESFKKAAEGAGIDFHVFENGSEKAIAAIKAGEVDAAMVGTEP';
open my $nr, '>', 'nr.fa' or die $!;
print {$nr} ">sp|P11111.1| protein A [Org one]\x01sp|P22222.1| protein A [Org two]\n$nr_seq\n>sp|P33333.1| protein B\n" . substr($nr_seq, 5) . "W\n";
close $nr;
open my $nq, '>', 'nr.query.fa' or die $!;
print {$nq} '>q' . "\n" . substr($nr_seq, 0, 52) . "\n";
close $nq;
my $nr_db = 'nr.db';
system(Alien::Bioinf->blast('makeblastdb'), '-in', 'nr.fa', '-dbtype', 'prot', '-parse_seqids', '-out', $nr_db) == 0 or die 'makeblastdb failed';
system(Alien::Bioinf->blast('blastp'), '-query', 'nr.query.fa', '-db', $nr_db, '-outfmt', 15, '-out', 'nr.json') == 0 or die 'blastp failed';
unlink glob("$nr_db.*"), 'nr.fa', 'nr.query.fa';
