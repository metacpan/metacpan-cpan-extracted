#!/usr/bin/env perl
# Writes t/data/pdb_search.json: the answers RCSB's search and data APIs gave
# pdb_search for human haemoglobin alpha (UniProt P69905), which t/pdb.t
# replays in place of the network. Re-run it from the repository root, with
# the module built, as
#
#     perl -Mblib t/data/make_pdb_fixtures.pl
#
# It needs the network; the tests never run it. pdb_search is called with
# computed => 1 and max_hits => 10000, and the search API's answer is cut down,
# before the data API is asked about it, to the hits in @keep, so that the file
# stays small. Those were chosen on 2026-10-21 as the best hit (1BZ1_1, which
# ties 1Y01_2), two gapped alignments (6IYI_1 with one gap, 1CH4_1 with three
# gap openings), and the AlphaFold model of P69905 itself. total_count is left
# as RCSB gave it.
use 5.036;
use JSON::PP ();
use Cn::Bioinf qw(pdb_search);

my $seq = 'MVLSPADKTNVKAAWGKVGAHAGEYGAEALERMFLSFPTTKTYFPHFDLSHGSAQVKGHGKKVADALTNAVAHVDDMPNALSALSDLHAHKLRVDPVNFKLLSHCLLVTLAAHLPAEFTPAVHASLDKFLASVSTVLTSKYR';
my @keep = qw(1BZ1_1 1Y01_2 6IYI_1 1CH4_1 AF_AFP69905F1_1);
my %keep = map { $_ => 1 } @keep;
my $out = 't/data/pdb_search.json';

my $post = \&Cn::Bioinf::_rcsb_post;
my @answers;
{
	no warnings 'redefine';
	local *Cn::Bioinf::_rcsb_post = sub {
		my $json = $post->(@_);
		if (ref $json eq 'HASH' && $json->{result_set}) {
			$json->{result_set} = [grep { $keep{ $_->{identifier} } } @{ $json->{result_set} }];
			my %got = map { $_->{identifier} => 1 } @{ $json->{result_set} };
			my @lost = grep { !$got{$_} } @keep;
			die "RCSB no longer returns @lost\n" if @lost;
		}
		push @answers, { url => $_[1], answer => $json };
		$json;
	};
	pdb_search(seq => $seq, computed => 1, max_hits => 10000, report => 0);
}
open my $fh, '>:raw', $out or die "$out: $!";
print {$fh} JSON::PP->new->canonical->pretty->encode(\@answers);
close $fh or die "$out: $!";
say "wrote $out";
