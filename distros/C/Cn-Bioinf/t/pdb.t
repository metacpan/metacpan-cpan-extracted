require 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin;
use JSON::MaybeXS ();
use Cn::Bioinf qw(pdb_search);
# t/data/pdb_search.json holds what RCSB's search API and data API answered
# pdb_search on 2026-10-21 for human haemoglobin alpha (UniProt P69905), cut
# down to five hits, as t/data/make_pdb_fixtures.pl says. The tests replay it
# in place of _rcsb_post, so that they need no network.
#
# The expected alignment fields are RCSB's own, from that file, except for
# identity, gaps, pident and query_cover, which RCSB does not give; they were
# counted from its aligned sequences by Python on 2026-10-21 (identity is the
# columns where the two agree and neither is a gap, gaps the "-" in either,
# pident 100 * identity / alignment_length, query_cover 100 * (query_end -
# query_beg + 1) / query_length), and pident is checked against RCSB's own
# sequence_identity, which it truncates to 3 places. The structure fields are
# the data API's, from the same file.
#
# With NETWORK_TESTING set, one search is also made of the real RCSB.

open my $fixture, '<:raw', "$FindBin::Bin/data/pdb_search.json" or die "pdb_search.json: $!";
my $recorded = JSON::MaybeXS::decode_json(do { local $/; <$fixture> });
close $fixture;
my $alpha = 'MVLSPADKTNVKAAWGKVGAHAGEYGAEALERMFLSFPTTKTYFPHFDLSHGSAQVKGHGKKVADALTNAVAHVDDMPNALSALSDLHAHKLRVDPVNFKLLSHCLLVTLAAHLPAEFTPAVHASLDKFLASVSTVLTSKYR';

