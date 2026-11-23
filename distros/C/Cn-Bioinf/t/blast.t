require 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin;
use Cn::Bioinf qw(get_best_alignment_hit);
# t/data/hits.json and how it was made: see t/data/make_fixtures.pl. The
# expected orders below are what bioinf.pm's get_best_alignment_hit returned
# for it on 2026-09-29, as [hit id, number of the hsp chosen].
#
# BL_ORD_ID 4 is the two-fragment chimera, whose hsp 1 has the best bit score
# and hsp 2 the longest alignment; 0, 2 and 3 tie on every field, so they come
# back in BLAST's order; 1 and 3 share a title.
#
# t/data/nr.json is blastp 2.17.0+ against a database whose first record has
# two deflines, as one in nr does; the expected accessions and title are the
# ones blastp listed in its "description" for each hit (checked 2026-10-17).

my $json = "$FindBin::Bin/data/hits.json";
my $order = [4, 3, 2, 0, 1];
my %expect = (
	align_len => 2, bit_score => 1, evalue => 1, gaps => 1, identity => 2, positive => 2, score => 1,
);
foreach my $c (sort keys %expect) {
	my $r = get_best_alignment_hit($json, $c);
	is_deeply [keys %{ $r }], ['S.cerevisiae'], "$c: one query";
	my $hits = $r->{'S.cerevisiae'};
	is_deeply [map { $_->{id} } @{ $hits }], [map { "gnl|BL_ORD_ID|$_" } @{ $order }], "$c: hit order";
	is_deeply [map { $_->{num} } @{ $hits }], [$expect{$c}, 1, 1, 1, 1], "$c: hsp chosen per hit";
}
my $h = get_best_alignment_hit($json)->{'S.cerevisiae'};
is scalar(grep { $_->{title} eq 'C.neoformans.grubii.H99' } @{ $h }), 2, 'two hits with one title are both kept';
is_deeply [sort keys %{ $h->[0] }], [sort qw(accession align_len bit_score descriptions evalue gaps hit_from hit_len hit_to hseq id identity
	midline num positive qseq query_from query_to score title)], 'fields of a hit';
is $h->[0]{hit_len}, 360, 'hit_len is the subject length';
# Up to 2026-10-17 a hit with more than one description died
my $nr = get_best_alignment_hit("$FindBin::Bin/data/nr.json")->{q};
is_deeply [map { $_->{accession} } @{ $nr }], ['P11111', 'P33333'], 'a hit with two descriptions is kept under its first, rather than dying';
is_deeply [@{ $nr->[0] }{qw(id title)}], ['sp|P11111.1|', 'protein A [Org one]'], 'with the id and title of that first one';
is_deeply [map { $_->{accession} } @{ $nr->[0]{descriptions} }], ['P11111', 'P22222'], 'and every description in "descriptions"';
is_deeply [map { $_->{accession} } @{ $nr->[1]{descriptions} }], ['P33333'], 'which holds just the one for a hit with one';
eval { get_best_alignment_hit($json, 'hseq') };
like $@, qr/"hseq" isn't a sortable hsp field/, 'an unsortable field dies';
eval { get_best_alignment_hit("$FindBin::Bin/data/none.json") };
like $@, qr/doesn't exist or isn't a readable file/, 'a missing file dies';
done_testing;