# pdb_search run with @args, with _rcsb_post answering from @$answers in turn
# (a copy of the fixture's, unless given), and each request it was asked to
# make recorded as [url, body, timeout]. Returns the hits, the total, the
# requests, what was printed and what was warned.
sub replay {
	my ($answers, @args) = @_;
	my @queue = map { JSON::MaybeXS::decode_json(JSON::MaybeXS::encode_json($_->{answer} // {})) } @{ $answers // $recorded };
	@queue = map { ref $_ eq 'HASH' && !%{ $_ } ? undef : $_ } @queue; # {} stands for a 204
	my (@asked, $out, $warned);
	$warned = '';
	no warnings 'redefine';
	local *Cn::Bioinf::_rcsb_post = sub {
		push @asked, [@_[1 .. 3]];
		die "replay: asked more than the fixture answers\n" unless @queue;
		shift @queue;
	};
	local $SIG{__WARN__} = sub { $warned .= $_[0] };
	my ($hits, $total);
	{
		local *STDOUT;
		open STDOUT, '>', \$out or die "can't capture STDOUT: $!";
		($hits, $total) = pdb_search(@args);
		close STDOUT;
	}
	($hits, $total, \@asked, $out // '', $warned);
}

my @fields = sort qw(id entry entity url
	evalue bit_score align_len identity pident mismatches gaps gap_opens query_from query_to query_len query_cover hit_from hit_to hit_len qseq hseq
	title description method methodology resolution plddt polymer_type polymer_composition oligomeric_state stoichiometry symmetry
	chains organisms uniprot pfam interpro ligands deposited released);

# ---- the requests made

# lower case, a line break and a final stop, as a sequence pasted from a
# translated FASTA has; and the cutoffs as strings, which must still reach
# RCSB as numbers, since JSON::XS would write a string as one
my ($hits, $total, $asked, $out, $warned) = replay(undef, seq => lc(substr $alpha, 0, 70) . "\n" . substr($alpha, 70) . '*',
	computed => 1, evalue => '0.5', identity => '30', max_hits => '25', timeout => '9', report => 0);
is scalar(@{ $asked }), 2, 'one search, then one request of the data API';
my ($search, $data) = @{ $asked };
is $search->[0], 'https://search.rcsb.org/rcsbsearch/v2/query', 'the search goes to the search API';
is $data->[0], 'https://data.rcsb.org/graphql', 'and the structures are asked of the GraphQL data API';
is $search->[1]{query}{parameters}{value}, $alpha, 'the sequence is sent in upper case, with no whitespace or final stop';
my $json = JSON::MaybeXS->new(canonical => 1)->encode($search->[1]);
like $json, qr/"evalue_cutoff":0\.5[,}]/, 'evalue reaches RCSB as a number, not the string it was given';
like $json, qr/"identity_cutoff":0\.3[,}]/, 'identity, a percentage, reaches RCSB as a fraction';
like $json, qr/"rows":25[,}]/, 'max_hits reaches RCSB as a number of rows';
is_deeply $search->[1]{request_options}{results_content_type}, ['experimental', 'computational'], 'computed => 1 asks for computed models too';
is $search->[1]{query}{parameters}{sequence_type}, 'protein', 'type defaults to protein';
is $search->[1]{return_type}, 'polymer_entity', 'the hits are polymer entities, which is what has a sequence';
is $search->[2], 9, 'the timeout is passed on';
is_deeply $data->[1]{variables}{ids}, [qw(1BZ1_1 1Y01_2 AF_AFP69905F1_1 6IYI_1 1CH4_1)], 'the data API is asked about every hit, in the order RCSB gave them';

# the defaults
(undef, undef, $asked) = replay(undef, seq => $alpha, report => 0);
my $p = $asked->[0][1];
is_deeply [$p->{query}{parameters}{evalue_cutoff}, $p->{query}{parameters}{identity_cutoff}, $p->{request_options}{paginate}{rows}, $asked->[0][2]],
	[0.1, 0, 100, 60], 'evalue 0.1, identity 0, max_hits 100 and a 60 s timeout by default';
is_deeply $p->{request_options}{results_content_type}, ['experimental'], 'and experimental structures only';

# ---- what comes back

is $total, 1952, 'the total is how many hits RCSB found, not how many it returned';
is_deeply [map { $_->{id} } @{ $hits }], [qw(1BZ1_1 1Y01_2 AF_AFP69905F1_1 6IYI_1 1CH4_1)],
	'best first: by E-value, the three that tie in RCSB\'s order';
is_deeply [sort keys %{ $_ }], \@fields, "$_->{id} has every field" foreach @{ $hits };
my %h = map { $_->{id} => $_ } @{ $hits };

# 1CH4_1: three gap openings, eight gap columns
is_deeply { map { $_ => $h{'1CH4_1'}{$_} } qw(bit_score align_len identity mismatches gaps gap_opens query_from query_to query_len hit_from hit_to hit_len) },
	{ bit_score => 168, align_len => 146, identity => 89, mismatches => 49, gaps => 8, gap_opens => 3,
		query_from => 3, query_to => 142, query_len => 142, hit_from => 3, hit_to => 146, hit_len => 146 },
	'a gapped alignment: RCSB\'s numbers, and the identities and gaps counted from its sequences';
# The E-value is RCSB's 9.682e-47 to within a relative 1e-12, rather than equal
# to it: it reaches pdb_search through whichever JSON decoder JSON::MaybeXS
# found, and not every decoder rounds a number correctly. On Strawberry Perl
# 5.24.4 it came back as 9.6820000000001e-47, a relative error of about 1e-14
# (CPAN Testers report 620bc624-ddea-11f1-b231-87fe50e89311, 2026-11-11), so
# 1e-12 is a hundred times what was seen. The fixture's nearest other E-value,
# 1.062e-47, is a factor of 9 away, so the wrong hit's would still fail.
cmp_ok abs($h{'1CH4_1'}{evalue} / 9.682e-47 - 1), '<', 1e-12, 'and RCSB\'s E-value, as nearly as the JSON decoder gives it';
cmp_ok abs($h{'1CH4_1'}{pident} - 60.9589041096), '<', 1e-9, 'pident is 100 * identity / align_len';
cmp_ok abs($h{'1CH4_1'}{query_cover} - 98.5915492958), '<', 1e-9, 'query_cover is the share of the query aligned';
is_deeply [@{ $h{'6IYI_1'} }{qw(identity gaps gap_opens align_len)}], [86, 1, 1, 141], 'one gap';
like $h{'1CH4_1'}{qseq}, qr/^LSPADKTNVKAAWGKVGAHAGEYGAEALERMFLSFPTTKTYFPHF-DLS-----HGSAQ/, 'the aligned query keeps its gaps';
like $h{'1CH4_1'}{hseq}, qr/^LTPEEKSAVTALWGKV--NVDEVGGEALGRLLVVYPWTQRFFESFGDLS/, 'and so does the aligned hit';
# RCSB truncates sequence_identity to 3 places: 86/141 = 0.60993 is 0.609
foreach my $res (@{ $recorded->[0]{answer}{result_set} }) {
	my $rcsb = $res->{services}[0]{nodes}[0]{match_context}[0]{sequence_identity};
	is int(10 * $h{ $res->{identifier} }{pident}) / 1000, $rcsb, "$res->{identifier}: pident agrees with RCSB's sequence_identity";
}

is_deeply { map { $_ => $h{'1BZ1_1'}{$_} } qw(entry entity url title description method methodology resolution plddt polymer_type
	polymer_composition oligomeric_state stoichiometry symmetry chains organisms uniprot pfam ligands deposited released) },
	{ entry => '1BZ1', entity => 1, url => 'https://www.rcsb.org/structure/1BZ1', title => 'HEMOGLOBIN (ALPHA + MET) VARIANT',
		description => 'PROTEIN (HEMOGLOBIN ALPHA CHAIN)', method => 'X-ray', methodology => 'experimental', resolution => 1.59, plddt => undef,
		polymer_type => 'Protein', polymer_composition => 'heteromeric protein', oligomeric_state => 'Hetero 4-mer', stoichiometry => 'A2B2',
		symmetry => 'C2', chains => ['A', 'C'], organisms => [{ name => 'Homo sapiens', taxonomy_id => 9606 }], uniprot => ['P69905'],
		pfam => [{ id => 'PF00042', name => 'Globin (Globin)' }], ligands => [{ id => 'HEM', name => 'PROTOPORPHYRIN IX CONTAINING FE' }],
		deposited => '1998-11-05', released => '1998-11-11' },
	'an X-ray structure: its method, resolution, assembly, chains, source and ligands';
is scalar(@{ $h{'1BZ1_1'}{interpro} }), 6, 'and its six InterPro entries';
is_deeply [map { $_->{id} } @{ $h{'1Y01_2'}{ligands} }], [qw(HEM CHK OXY)], 'ligands in the order RCSB lists them';
is_deeply { map { $_ => $h{'AF_AFP69905F1_1'}{$_} } qw(entry entity url method methodology resolution plddt oligomeric_state ligands) },
	{ entry => 'AF_AFP69905F1', entity => 1, url => 'https://www.rcsb.org/structure/AF_AFP69905F1', method => undef,
		methodology => 'computational', resolution => undef, plddt => 98.06, oligomeric_state => 'Monomer', ligands => [] },
	'a computed model: no method or resolution, but its pLDDT, and an identifier with an underscore in its entry';
is $warned, '', 'no warning when every hit is in the data API';

# ---- the report

(undef, undef, undef, $out) = replay(undef, seq => $alpha);
like $out, qr/\Apdb_search: 5 of 1952 hits in RCSB's PDB for a 142-residue protein sequence, at an E-value below 0\.1\n/, 'the report says how many of how many';
like $out, qr/^id +method +resolution +identity +cover +evalue +bits +oligomer +description$/m, 'it has a header';
like $out, qr/^1BZ1_1 +X-ray +1\.59 A +100\.0% +100% +1\.6e-89 +291 +Hetero 4-mer +PROTEIN \(HEMOGLOBIN ALPHA CHAIN\)$/m, 'a line for an X-ray structure';
like $out, qr/^AF_AFP69905F1_1 +model +pLDDT 98\.06 /m, 'a computed model shows its pLDDT in place of a resolution';
like $out, qr/^1CH4_1 +X-ray +2\.50 A +61\.0% +99% +9\.7e-47 +168 +Homo 4-mer /m, 'and a gapped hit its identity and cover';
# The C runtime under Strawberry Perl 5.24.4 writes an exponent with three
# digits, and up to 2026-11-11 the report showed it: "1.6e-089" (CPAN Testers
# report 620bc624-ddea-11f1-b231-87fe50e89311). No perl here writes one, so the
# three-digit forms are given to the function that now shortens them.
is_deeply [map { Cn::Bioinf::_two_digit_exponent($_) } qw(1.6e-089 9.7e-047 1e+005 1.5E-007)], [qw(1.6e-89 9.7e-47 1e+05 1.5E-07)],
	'an exponent that a C runtime wrote with three digits is shown with two, rather than as "1.6e-089"';
is_deeply [map { Cn::Bioinf::_two_digit_exponent($_) } qw(1.6e-89 1e-100 2.5e+308 0.011 5 0)], [qw(1.6e-89 1e-100 2.5e+308 0.011 5 0)],
	'and an exponent of two digits, one that needs three, and a number with none are left as they are';
(undef, undef, undef, $out) = replay(undef, seq => $alpha, evalue => 1e-5);
like $out, qr/, at an E-value below 1e-05\n/, 'the E-value asked for is shown in the same form';
(undef, undef, undef, $out) = replay(undef, seq => $alpha);
# Without the utf8::encode in pdb_search (checked 2026-10-21 by deleting it), a
# character above 255 in RCSB's text is printed as a "Wide character", which
# kills a caller under FATAL warnings.
{
	my $wide = JSON::MaybeXS::decode_json(JSON::MaybeXS::encode_json($recorded));
	$_->{rcsb_polymer_entity}{pdbx_description} = "\x{3b1}-globin" foreach @{ $wide->[1]{answer}{data}{polymer_entities} };
	my $w;
	(undef, undef, undef, $out, $w) = replay($wide, seq => $alpha);
	like $out, qr/^1BZ1_1 .* \xce\xb1-globin$/m, 'a Greek letter from RCSB is printed as UTF-8';
	is $w, '', 'with no "Wide character" warning';
}

# ---- what RCSB may not have

{
	my $gap = JSON::MaybeXS::decode_json(JSON::MaybeXS::encode_json($recorded));
	$gap->[1]{answer}{data}{polymer_entities} = [grep { $_->{rcsb_id} ne '6IYI_1' } @{ $gap->[1]{answer}{data}{polymer_entities} }];
	my ($g, undef, undef, undef, $w) = replay($gap, seq => $alpha, report => 0);
	like $w, qr/^pdb_search: https:\/\/data\.rcsb\.org\/graphql had nothing on 6IYI_1, so its structure fields are empty/,
		'an entity the data API lacks is warned of';
	my ($six) = grep { $_->{id} eq '6IYI_1' } @{ $g };
	is_deeply [sort keys %{ $six }], \@fields, 'and is still returned with every field';
	is $six->{bit_score}, 171, 'with its alignment';
	is_deeply [@{ $six }{qw(method title resolution)}, @{ $six }{qw(chains ligands)}], [undef, undef, undef, [], []], 'and no structure';
}
{
	my ($g, $t, $a, $o) = replay([{ answer => undef }], seq => $alpha);
	is_deeply [$g, $t], [[], 0], 'no hits (RCSB answers 204) is an empty list, and a total of 0';
	is scalar(@{ $a }), 1, 'and the data API is not asked';
	like $o, qr/\Apdb_search: no hits in RCSB's PDB for a 142-residue protein sequence/, 'and the report says so';
}
{
	my $err = [$recorded->[0], { answer => { errors => [{ message => 'boom' }], data => undef } }];
	eval { replay($err, seq => $alpha, report => 0) };
	like $@, qr/^pdb_search: https:\/\/data\.rcsb\.org\/graphql said nothing of 1BZ1_1 and the rest: boom/, 'a GraphQL error dies with its message';
}
# A search answer that is JSON but not a search result used to die with perl's
# "Not a HASH reference" or "Not an ARRAY reference", naming no function, and
# one with no total_count gave an "uninitialized" warning as the report used it.
foreach my $case (
	[[1], 'a JSON array'],
	[{ total_count => 1 }, 'an object with no result_set'],
	[{ result_set => [] }, 'a result_set with no total_count'],
	[{ total_count => 1, result_set => [1] }, 'a hit that is not an object'],
) {
	my ($answer, $name) = @{ $case };
	eval { replay([{ answer => $answer }], seq => $alpha) };
	like $@, qr/^pdb_search: https:\/\/search\.rcsb\.org\/rcsbsearch\/v2\/query answered with JSON that isn't a search result: /, "$name dies";
}
# A match with an alignment_length or a query_length of 0, or none, used to
# die of "Illegal division by zero"; its pident or query_cover is undef, and
# the report shows "-".
{
	my $zero = JSON::MaybeXS::decode_json(JSON::MaybeXS::encode_json($recorded));
	my $m = $zero->[0]{answer}{result_set}[0]{services}[0]{nodes}[0]{match_context}[0];
	@{ $m }{qw(alignment_length query_length)} = (0, undef);
	my ($g, undef, undef, $o, $w) = replay($zero, seq => $alpha);
	is_deeply [@{ $g->[0] }{qw(id pident query_cover bit_score)}], ['1BZ1_1', undef, undef, 291],
		'an alignment_length of 0 and no query_length leave pident and query_cover undef, and the rest of the hit';
	like $o, qr/^1BZ1_1 +X-ray +1\.59 A +- +- +1\.6e-89 +291 /m, 'and the report shows them as "-"';
	is $w, '', 'with no warning';
}

# ---- _rcsb_post, with HTTP::Tiny standing in for the network

{
	require HTTP::Tiny;
	no warnings qw(redefine once); # 'once', since HTTP::Tiny is loaded only at run time
	my ($res, $ssl);
	local *HTTP::Tiny::can_ssl = sub { @{ $ssl } };
	local *HTTP::Tiny::post = sub { $res };
	my $post = sub { Cn::Bioinf::_rcsb_post('pdb_search', 'https://x.test/q', { a => 1 }, 5) };
	$ssl = [1, ''];
	$res = { status => 200, success => 1, reason => 'OK', content => '{"a":[1]}' };
	is_deeply $post->(), { a => [1] }, '_rcsb_post: 200 is the JSON decoded';
	$res = { status => 204, success => 1, reason => 'No Content', content => '' };
	is $post->(), undef, '_rcsb_post: 204 is undef';
	$res = { status => 400, success => '', reason => 'Bad Request', content => qq({"status":400,"message":"Invalid sequence [ X ]"}\n) };
	eval { $post->() };
	like $@, qr/^pdb_search: https:\/\/x\.test\/q answered 400: Invalid sequence \[ X \] at /, '_rcsb_post: an error gives RCSB\'s message';
	$res = { status => 503, success => '', reason => 'Service Unavailable', content => '<html>down</html>' };
	eval { $post->() };
	like $@, qr/^pdb_search: https:\/\/x\.test\/q answered 503: Service Unavailable at /, '_rcsb_post: or the reason, when it sent no JSON';
	$res = { status => 599, success => '', reason => 'Internal Exception', content => "Could not connect to 'x.test:443': Name or service not known\n" };
	eval { $post->() };
	like $@, qr/^pdb_search: https:\/\/x\.test\/q answered 599: Could not connect to 'x\.test:443': Name or service not known at /,
		'_rcsb_post: no answer at all says why';
	$res = { status => 200, success => 1, reason => 'OK', content => '<html>' };
	eval { $post->() };
	like $@, qr/^pdb_search: https:\/\/x\.test\/q answered with something that isn't JSON: <html>/, '_rcsb_post: a 200 that is not JSON dies';
	$ssl = [0, "IO::Socket::SSL 1.968 or later must be installed for https support\n"];
	eval { $post->() };
	like $@, qr/^pdb_search: can't reach RCSB, which needs HTTPS: IO::Socket::SSL 1\.968 or later must be installed for https support at /,
		'_rcsb_post: without SSL it says what is missing';
}

# ---- the real RCSB

SKIP: {
	skip 'set NETWORK_TESTING to search the real RCSB', 3 unless $ENV{NETWORK_TESTING};
	my ($live, $n) = pdb_search(seq => $alpha, max_hits => 3, report => 0);
	cmp_ok $n, '>=', 1382, 'RCSB finds at least the 1382 hits it found on 2026-10-21';
	is $live->[0]{pident}, 100, 'the best of them is identical';
	is_deeply [sort keys %{ $live->[0] }], \@fields, 'with every field';
}

done_testing;
