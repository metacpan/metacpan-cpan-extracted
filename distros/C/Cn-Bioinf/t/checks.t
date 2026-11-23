require 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catdir catfile rel2abs);
use Cwd ();
use FindBin;
use IO::Compress::Gzip ();
use Cn::Bioinf qw(:all);
# Checks that need none of Alien::Bioinf's programs, so that they run wherever
# the module builds: each one dies, or is decided, before clustalo, blastp or
# Python would be started. Every case is a bug that was found by review on
# 2026-10-01 and fixed then.

my $dir = tempdir(CLEANUP => 1);
sub spew {
	my ($name, $content) = @_;
	my $f = catfile($dir, $name);
	open my $fh, '>:raw', $f or die $!;
	print {$fh} $content;
	close $fh;
	$f;
}
sub dies_like {
	my ($code, $re, $name) = @_;
	eval { $code->(); 1 } and return fail($name);
	like $@, $re, $name;
}
sub slurp { open my $fh, '<', $_[0] or die "$_[0]: $!"; local $/; <$fh> }
my @inc = map { "-I$_" } grep { !ref } @INC;

#  loading

is system($^X, @inc, '-e', 'BEGIN { $0 = q{/no/such/script.pl} } require Cn::Bioinf'), 0,
	'the module loads when $0 is not a file, which FindBin would croak on';
# Up to 2026-11-16 a bare "use Cn::Bioinf" imported every function, although
# the documentation said nothing was exported by default. The child prints 1
# for each import that happened; "loaded" shows that it ran at all.
{
	my $out = catfile($dir, 'exports.txt');
	system($^X, @inc, '-e', 'package Bare; use Cn::Bioinf; package Named; use Cn::Bioinf q{gc_content}; package All; use Cn::Bioinf q{:all};'
		. ' package main; open my $fh, q{>}, $ARGV[0] or die $!;'
		. ' print {$fh} join q{,}, q{loaded}, map { defined &$_ ? 1 : 0 } qw(Bare::gc_content Bare::fasta2hash Named::gc_content Named::fasta2hash All::gc_content All::view_alignment)',
		$out);
	is slurp($out), 'loaded,0,0,1,0,1,1',
		'a bare "use Cn::Bioinf" imports nothing, rather than every function; a name imports that one, and ":all" every one';
}
# Alien::Bioinf hidden from require, as on a machine that could not install it
my $hide = 'BEGIN { unshift @INC, sub { die qq{hidden\n} if $_[1] eq q{Alien/Bioinf.pm}; return } }';
my $err = catfile($dir, 'err.txt');
# $err is passed in @ARGV, not pasted into the code, which a Windows path's
# backslashes or a '}' in it would break
system($^X, @inc, '-e', "$hide use Cn::Bioinf q{plot_msa}; open STDERR, q{>}, \$ARGV[0]; plot_msa(fasta => { a => q{MK}, b => q{MV} }, filename => q{x.png})", $err);
like slurp($err), qr/^_alien: plot_msa needs Alien::Bioinf, for Clustal Omega, BLAST\+ and the plotting Python, and it can't be loaded: hidden/,
	'without Alien::Bioinf a plotting function says what it needs';

# Up to 2026-10-17 _creator joined the working directory to the script's file
# name, so a script run from elsewhere was recorded at a path that isn't it.
# Alien::Bioinf is stood in for by a stub, since _creator only reads its
# version; it is put in %INC rather than found through @INC, which an @INC hook
# in PERL5OPT could hide it from.
{
	my $scripts = catdir($dir, 'scripts');
	mkdir $scripts or die "$scripts: $!";
	my $script = catfile($scripts, 'creator.pl');
	open my $fh, '>', $script or die $!;
	print {$fh} 'BEGIN { $Alien::Bioinf::VERSION = q{9.99}; $INC{q{Alien/Bioinf.pm}} = __FILE__ } use Cn::Bioinf;'
		. ' open STDOUT, q{>}, $ARGV[0] or die $!; print Cn::Bioinf::_creator(q{x});';
	close $fh;
	my $out = catfile($dir, 'creator.txt');
	my $was = Cwd::getcwd();
	chdir $dir or die "$dir: $!";
	# absolute, since the relative entries prove -b gives would not survive the chdir
	system($^X, (map { '-I' . rel2abs(substr $_, 2) } @inc), $script, $out);
	chdir $was or die "$was: $!";
	my $real = catfile(Cwd::realpath($scripts), 'creator.pl');
	like slurp($out), qr/^\Q$real\E called using "x" in .+ with Alien::Bioinf 9\.99 by user /,
		"the Creator names the script's own path, not the working directory's";
}

#  _cmd_text

# Up to 2026-11-16 _cmd_text put an argument holding an apostrophe between
# apostrophes as it was, so the command it wrote into an image's Creator could
# not be pasted into a shell, and wrote an empty argument as nothing at all.
is Cn::Bioinf::_cmd_text('clustalo', '-i', "O'Brien.fa", '--outfmt=fa', ''), q{clustalo -i 'O'\''Brien.fa' --outfmt=fa ''},
	"_cmd_text escapes an apostrophe and quotes an empty argument, rather than writing 'O'Brien.fa' and dropping it";

#  _run

# Up to 2026-10-07 _run read only the exit code, the high byte of $?, so a
# program killed by a signal was reported as "exit 0".
dies_like sub { Cn::Bioinf::_run($^X, '-e', 'exit 3') }, qr/^_run: .+ failed: exit 3 at /, 'a non-zero exit is reported';
SKIP: {
	skip 'MSWin32 has no POSIX signals', 1 if $^O eq 'MSWin32';
	# set to DEFAULT in the child, which may have inherited TERM ignored
	dies_like sub { Cn::Bioinf::_run($^X, '-e', '$SIG{TERM} = q{DEFAULT}; kill q{TERM}, $$; sleep 5') },
		qr/^_run: .+ failed: killed by signal 15/, 'a death by signal is reported as one, not as "exit 0"';
}

#  _plink2

# A plink2 that never starts is reported with the reason system gave. Up to
# 2026-11-02 $! was read after STDOUT and STDERR had been reopened, and the
# reason given was theirs ("Inappropriate ioctl for device"). The reason
# expected is the one perl gives for the same failed system, which is how this
# perl words it.
SKIP: {
	my $nowhere = catfile($dir, 'no such dir', 'plink2');
	my $want = do { no warnings 'exec'; system($nowhere) == -1 ? "$!" : undef };
	skip "this perl's system does not return -1 for a program that is not there", 1 unless defined $want;
	dies_like sub { Cn::Bioinf::_plink2('pgs_score', $nowhere, $dir, '--version') },
		qr/^pgs_score: .+ failed \(it didn't start: \Q$want\E\)/, '_plink2: a plink2 that does not start is reported with the reason it did not';
}

#  undef file names

# Up to 2026-10-07 the message interpolated the undef, which warned
# "uninitialized value" -- fatally, under a caller's FATAL warnings, which then
# hid the message itself.
foreach my $case (
	[fasta2hash             => sub { fasta2hash(undef) },             qr/^_open_fasta: undef isn't a readable file/],
	[get_best_alignment_hit => sub { get_best_alignment_hit(undef) }, qr/^get_best_alignment_hit: undef isn't a readable file/],
) {
	my ($name, $code, $re) = @{ $case };
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	dies_like $code, $re, "$name(undef) dies naming the undef";
	is "@w", '', 'and with no warning';
}

#  hash2fasta_file 

# Up to 2026-10-07 the width went straight to the XS as a UV: -1 wrapped round
# to one line per sequence, and 'x' warned with no function name.
foreach my $w (-1, 1.5, 'x') {
	dies_like sub { hash2fasta_file({ a => 'MK' }, catfile($dir, 'w.fa'), undef, $w) },
		qr/^hash2fasta_file: 4th argument must be a whole number, 0 or more, or undef, not "\Q$w\E"/, "width $w dies";
}

#  get_best_alignment_hit 

my $report = '{"report":{"results":{"search":{"query_title":"q","hits":[]}}}}';
dies_like sub { get_best_alignment_hit(spew('twice.json', qq({"BlastOutput2":[$report,$report]}))) },
	qr/^get_best_alignment_hit: two queries in .+twice\.json are both titled "q"/, 'two queries of one title die rather than one being lost';
# A file that is not BLAST's JSON used to die with JSON::MaybeXS's message or
# perl's "Not a HASH reference", naming no function, or, for {}, return no
# queries as though BLAST had found none.
foreach my $case (
	['', qr/^get_best_alignment_hit: .+empty\.json isn't JSON: /, 'an empty file'],
	['{not json', qr/^get_best_alignment_hit: .+bad\.json isn't JSON: /, 'a file that is not JSON'],
	['[1]', qr/^get_best_alignment_hit: .+array\.json isn't a BLAST report in JSON \(-outfmt 15\): it has no "BlastOutput2" array/, 'a JSON array'],
	['{}', qr/^get_best_alignment_hit: .+object\.json isn't a BLAST report in JSON \(-outfmt 15\): it has no "BlastOutput2" array/, 'a JSON object of no report'],
	['{"BlastOutput2":[1]}', qr/^get_best_alignment_hit: report 1 of .+nosearch\.json has no report\.results\.search/, 'a report with no search'],
	['{"BlastOutput2":[{"report":{"results":{"search":{"hits":[]}}}}]}', qr/^get_best_alignment_hit: report 1 of .+noquery\.json names no query: it has no query_title or query_id/,
		'a report with no query'],
) {
	my ($json, $re, $name) = @{ $case };
	my ($file) = $re =~ /\.\+(\w+)\\\.json/;
	dies_like sub { get_best_alignment_hit(spew("$file.json", $json)) }, $re, "get_best_alignment_hit: $name dies";
}
# A query with no title is named by its query_id, where it used to be named
# "" with an "uninitialized" warning.
is_deeply [keys %{ get_best_alignment_hit(spew('untitled.json', '{"BlastOutput2":[{"report":{"results":{"search":{"query_id":"Query_1","hits":[]}}}}]}')) }],
	['Query_1'], 'get_best_alignment_hit: a query with no title is named by its query_id';

#  pgs_score 

# Added with pgs_score on 2026-10-17; t/pgs.t has the scores themselves. Every
# case that dies does so before PLINK 2 starts; the ones that score need it.
{
	my $v = { 'chr1:5:A:G' => { CHROM => 'chr1', POS => 5, ID => 'rs1', REF => 'A', ALT => 'G', 'S.GT' => '0/1' } };
	my $wrow = { rsID => 'rs1', chr_name => '1', chr_position => 5, effect_allele => 'G', other_allele => 'A', effect_weight => '0.5' };
	my $w = [$wrow];
	my $plink2 = eval { require Alien::Bioinf; -x Alien::Bioinf->plink2 };
	SKIP: {
		skip 'PLINK 2, which Alien::Bioinf installs, is not installed', 1 unless $plink2;
		is pgs_score(vcf => $v, weights => $w)->{S}{score}, 0.5, 'pgs_score: the arguments below differ from these only where they say';
	}
	my $head = "rsID\tchr_name\tchr_position\teffect_allele\teffect_weight\n";
	my @cases = (
		[[vcf => $v], qr/^pgs_score: needs "weights"/, 'no weights'],
		[[{ vcf => $v, weights => $w }], qr/^pgs_score: takes name => value pairs, not a hash ref/, 'a hash ref'],
		[[vcf => $v, weights => $w, matches => 'id'], qr/^pgs_score: doesn't know "matches"; it takes build, match, memory, threads, vcf, weights/, 'a misspelled option'],
		[[vcf => $v, weights => $w, match => 'rsid'], qr/^pgs_score: "match" must be "position" or "id", not "rsid"/, 'match "rsid"'],
		[[vcf => $v, weights => $w, build => 'GRCh37'], qr/^pgs_score: "build" must be hg19, b37, hg38 or b38, not "GRCh37"/, 'build "GRCh37"'],
		[[vcf => $v, weights => $w, memory => 639], qr/^pgs_score: "memory" must be 640 or more \(MiB\), the least PLINK 2 takes, not 639/, 'memory 639'],
		[[vcf => $v, weights => $w, memory => '2G'], qr/^pgs_score: "memory" must be a whole number, 1 or more, not "2G"/, 'memory "2G"'],
		[[vcf => $v, weights => $w, threads => 0], qr/^pgs_score: "threads" must be a whole number, 1 or more, not "0"/, 'threads 0'],
		[[vcf => \'calls', weights => $w], qr/^pgs_score: "vcf" must be a VCF, BCF or PLINK 2 \.pgen file, or a data frame, not a SCALAR ref/, 'a scalar ref'],
		[[vcf => catfile($dir, 'none.vcf.gz'), weights => $w], qr/^pgs_score: "vcf" file ".+none\.vcf\.gz" doesn't exist or isn't readable/, 'a VCF that is not there'],
		[[vcf => spew('calls.txt', ''), weights => $w], qr/^pgs_score: "vcf" file .+calls\.txt must end in \.vcf, \.vcf\.gz, \.vcf\.bgz, \.bcf or \.pgen/, 'a VCF named .txt'],
		[[vcf => spew('lone.pgen', ''), weights => $w], qr/^pgs_score: "vcf" .+lone\.pgen has no .+lone\.pvar \(or \.pvar\.zst\) beside it/, 'a .pgen with no .pvar'],
		[[vcf => $v, weights => catfile($dir, 'none.txt.gz')], qr/^pgs_score: "weights" file ".+none\.txt\.gz" doesn't exist or isn't readable/, 'a scoring file that is not there'],
		[[vcf => $v, weights => spew('comments.txt', "#pgs_id=X\n#genome_build=NR\n")], qr/^pgs_score: "weights" file .+comments\.txt has no header line/, 'a scoring file of comments alone'],
		[[vcf => $v, weights => spew('header.txt', $head)], qr/^pgs_score: "weights" has no rows/, 'a scoring file of a header alone'],
		[[vcf => $v, weights => spew('bad.txt', $head . "rs1\t1\t5\tG\t0.5\nrs2\t1\t6\tG\tx\n")], qr/^pgs_score: row 2 of "weights" has effect_weight "x", which isn't a number/, 'a bad weight in a scoring file'],
		[[vcf => $v, weights => [{ %{ $wrow }, chr_name => 'X' }]], qr/^pgs_score: "weights" has variants on X, which PLINK 2 reads only when "build" says where X's pseudo-autosomal regions are: hg19 \(b37\) or hg38 \(b38\)/, 'a variant on X without build'],
		[[vcf => $v, weights => []], qr/^pgs_score: "weights" has no rows/, 'an empty array'],
		[[vcf => {}, weights => $w], qr/^pgs_score: "vcf" has no rows/, 'an empty hash'],
		[[vcf => $v, weights => [['effect_allele']]], qr/^pgs_score: "weights" has a header and no rows/, 'an array of arrays of only a header'],
		[[vcf => $v, weights => [$wrow, undef]], qr/^pgs_score: row 2 of "weights" must be a hash ref, not undef/, 'an undef row'],
		[[vcf => $v, weights => [[qw(a b)], 'x']], qr/^pgs_score: row 1 of "weights" must be an array ref, as its header is, not "x"/, 'a string row of an aoa'],
		# the shape is taken from whichever column perl's hash order gives first
		[[vcf => $v, weights => { a => [1], b => 2 }],
			qr/^pgs_score: (?:column "b" of "weights" must be an array ref, as "a" is, not "2"|"weights" must be .+, not a hash whose "b" is "2")/,
			'a string column of a hoa'],
		[[vcf => $v, weights => [1]], qr/^pgs_score: "weights" must be .+, not an array whose first row is "1"/, 'an array of strings'],
		[[vcf => { a => 1 }, weights => $w], qr/^pgs_score: "vcf" must be .+, not a hash whose "a" is "1"/, 'a hash of strings'],
		[[vcf => $v, weights => [{ map { $_ => $wrow->{$_} } qw(rsID effect_allele effect_weight) }]],
			qr/^pgs_score: "weights" has no "chr_name", "chr_position" columns, which a PGS Catalog scoring file has/, 'no positions'],
		[[vcf => $v, weights => [{ map { $_ => $wrow->{$_} } qw(chr_name chr_position effect_allele effect_weight) }], match => 'id'],
			qr/^pgs_score: "weights" has no "rsID" column/, 'no rsID to match by ID'],
		[[vcf => $v, weights => [{ %{ $wrow }, effect_weight => 'NaN' }]], qr/^pgs_score: row 1 of "weights" has effect_weight "NaN", which isn't a number/, 'a NaN weight'],
		[[vcf => $v, weights => [$wrow, { %{ $wrow }, effect_weight => undef }]], qr/^pgs_score: row 2 of "weights" has effect_weight undef, which isn't a number/, 'an undef weight'],
		[[vcf => $v, weights => { k => { %{ $wrow }, effect_weight => '0,5' } }], qr/^pgs_score: row "k" of "weights" has effect_weight "0,5", which isn't a number/, 'a decimal comma, in a hoh'],
		[[vcf => $v, weights => [{ %{ $wrow }, effect_allele => '' }]], qr/^pgs_score: row 1 of "weights" has no effect_allele/, 'an empty effect allele'],
		[[vcf => $v, weights => [{ %{ $wrow }, chr_position => '1e5' }]], qr/^pgs_score: row 1 of "weights" has chr_position "1e5", which isn't a position/, 'a position in exponent form'],
		[[vcf => $v, weights => [{ %{ $wrow }, hm_chr => '1', hm_pos => 0 }]], qr/^pgs_score: row 1 of "weights" has hm_pos "0", which isn't a position/, 'position 0, in hm_pos'],
		[[vcf => $v, weights => [{ %{ $wrow }, is_dominant => 'True' }]], qr/^pgs_score: row 1 of "weights" has is_dominant "True", and only additive weights can be scored/, 'a dominant weight'],
		[[vcf => $v, weights => [{ %{ $wrow }, is_haplotype => 'TRUE' }]], qr/^pgs_score: row 1 of "weights" has is_haplotype "TRUE", and only/, 'a haplotype'],
		[[vcf => $v, weights => [{ %{ $wrow }, dosage_1_weight => '0.2' }]], qr/^pgs_score: row 1 of "weights" has a dosage_1_weight, and only additive weights can be scored/, 'a dosage weight'],
		[[vcf => { k => { CHROM => 'chr1', POS => 5, REF => 'A', ALT => 'G', FORMAT => 'GT', S => '0/1' } }, weights => $w],
			qr/^pgs_score: "vcf" has no <sample>\.GT column; read the VCF with read_table's default of explode => 1/, 'a VCF read with explode => 0'],
		[[vcf => { k => { CHROM => 'chr1', POS => 5, ALT => 'G', 'S.GT' => '0/1' } }, weights => $w], qr/^pgs_score: "vcf" has no "REF" column/, 'no REF'],
		[[vcf => { k => { CHROM => 'chr1', POS => 5, REF => 'A', ALT => 'G', 'S.GT' => '0/1' } }, weights => $w, match => 'id'], qr/^pgs_score: "vcf" has no "ID" column/, 'no ID to match by ID'],
	);
	foreach my $c (@cases) {
		my ($args, $re, $name) = @{ $c };
		dies_like sub { pgs_score(@{ $args }) }, $re, "pgs_score: $name dies";
	}
	SKIP: {
		skip 'PLINK 2, which Alien::Bioinf installs, is not installed', 3 unless $plink2;
		is pgs_score(vcf => $v, weights => $w, match => 'id')->{S}{score}, 0.5, 'pgs_score: rs1 is found by ID';
		is pgs_score(vcf => $v, weights => [{ %{ $wrow }, chr_name => undef, chr_position => undef }], match => 'id')->{S}{score}, 0.5,
			'pgs_score: matching by ID needs no position';
		is pgs_score(vcf => $v, weights => [{ %{ $wrow }, rsID => undef }])->{S}{score}, 0.5, 'pgs_score: matching by position needs no rsID';
	}
}

#  pca, fst, hardy_weinberg, ld, ld_prune and gwas

# Added with them on 2026-11-17; t/popgen.t has their results. Every case here
# dies before PLINK 2 is looked for, so they run where Alien::Bioinf is not
# installed.
{
	my $v = { 'chr1:5:A:G' => { CHROM => 'chr1', POS => 5, REF => 'A', ALT => 'G', 'S.GT' => '0/1', 'T.GT' => '1/1' } };
	my @p = ({ IID => 'S', y => '1.5', age => 30, site => 'north' }, { IID => 'T', y => '2.5', age => 40, site => 'south' });
	my $head = "#IID\ty\tage\n";
	my @cases = (
		[pca => [], qr/^pca: needs "vcf"/, 'no vcf'],
		[pca => [vcf => $v, pcs => 3], qr/^pca: doesn't know "pcs"; it takes memory, n, threads, vcf/, 'a misspelled option'],
		[pca => [vcf => $v, n => 0], qr/^pca: "n" must be a whole number, 1 or more, not "0"/, 'n 0'],
		[pca => [vcf => $v, n => '2.5'], qr/^pca: "n" must be a whole number, 1 or more, not "2\.5"/, 'n 2.5'],
		[pca => [vcf => $v, threads => 0], qr/^pca: "threads" must be a whole number, 1 or more, not "0"/, 'threads 0'],
		[pca => [vcf => $v, memory => 639], qr/^pca: "memory" must be 640 or more \(MiB\), the least PLINK 2 takes, not 639/, 'memory 639'],
		[pca => [vcf => \'calls'], qr/^pca: "vcf" must be a VCF, BCF or PLINK 2 \.pgen file, or a data frame, not a SCALAR ref/, 'a scalar ref'],
		[pca => [vcf => catfile($dir, 'none.vcf')], qr/^pca: "vcf" file ".+none\.vcf" doesn't exist or isn't readable/, 'a VCF that is not there'],
		[pca => [vcf => spew('calls.tsv', '')], qr/^pca: "vcf" file .+calls\.tsv must end in \.vcf, \.vcf\.gz, \.vcf\.bgz, \.bcf or \.pgen/, 'a VCF named .tsv'],
		[fst => [vcf => $v], qr/^fst: needs "populations"/, 'no populations'],
		[fst => [vcf => $v, populations => { S => 'A', T => 'B' }, method => 'nei'], qr/^fst: "method" must be "hudson" or "wc", not "nei"/, 'method "nei"'],
		[fst => [vcf => $v, populations => { S => 'A', T => 'B' }, per_variant => 2], qr/^fst: "per_variant" must be 0 or 1, not "2"/, 'per_variant 2'],
		[fst => [vcf => $v, populations => [S => 'A']], qr/^fst: "populations" must be a hash ref of sample => population, not an ARRAY ref/, 'populations as an array'],
		[fst => [vcf => $v, populations => {}], qr/^fst: "populations" names no population, and Fst is between two or more/, 'no populations named'],
		[fst => [vcf => $v, populations => { S => 'A', T => 'A' }], qr/^fst: "populations" names one population, and Fst is between two or more/, 'one population'],
		[fst => [vcf => $v, populations => { S => 'A', T => undef }], qr/^fst: "populations" gives "T" the population undef, where a population is a name/, 'an undef population'],
		[fst => [vcf => $v, populations => { S => 'A', T => '' }], qr/^fst: "populations" gives "T" the population "", where a population is a name/, 'an empty population'],
		[hardy_weinberg => [vcf => $v, midp => 'yes'], qr/^hardy_weinberg: "midp" must be 0 or 1, not "yes"/, 'midp "yes"'],
		[ld => [vcf => $v, window_kb => 0], qr/^ld: "window_kb" must be a number above 0, not "0"/, 'window_kb 0'],
		[ld => [vcf => $v, window => 0], qr/^ld: "window" must be a whole number, 1 or more, not "0"/, 'window 0'],
		[ld => [vcf => $v, min_r2 => 1.5], qr/^ld: "min_r2" must be a number from 0 to 1, not "1\.5"/, 'min_r2 1.5'],
		[ld => [vcf => $v, phased => 2], qr/^ld: "phased" must be 0 or 1, not "2"/, 'phased 2'],
		[ld_prune => [vcf => $v, window => 50, window_kb => 200], qr/^ld_prune: the window is given either in variants, as "window", or in kb, as "window_kb", not both/,
			'window and window_kb'],
		[ld_prune => [vcf => $v, window => 1], qr/^ld_prune: "window" must be a whole number, 2 or more, not "1"/, 'window 1'],
		[ld_prune => [vcf => $v, window_kb => '200kb'], qr/^ld_prune: "window_kb" must be a whole number, 1 or more, not "200kb"/, 'window_kb "200kb"'],
		[ld_prune => [vcf => $v, step => 0], qr/^ld_prune: "step" must be a whole number, 1 or more, not "0"/, 'step 0'],
		[ld_prune => [vcf => $v, window_kb => 200, step => 5], qr/^ld_prune: "step" must be 1 with "window_kb", as PLINK 2 has it, not 5/, 'step 5 with window_kb'],
		[ld_prune => [vcf => $v, r2 => 1], qr/^ld_prune: "r2" must be a number above 0 and below 1, not "1"/, 'r2 1'],
		[ld_prune => [vcf => $v, r2 => 0], qr/^ld_prune: "r2" must be a number above 0 and below 1, not "0"/, 'r2 0'],
		[gwas => [vcf => $v, phenotypes => \@p], qr/^gwas: needs "phenotype"/, 'no phenotype'],
		[gwas => [vcf => $v, phenotypes => \@p, phenotype => ['y']], qr/^gwas: "phenotype" must be the name of a column of "phenotypes", not an ARRAY ref/, 'a phenotype that is an array'],
		[gwas => [vcf => $v, phenotypes => \@p, phenotype => 'y', covariates => 'age'],
			qr/^gwas: "covariates" must be an array ref of names of columns of "phenotypes", not "age"/, 'covariates as a string'],
		[gwas => [vcf => $v, phenotypes => \@p, phenotype => 'y', covariates => [undef]], qr/^gwas: "covariates" must name columns of "phenotypes", and one is undef/, 'an undef covariate'],
		[gwas => [vcf => $v, phenotypes => \@p, phenotype => 'y', covariates => ['y']], qr/^gwas: "covariates" names "y", which is already the phenotype/, 'the phenotype as a covariate'],
		[gwas => [vcf => $v, phenotypes => \@p, phenotype => 'y', covariates => [qw(age age)]], qr/^gwas: "covariates" names "age", which is already a covariate/, 'a covariate twice'],
		[gwas => [vcf => $v, phenotypes => \@p, phenotype => 'y', model => 'probit'], qr/^gwas: "model" must be "linear" or "logistic", not "probit"/, 'model "probit"'],
		[gwas => [vcf => $v, phenotypes => \@p, phenotype => 'y', threads => 'all'], qr/^gwas: "threads" must be a whole number, 1 or more, not "all"/, 'threads "all"'],
		[gwas => [vcf => $v, phenotypes => catfile($dir, 'none.tsv'), phenotype => 'y'], qr/^gwas: "phenotypes" file ".+none\.tsv" doesn't exist or isn't readable/,
			'a phenotype file that is not there'],
		[gwas => [vcf => $v, phenotypes => spew('head.tsv', $head), phenotype => 'y'], qr/^gwas: "phenotypes" file .+head\.tsv has no rows/, 'a phenotype file of a header alone'],
		[gwas => [vcf => $v, phenotypes => spew('short.tsv', "$head" . "S\t1\n"), phenotype => 'y'],
			qr/^gwas: line 2 of "phenotypes" file .+short\.tsv has 2 fields, and its header 3/, 'a short line'],
		[gwas => [vcf => $v, phenotypes => [{ sample => 'S', y => 1 }], phenotype => 'y'], qr/^gwas: "phenotypes" has no "IID" column, which names each row's sample/, 'no IID'],
		[gwas => [vcf => $v, phenotypes => \@p, phenotype => 'height', covariates => ['weight']], qr/^gwas: "phenotypes" has no "height", "weight" columns/, 'columns it lacks'],
		[gwas => [vcf => $v, phenotypes => [@p, $p[0]], phenotype => 'y'], qr/^gwas: "phenotypes" has two rows for "S"/, 'a sample twice'],
		[gwas => [vcf => $v, phenotypes => [@p, { %{ $p[0] }, IID => '' }], phenotype => 'y'], qr/^gwas: "phenotypes" has a row whose IID is ""/, 'an empty IID'],
		[gwas => [vcf => $v, phenotypes => \@p, phenotype => 'site'], qr/^gwas: phenotype "site" has "north" for "S", which isn't a number/, 'a phenotype of words'],
		[gwas => [vcf => $v, phenotypes => [@p, { IID => 'U', y => [] }], phenotype => 'y'], qr/^gwas: column "y" of "phenotypes" has an ARRAY ref for "U"/, 'a reference as a value'],
		[gwas => [vcf => $v, phenotypes => [{ IID => 'S', y => 1 }, { IID => 'T', y => 'NA' }], phenotype => 'y'],
			qr/^gwas: phenotype "y" has only the value 1, and a test needs two or more/, 'a phenotype of one value'],
		[gwas => [vcf => $v, phenotypes => [{ IID => 'S', y => '' }], phenotype => 'y'], qr/^gwas: phenotype "y" has no values, and a test needs two or more/, 'a phenotype of no values'],
		[gwas => [vcf => $v, phenotypes => [map { { IID => $_, y => ord($_) - 82 } } qw(S T U)], phenotype => 'y', model => 'logistic'],
			qr/^gwas: "model" is logistic, and phenotype "y" has the values 1, 2, 3, where a case-control phenotype has two: 1 and 2, or 0 and 1/,
			'a logistic model of three values'],
		[gwas => [vcf => $v, phenotypes => [map { { %{ $_ }, site => "$_->{site} side" } } @p], phenotype => 'y', covariates => ['site']],
			qr/^gwas: column "site" of "phenotypes" has "north side" for "S", and a covariate's values have no whitespace/, 'a covariate with a space'],
	);
	foreach my $c (@cases) {
		my ($sub, $args, $re, $name) = @{ $c };
		no strict 'refs';
		dies_like sub { &{"Cn::Bioinf::$sub"}(@{ $args }) }, $re, "$sub: $name dies";
	}
}


#  admixture

# Added with it on 2026-11-17; t/admixture.t has its fit.
{
	my $v = spew('admix.vcf', "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tA\tB\tC\n"
		. "1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\t1/1\t0/0\n1\t9\t.\tC\tT\t.\t.\t.\tGT\t0/0\t0/1\t1/1\n");
	is scalar keys %{ admixture(vcf => $v, k => 2, starts => 1)->{samples} }, 3, 'admixture: the arguments below differ from these only where they say';
	my @cases = (
		[[k => 2], qr/^admixture: needs "vcf"/, 'no vcf'],
		[[vcf => $v], qr/^admixture: needs "k"/, 'no k'],
		[[vcf => $v, k => 2, K => 3], qr/^admixture: doesn't know "K"; it takes k, max_iterations, min_depth, seed, starts, tolerance, vcf/, 'a misspelled option'],
		[[vcf => $v, k => 1], qr/^admixture: "k" must be a whole number, 2 or more, not "1"/, 'k 1'],
		[[vcf => $v, k => '2.5'], qr/^admixture: "k" must be a whole number, 2 or more, not "2\.5"/, 'k 2.5'],
		[[vcf => $v, k => 3], qr/^admixture: "vcf" .+admix\.vcf has 3 samples, and "k" is 3; a sample's ancestry is a share of the k populations, which needs more samples than k/,
			'k as many as the samples'],
		[[vcf => $v, k => 2, starts => 0], qr/^admixture: "starts" must be a whole number, 1 or more, not "0"/, 'starts 0'],
		[[vcf => $v, k => 2, seed => -1], qr/^admixture: "seed" must be a whole number, 0 or more, not "-1"/, 'seed -1'],
		[[vcf => $v, k => 2, tolerance => 0], qr/^admixture: "tolerance" must be a number above 0, not "0"/, 'tolerance 0'],
		[[vcf => $v, k => 2, max_iterations => 0], qr/^admixture: "max_iterations" must be a whole number, 1 or more, not "0"/, 'max_iterations 0'],
		[[vcf => $v, k => 2, min_depth => 'deep'], qr/^admixture: "min_depth" must be a whole number, 0 or more, not "deep"/, 'min_depth "deep"'],
		[[vcf => [], k => 2], qr/^admixture: "vcf" must be a file name, not an ARRAY ref/, 'a vcf that is an array'],
		[[vcf => catfile($dir, 'none.vcf'), k => 2], qr/^admixture: "vcf" file ".+none\.vcf" doesn't exist or isn't readable/, 'a VCF that is not there'],
		[[vcf => spew('admix.txt', ''), k => 2], qr/^admixture: "vcf" file .+admix\.txt must end in \.vcf, \.vcf\.gz, \.vcf\.bgz or \.vcf\.bz2/, 'a VCF named .txt'],
	);
	foreach my $c (@cases) {
		my ($args, $re, $name) = @{ $c };
		dies_like sub { admixture(@{ $args }) }, $re, "admixture: $name dies";
	}
}

#  sex_check

# Added with sex_check on 2026-10-18; t/sex.t has the counts themselves, and the
# errors that come from reading the file.
{
	my $v = spew('sex.vcf', "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS\nchrX\t3000000\t.\tA\tG\t.\t.\t.\tGT\t0/1\n");
	is sex_check(vcf => $v, report => 0)->{S}{sex}, 'female', 'sex_check: the arguments below differ from these only where they say';
	is_deeply sex_check($v, report => 0), sex_check(vcf => $v, report => 0), 'sex_check: the file may come first, unnamed, before the options';
	{
		open my $save, '>&', \*STDOUT or die $!;
		open STDOUT, '>', File::Spec->devnull or die $!;
		my $r = eval { sex_check($v) };
		open STDOUT, '>&', $save or die $!;
		is_deeply $r, { S => sex_check(vcf => $v, report => 0)->{S} }, 'sex_check: or alone, as sex_check($file), rather than dying on an odd number of arguments';
	}
	my @cases = (
		[[], qr/^sex_check: needs "vcf"/, 'no vcf'],
		[[{ vcf => $v }], qr/^sex_check: takes name => value pairs, not a hash ref/, 'a hash ref'],
		[[vcf => $v, depth => 7], qr/^sex_check: doesn't know "depth"; it takes cutoff, min_depth, report, vcf/, 'a misspelled option'],
		[[vcf => $v, cutoff => 0], qr/^sex_check: "cutoff" must be a number above 0, not "0"/, 'cutoff 0'],
		[[vcf => $v, cutoff => 'NaN'], qr/^sex_check: "cutoff" must be a number above 0, not "NaN"/, 'cutoff NaN'],
		[[vcf => $v, cutoff => [0.6]], qr/^sex_check: "cutoff" must be a number above 0, not an ARRAY ref/, 'cutoff an array ref'],
		[[vcf => $v, min_depth => -1], qr/^sex_check: "min_depth" must be a whole number, 0 or more, not "-1"/, 'min_depth -1'],
		[[vcf => $v, min_depth => 7.5], qr/^sex_check: "min_depth" must be a whole number, 0 or more, not "7\.5"/, 'min_depth 7.5'],
		[[vcf => $v, report => 2], qr/^sex_check: "report" must be 0 or 1, not "2"/, 'report 2'],
		[['cutoff', 0.5, 'min_depth'], qr/^sex_check: takes name => value pairs, and was given an odd number of arguments/, 'an odd list that starts with an option'],
		[[$v, 'report'], qr/^sex_check: ".+sex\.vcf" is the file, so the options after it must be name => value pairs, and are an odd number/, 'the file and an option with no value, which is read as a pair'],
		[[vcf => $v, report => 'yes'], qr/^sex_check: "report" must be 0 or 1, not "yes"/, 'report "yes"'],
		[[vcf => \'calls'], qr/^sex_check: "vcf" must be a file name, not a SCALAR ref/, 'a scalar ref'],
		[[vcf => catfile($dir, 'none.vcf.bz2')], qr/^sex_check: "vcf" file ".+none\.vcf\.bz2" doesn't exist or isn't readable/, 'a VCF that is not there'],
		[[vcf => $dir], qr/^sex_check: "vcf" file ".+" doesn't exist or isn't readable/, 'a directory'],
		[[vcf => spew('sex.bcf', '')], qr/^sex_check: "vcf" file .+sex\.bcf must end in \.vcf, \.vcf\.gz, \.vcf\.bgz or \.vcf\.bz2/, 'a BCF'],
		[[vcf => spew('sex.vcf.zst', '')], qr/^sex_check: "vcf" file .+sex\.vcf\.zst must end in/, 'a .vcf.zst'],
	);
	foreach my $c (@cases) {
		my ($args, $re, $name) = @{ $c };
		dies_like sub { sex_check(@{ $args }) }, $re, "sex_check: $name dies";
	}
}

#  relatedness 

# Added with relatedness on 2026-10-19; t/relatedness.t has the counts
# themselves, and the errors that come from reading the files. Each case here
# dies before any file is opened.
{
	my $hdr = "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT";
	my $two = spew('two.vcf', "$hdr\tA\tB\n1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\t0/0\n");
	my $a = spew('a.vcf', "$hdr\tA\n1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n");
	my $b = spew('b.vcf', "$hdr\tB\n1\t6\t.\tA\tG\t.\t.\t.\tGT\t0/1\n");
	my @w;
	{
		local $SIG{__WARN__} = sub { push @w, $_[0] };
		is_deeply [sort keys %{ relatedness($two, report => 0) }], ['A', 'B'], 'relatedness: the arguments below differ from these only where they say';
		is relatedness($a, $b, report => 0)->{A}{B}{sites}, 2, 'relatedness: and two own VCFs';
	}
	is scalar(@w), 2, 'relatedness: which are undecided, with too few sites, and say so';
	my $none = catfile($dir, 'none.vcf');
	my @cases = (
		[[], qr/^relatedness: needs a VCF of several samples, or several VCFs of one/, 'nothing'],
		[[report => 0], qr/^relatedness: needs a VCF/, 'options and no VCF'],
		[[{ vcf => $two }], qr/^relatedness: takes name => value pairs, not a hash ref/, 'a hash ref'],
		[[$two, 'report'], qr/^relatedness: takes name => value pairs, and was given an odd number of arguments/, 'the file and an option with no value'],
		[[$two, depth => 7], qr/^relatedness: doesn't know "depth"; it takes max_ibs0, min_depth, report, vcf/, 'a misspelled option'],
		[[$a, vcf => $b], qr/^relatedness: the VCFs are given either first, unnamed, or as "vcf", not both/, 'files both first and as "vcf"'],
		[[vcf => []], qr/^relatedness: needs a VCF/, 'an empty array as "vcf"'],
		[[vcf => { a => $a }], qr/^relatedness: "vcf" must be a file name, not a HASH ref/, 'a hash ref as "vcf"'],
		[[vcf => [$a, undef]], qr/^relatedness: "vcf" must be a file name, not undef/, 'an undef among the files'],
		[[vcf => [$a, \'b']], qr/^relatedness: "vcf" must be a file name, not a SCALAR ref/, 'a scalar ref among the files'],
		[[$a, $none], qr/^relatedness: "vcf" file "\Q$none\E" doesn't exist or isn't readable/, 'a file that is not there'],
		[[$a, $dir], qr/^relatedness: "vcf" file ".+" doesn't exist or isn't readable/, 'a directory'],
		[[$a, spew('b.bcf', '')], qr/^relatedness: "vcf" file .+b\.bcf must end in \.vcf, \.vcf\.gz, \.vcf\.bgz or \.vcf\.bz2/, 'a BCF'],
		[[$a, $b, $a], qr/^relatedness: "\Q$a\E" is given twice/, 'one file twice'],
		[[$two, min_depth => -1], qr/^relatedness: "min_depth" must be a whole number, 0 or more, not "-1"/, 'min_depth -1'],
		[[$two, min_depth => 7.5], qr/^relatedness: "min_depth" must be a whole number, 0 or more, not "7\.5"/, 'min_depth 7.5'],
		[[$two, max_ibs0 => 0], qr/^relatedness: "max_ibs0" must be a number above 0, not "0"/, 'max_ibs0 0'],
		[[$two, max_ibs0 => 'NaN'], qr/^relatedness: "max_ibs0" must be a number above 0, not "NaN"/, 'max_ibs0 NaN'],
		[[$two, max_ibs0 => [0.01]], qr/^relatedness: "max_ibs0" must be a number above 0, not an ARRAY ref/, 'max_ibs0 an array ref'],
		[[$two, report => 'yes'], qr/^relatedness: "report" must be 0 or 1, not "yes"/, 'report "yes"'],
	);
	foreach my $c (@cases) {
		my ($args, $re, $name) = @{ $c };
		dies_like sub { relatedness(@{ $args }) }, $re, "relatedness: $name dies";
	}
}

# The XSUB's own checks of what perl hands it, which relatedness never gets
# wrong; they named XS_Cn__Bioinf__relatedness_own, __func__ in an XSUB, up to
# 2026-11-02.
{
	dies_like sub { Cn::Bioinf::_relatedness_own([sub { undef }], [], 0) },
		qr/^_relatedness_own: 1 readers for 0 files/, '_relatedness_own: names itself when its arrays differ in length';
	my @sparse;
	$sparse[1] = 'b.vcf'; # element 0 does not exist
	dies_like sub { Cn::Bioinf::_relatedness_own([sub { undef }, sub { undef }], \@sparse, 0) },
		qr/^_relatedness_own: file 0 has no reader/, '_relatedness_own: and when a file is missing';
}

#  concordance 

# Added with concordance on 2026-10-19; t/concordance.t has the counts
# themselves, and the errors that come from reading the files. Each case here
# dies before any file is opened.
{
	my $hdr = "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT";
	my $truth = spew('conc.truth.vcf', "$hdr\tS\n1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n");
	my $test = spew('conc.test.vcf', "$hdr\tS\n1\t5\t.\tA\tG\t.\t.\t.\tGT\t1/1\n");
	is concordance(truth => $truth, test => $test, report => 0)->{S}{counts}{discordant_het_ref_to_hom_alt}, 1,
		'concordance: the arguments below differ from these only where they say';
	my %ok = (truth => $truth, test => $test);
	my $none = catfile($dir, 'none.vcf');
	my @cases = (
		[[], qr/^concordance: needs "test", "truth"/, 'nothing'],
		[[truth => $truth], qr/^concordance: needs "test"/, 'no test'],
		[[test => $test], qr/^concordance: needs "truth"/, 'no truth'],
		[[{ %ok }], qr/^concordance: takes name => value pairs, not a hash ref/, 'a hash ref'],
		[[%ok, 'report'], qr/^concordance: takes name => value pairs, and was given an odd number of arguments/, 'an option with no value'],
		[[%ok, depth => 7], qr/^concordance: doesn't know "depth"; it takes discordances, min_depth, report, test, truth/, 'a misspelled option'],
		[[%ok, truth => [$truth]], qr/^concordance: "truth" must be a file name, not an ARRAY ref/, 'an array ref as "truth"'],
		[[%ok, test => \'x'], qr/^concordance: "test" must be a file name, not a SCALAR ref/, 'a scalar ref as "test"'],
		[[%ok, test => $none], qr/^concordance: "test" file "\Q$none\E" doesn't exist or isn't readable/, 'a test that is not there'],
		[[%ok, truth => $dir], qr/^concordance: "truth" file ".+" doesn't exist or isn't readable/, 'a directory as "truth"'],
		[[%ok, truth => spew('conc.bcf', '')], qr/^concordance: "truth" file .+conc\.bcf must end in \.vcf, \.vcf\.gz, \.vcf\.bgz or \.vcf\.bz2/, 'a BCF'],
		[[%ok, min_depth => -1], qr/^concordance: "min_depth" must be a whole number, 0 or more, not "-1"/, 'min_depth -1'],
		[[%ok, min_depth => 7.5], qr/^concordance: "min_depth" must be a whole number, 0 or more, not "7\.5"/, 'min_depth 7.5'],
		[[%ok, min_depth => [7]], qr/^concordance: "min_depth" must be a whole number, 0 or more, not an ARRAY ref/, 'min_depth an array ref'],
		[[%ok, discordances => 2], qr/^concordance: "discordances" must be 0 or 1, not "2"/, 'discordances 2'],
		[[%ok, discordances => 'yes'], qr/^concordance: "discordances" must be 0 or 1, not "yes"/, 'discordances "yes"'],
		[[%ok, report => 'yes'], qr/^concordance: "report" must be 0 or 1, not "yes"/, 'report "yes"'],
	);
	foreach my $c (@cases) {
		my ($args, $re, $name) = @{ $c };
		dies_like sub { concordance(@{ $args }) }, $re, "concordance: $name dies";
	}
}

#  plot_msa 

my %two = (fasta => { a => 'MK', b => 'MV' }, filename => catfile($dir, 'x.png'), query => 'a');
foreach my $n (0, -1, 1.5, 'two') {
	dies_like sub { plot_msa(%two, 'active_site_aa' => { X => $n }) },
		qr/^plot_msa: active site X must be a residue number, 1 or more, not "\Q$n\E"/, "active site $n dies, rather than counting from the end";
}
dies_like sub { plot_msa(%two, 'active_site_aa' => [1]) }, qr/^plot_msa: "active_site_aa" must be a hash ref/, 'active_site_aa must be a hash ref';
dies_like sub { plot_msa(%two, tooltips => 'yes') }, qr/^plot_msa: "tooltips" must be 0 or 1, not "yes"/, 'tooltips "yes" dies';
dies_like sub { plot_msa(%two, tooltips => 1) }, qr/^plot_msa: "tooltips" needs an SVG "filename", the only format that carries them, not "\Q$two{filename}\E"/,
	'tooltips in a PNG dies';

# Up to 2026-10-17 a wrong kind of reference died with perl's own "Not an
# ARRAY reference" or "Can't use string", naming no function.
my %two_noq = (fasta => { a => 'MK', b => 'MV' }, filename => catfile($dir, 'x.png'));
foreach my $case (
	[sub { plot_msa(%two_noq, order => 'a') },        qr/^plot_msa: "order" must be an array ref, not "a"/],
	[sub { plot_msa(%two_noq, labels => ['a']) },     qr/^plot_msa: "labels" must be a hash ref, not an ARRAY ref/],
	[sub { plot_msa(%two_noq, 'clustal_args' => '--iter=2') }, qr/^plot_msa: "clustal_args" must be an array ref, not "--iter=2"/],
	[sub { plot_phylo(fasta => { a => 'MK', b => 'MV' }, labels => 'a') }, qr/^plot_phylo: "labels" must be a hash ref, not "a"/],
	[sub { plot_phylo(fasta => { a => 'MK', b => 'MV' }, 'clustal_args' => {}) }, qr/^plot_phylo: "clustal_args" must be an array ref, not a HASH ref/],
) {
	dies_like $case->[0], $case->[1], "dies: $case->[1]";
}
# A sequence that is undef, a reference or empty is refused before clustalo
# runs. Up to 2026-11-02 undef warned "uninitialized" and then died in
# write_fasta, a reference was written as "ARRAY(0x...)" for clustalo to
# align, and an empty one died in clustalo ("Sequence 's2' has 0 residues"),
# none of them naming plot_msa; and a fasta that was neither a file nor a hash
# ref named _ungapped_fasta.
foreach my $case (
	[{ a => 'MK', b => undef }, qr/^plot_msa: "fasta" sequence "b" must be a string of residues, not undef/, 'undef'],
	[{ a => 'MK', b => [1] }, qr/^plot_msa: "fasta" sequence "b" must be a string of residues, not an ARRAY ref/, 'an ARRAY ref'],
	[{ a => 'MK', b => '' }, qr/^plot_msa: "fasta" sequence "b" has no residues/, 'empty'],
	[{ a => 'MK', b => '--.-' }, qr/^plot_msa: "fasta" sequence "b" has no residues/, 'only gaps'],
	[[], qr/^plot_msa: "fasta" must be a FASTA file name or a hash ref of name => sequence, not an ARRAY ref/, 'an ARRAY ref for fasta'],
) {
	my ($fasta, $re, $name) = @{ $case };
	my $warned = '';
	local $SIG{__WARN__} = sub { $warned .= $_[0] };
	dies_like sub { plot_msa(%two_noq, fasta => $fasta) }, $re, "plot_msa: a sequence that is $name dies";
	is $warned, '', "plot_msa: with no warning first, for a sequence that is $name";
}
dies_like sub { msa_quality_table(fasta => { a => 'MK', b => '' }, filename => catfile($dir, 'q.png'), metric => 'evalue') },
	qr/^msa_quality_table: "fasta" sequence "b" has no residues/, 'msa_quality_table: so does an empty sequence';

# "fh" and "execute", as Matplotlib::Simple's plt takes them, are checked
# before clustalo would run.
open my $plain, '>', catfile($dir, 'plain.py') or die $!;
foreach my $f ([\&plot_msa, 'plot_msa', %two_noq], [\&plot_phylo, 'plot_phylo', fasta => $two_noq{fasta}]) {
	my ($code, $name, @args) = @{ $f };
	foreach my $case (
		[[execute => 'yes'], qr/^$name: "execute" must be 0 or 1, not "yes"/],
		[[execute => 2],     qr/^$name: "execute" must be 0 or 1, not "2"/],
		[[execute => []],    qr/^$name: "execute" must be 0 or 1, not an ARRAY ref/],
		[[fh => $plain],     qr/^$name: "fh" must be a File::Temp object, as for Matplotlib::Simple, not a GLOB ref/],
		[[fh => 'x.py'],     qr/^$name: "fh" must be a File::Temp object, as for Matplotlib::Simple, not "x\.py"/],
	) {
		dies_like sub { $code->(@args, @{ $case->[0] }) }, $case->[1], "dies: $case->[1]";
	}
}
close $plain;

#  msa_quality_table 

# Two sequences, every pair with an e-value of 0, as BLAST reports strong hits
my $hit = sub { { description => [{ title => $_[0] }], hsps => [{ evalue => 0 }] } };
my $blast = { BlastOutput2 => [map {
	my $q = $_;
	{ report => { results => { bl2seq => [{ query_title => $q, hits => [map { $hit->($_) } 'A.b', 'C.d'] }] } } }
} 'A.b', 'C.d'] };
my %q = ('alignment_json' => $blast, filename => catfile($dir, 'q.png'), metric => 'evalue');
dies_like sub { msa_quality_table(%q, normalize => 1) },
	qr/^msa_quality_table: can't normalize "evalue", since its largest value is 0, not above 0/, 'normalizing all-zero e-values dies, rather than dividing by 0';
dies_like sub { msa_quality_table(%q, order => 'A.b') }, qr/^msa_quality_table: "order" must be an array ref, not "A\.b"/, 'an order that is not an array ref dies';
dies_like sub { msa_quality_table(%q, 'alignment_json' => []) },
	qr/^msa_quality_table: "alignment_json" must be a file name or a hash ref, not an ARRAY ref/, 'and so does an alignment_json that is neither';
# E.f is a query with no hit; up to 2026-11-10 this case named a sequence the
# report lacked altogether, which now dies of that (see "found by review on 2026-11-10" below)
dies_like sub { msa_quality_table(%q, 'alignment_json' => { BlastOutput2 => [@{ $blast->{BlastOutput2} },
		{ report => { results => { bl2seq => [{ query_title => 'E.f', hits => [] }] } } }] }, order => ['E.f']) },
	qr/^msa_quality_table: no pair of the sequences in "order" has a "evalue" value/, 'an order with nothing to draw dies';
# a file of JSON that is not a BLAST report used to die with perl's "Not a HASH
# reference", and one that is not JSON at all with JSON::MaybeXS's message
dies_like sub { msa_quality_table(%q, 'alignment_json' => spew('q_array.json', '[1]')) },
	qr/^msa_quality_table: "alignment_json" isn't a BLAST report in JSON \(-outfmt 15\): it has no "BlastOutput2" array/, 'an alignment_json of a JSON array dies';
dies_like sub { msa_quality_table(%q, 'alignment_json' => spew('q_bad.json', '{not json')) },
	qr/^msa_quality_table: .+q_bad\.json isn't JSON: /, 'and one that is not JSON';

#  view_alignment

my $ab = hash2fasta_file({ 'a_b^c~d' => 'MK-LV', 'e{f}' => 'M-QLV' }, catfile($dir, 'ab.aln.fa'));
my $tex = catfile($dir, 'r.tex');
my %view = ('msa_file' => $ab, 'output_file' => $tex);
foreach my $k ('row_width', 'split') {
	foreach my $v (0, -3, 'x') {
		dies_like sub { view_alignment(%view, $k => $v) }, qr/^view_alignment: "\Q$k\E" must be a whole number, 1 or more, not "\Q$v\E"/,
			"$k $v dies" . ($k eq 'row_width' && $v eq '0' ? ', rather than looping forever' : '');
	}
}
dies_like sub { view_alignment(%view, order => 'e{f}') }, qr/^view_alignment: "order" must be an array ref, not "e\{f\}"/,
	'an order that is not an array ref dies';
dies_like sub { view_alignment(%view, 'color_residues' => { 'e{f}' => [2] }) },
	qr/^view_alignment: "color_residues" must map e\{f\} to a hash ref of residue number => color, not an ARRAY ref/,
	'and so does a protein in color_residues that maps to anything but a hash ref';
foreach my $n (0, -1) {
	dies_like sub { view_alignment(%view, 'color_residues' => { 'e{f}' => { $n => 'red' } }) },
		qr/^view_alignment: a residue of e\{f\} in "color_residues" must be a residue number, 1 or more, not "$n"/,
		"colouring residue $n dies, rather than colouring the last";
}
{
	open my $saved, '>&', \*STDOUT or die $!;
	open STDOUT, '>', catfile($dir, 'out.txt') or die $!;
	my $text = view_alignment(%view);
	open STDOUT, '>&', $saved or die $!;
	like $text, qr/^# alignment: 2 sequences x 5 columns\n/, 'view_alignment returns the text it shows';
	is slurp(catfile($dir, 'out.txt')), "$text" . "wrote $tex\n", 'and prints it, and then the "wrote" line, with no color when STDOUT is not a terminal';
}
my $body = slurp($tex);
like $body, qr/^\\textit\{a\\_b\\textasciicircum\{\}c\\textasciitilde\{\}d\} & /m, 'a name\'s _, ^ and ~ print as themselves';
like $body, qr/^\\textit\{e\\\{f\\\}\} & /m, 'and so do its braces';
{
	# Up to 2026-11-02 |, < and > were left as they were, and print under
	# LaTeX's default OT1 fonts as an em dash and an inverted ! and ?; and the
	# residues were not escaped at all, so a % in one ended the line.
	local *STDOUT; # for the "wrote" lines, which are not TAP
	open STDOUT, '>', catfile($dir, 'quiet.txt') or die "can't send STDOUT to quiet.txt: $!";
	my $odd = hash2fasta_file({ 'sp|P1|<x>' => 'MK%L#' }, catfile($dir, 'odd.aln.fa'));
	view_alignment('msa_file' => $odd, 'output_file' => $tex);
	like slurp($tex), qr/^\\textit\{sp\\textbar\{\}P1\\textbar\{\}\\textless\{\}x\\textgreater\{\}\} & \\texttt\{MK\\%L\\#\} & 3$/m,
		'a name\'s |, < and > print as themselves, and so do a residue\'s % and #';
}
{
	# A number in a block's last columns used to be left off the track row,
	# and so did every number after it in that block; it now ends at the
	# block's end. 9 and 10 in the second case cannot both fit, so 10 is left
	# out and 9 kept.
	local *STDOUT; # for the "wrote" lines, which are not TAP
	open STDOUT, '>', catfile($dir, 'quiet.txt') or die "can't send STDOUT to quiet.txt: $!";
	my $one = hash2fasta_file({ a => 'ACDEFGHIKLMN', b => 'ACDEFGHIKLMN' }, catfile($dir, 'track.aln.fa'));
	my %t = ('msa_file' => $one, 'output_file' => $tex, 'row_width' => 10, track => 'a');
	view_alignment(%t, 'color_residues' => { a => { 3 => 'red', 5 => 'blue', 10 => 'green', 11 => 'red' } });
	my @track = slurp($tex) =~ /^\\textit\{a\} track & \\texttt\{([^}]*)\}/mg;
	is_deeply \@track, ['--3-5---10', '11'], 'view_alignment: a residue number in the last column of a block ends at the block\'s end';
	view_alignment(%t, 'color_residues' => { a => { 9 => 'red', 10 => 'green' } });
	@track = slurp($tex) =~ /^\\textit\{a\} track & \\texttt\{([^}]*)\}/mg;
	is_deeply \@track, ['--------9-', '--'], 'view_alignment: and one that would overlap the number before it is left out';
	# A tracked protein that "order" leaves out has no track row, and used to be
	# counted as having one, so a table held more blocks than "split" said.
	view_alignment(%t, track => 'b', order => ['a'], 'row_width' => 4, split => 2);
	my $tables = () = slurp($tex) =~ /\\begin\{table\}/g;
	is $tables, 2, 'view_alignment: three blocks at 2 a table are two tables when the tracked protein is not shown';
	# a residue number that is not a number used to warn "isn't numeric in
	# sort" before it was refused
	my $warned = '';
	local $SIG{__WARN__} = sub { $warned .= $_[0] };
	dies_like sub { view_alignment(%t, 'color_residues' => { a => { abc => 'red', 2 => 'blue' } }) },
		qr/^view_alignment: a residue of a in "color_residues" must be a residue number, 1 or more, not "abc"/,
		'view_alignment: a residue number "abc" dies';
	is $warned, '', 'view_alignment: with no warning from sorting it first';
}
# view_alignment's terminal text and SVG (2026-11-16), worked out by hand for
# the alignment below, as t/msa.t's LaTeX is: residue 2 of a is column 2 and
# residue 3 is column 4, and 3 columns a block. The name column is as wide as
# "a track", and the counts end 2 columns past the widest block. The SVG's
# lengths are 7.2 px a character, from an 8 px margin; its metadata is laid
# out as Matplotlib::Simple 0.33's svg_creator_metadata lays it out.
{
	my %ab = (a => 'MK-LV', b => 'M-QLV');
	my %show = ('row_width' => 3, track => 'a', 'color_residues' => { a => { 2 => 'red', 3 => [1, 0, 0] } }, 'return_only' => 1);
	my $text = <<'EOT';
# alignment: 2 sequences x 5 columns
         1 3
a        MK-  2
a track  -2-
b        M-Q  2

         4
a        LV   4
a track  3-
b        LV   4
# alignment: 2 sequences x 5 columns
EOT
	is view_alignment(\%ab, %show), $text, 'view_alignment: a hash ref first, shown as text, the banner first and last';
	my $fa = hash2fasta_file(\%ab, catfile($dir, 'view.aln.fa'));
	is view_alignment($fa, %show), $text, 'view_alignment: and the same from a FASTA file name first';
	is view_alignment(\%ab, 'return_only' => 1, order => ['b']), <<'EOT', 'view_alignment: "order" leaves a sequence out, which the banner says';
# alignment: 2 sequences x 5 columns  (showing 1)
   1   5
b  M-QLV  4
# alignment: 2 sequences x 5 columns  (showing 1)
EOT
	# a tab in a name would break its row in two columns, as Stats::LikeR's view writes it
	like view_alignment({ "x\ty" => 'MK' }, 'return_only' => 1), qr/^x\\ty  MK  2$/m, 'view_alignment: a tab in a name is shown as \t';
	# printed to "to", and not to STDOUT, with return_only 0 (the default)
	open my $to, '>', \my $buf or die $!;
	{
		local *STDOUT;
		open STDOUT, '>', catfile($dir, 'quiet.txt') or die $!;
		view_alignment(\%ab, %show, 'return_only' => 0, to => $to);
	}
	is $buf, $text, 'view_alignment: printed to "to"';
	is slurp(catfile($dir, 'quiet.txt')), '', 'view_alignment: and to nothing else';
	# the colors of a terminal, which a test cannot be: 24-bit ANSI, then a reset
	my $blocks = [{ start => 0, width => 2, rows => [{ label => 'a', track => 0, chars => ['M', 'K'], colors => [undef, 'orange'], count => 2 }] }];
	is Cn::Bioinf::_alignment_text($blocks, '#', 1), "#\n   1\na  M\e[38;2;255;128;0mK\e[0m  2\n#\n",
		'view_alignment: in a terminal, a colored residue is a 24-bit ANSI color (xcolor\'s orange, 1 .5 0)';

	my $svg = catfile($dir, 'view.svg');
	view_alignment({ %ab, 'x&<y>' => 'MKQ%V' }, %show, 'output_file' => $svg);
	my $got = slurp($svg);
	like $got, qr{\A<\?xml version="1\.0" encoding="utf-8" standalone="no"\?>\n<svg xmlns="http://www\.w3\.org/2000/svg" width="124" height="192" viewBox="0 0 124 192" version="1\.1">\n <metadata>\n  <rdf:RDF xmlns:dc="http://purl\.org/dc/elements/1\.1/" xmlns:cc="http://creativecommons\.org/ns#" xmlns:rdf="http://www\.w3\.org/1999/02/22-rdf-syntax-ns#">\n   <cc:Work>\n    <dc:creator>\n     <cc:Agent>\n      <dc:title>[^<]+ called using "view_alignment" in [^<]+Bioinf\.pm version \Q$Cn::Bioinf::VERSION\E by user [^<]+, written as SVG by [^<]+Bioinf\.pm itself; from a hash ref of 3 sequences; showing 3 of 3 sequences in blocks of 3 columns, tracking a, coloring 2 columns</dc:title>\n     </cc:Agent>\n    </dc:creator>\n   </cc:Work>\n  </rdf:RDF>\n </metadata>\n},
		'view_alignment: an SVG\'s provenance is in its <dc:creator>, as Matplotlib::Simple writes it, and names no Alien::Bioinf';
	# Up to 2026-11-16 a row was one <text> stretched by textLength, which
	# librsvg 2.58 (Eye of GNOME) ignores, so its letters drifted right of their
	# columns; each is now placed at its column's center, 72.8 + 3.6 + 7.2 i.
	like $got, qr{\Q<text y="36" text-anchor="middle" xml:space="preserve"><tspan x="76.4">M</tspan><tspan x="83.6" fill="rgb(255,0,0)">K</tspan><tspan x="90.8">-</tspan></text>\E},
		'view_alignment: each residue is a <tspan> centered on its column, rather than a row stretched by textLength, which librsvg ignores';
	ok $got =~ /<tspan x=/ && $got !~ /textLength/, 'view_alignment: and no row uses textLength';
	like $got, qr{<rect x="80" y="24" width="7\.2" height="16" fill="none" pointer-events="all"><title>a: K2, alignment column 2</title></rect>},
		'view_alignment: with a tooltip over each colored residue';
	like $got, qr{<title>b: a gap, alignment column 2</title>}, 'view_alignment: and over a gap in a colored column';
	like $got, qr{<text x="8" y="84">x&amp;&lt;y&gt;</text>}, 'view_alignment: a name\'s & and < are XML\'s';
	like $got, qr{\Q<tspan x="76.4">M</tspan><tspan x="83.6" fill="rgb(255,0,0)">K</tspan><tspan x="90.8">Q</tspan></text>\E}, 'view_alignment: the third sequence is drawn';
	like $got, qr{\Q<tspan x="76.4" fill="rgb(255,0,0)">%</tspan><tspan x="83.6">V</tspan></text>\E}, 'view_alignment: and a "%" residue is drawn as itself, not taken for a format';
	# an aligned input needs no clustalo, so no Alien::Bioinf, which a smoker lacks
	my $hidden = catfile($dir, 'hidden.svg');
	system($^X, @inc, '-e', "$hide use Cn::Bioinf q{view_alignment}; view_alignment({ a => q{MK}, b => q{MV} }, q{output_file} => \$ARGV[0], q{return_only} => 1)", $hidden);
	like slurp($hidden), qr{<dc:title>[^<]+ called using "view_alignment" [^<]+</dc:title>}, 'view_alignment: an SVG is written without Alien::Bioinf';
	my ($open, $close) = (scalar(() = $got =~ /<text /g), scalar(() = $got =~ m{</text>}g));
	ok $open > 0 && $open == $close, "view_alignment: every one of its $open <text> elements is closed";
	like $got, qr{</g>\n</svg>\n\z}, 'view_alignment: and so is the SVG';

	# "title" (2026-11-16): a bold 14 px line in a 20 px band above the rest,
	# which moves every line down by 20 (the first header from y 20 to 40, and
	# the first row from 36 to 56), and widens the image when it is wider than
	# the alignment, at 8.4 px a character
	my $titled = catfile($dir, 'titled.svg');
	view_alignment({ %ab, 'x&<y>' => 'MKQ%V' }, %show, 'output_file' => $titled, title => 'a<b> & c');
	$got = slurp($titled);
	like $got, qr{<svg [^>]*width="124" height="212" viewBox="0 0 124 212"}, 'view_alignment: a "title" makes the SVG 20 px taller';
	like $got, qr{\Q<text x="8" y="23" font-size="14" font-weight="bold">a&lt;b&gt; &amp; c</text>\E\n  <text x="72.8" y="40"},
		'view_alignment: and is drawn above the first block, its <, > and & XML\'s';
	like $got, qr{\Q<text y="56" text-anchor="middle" xml:space="preserve"><tspan x="76.4">M</tspan>\E},
		'view_alignment: and the rows are drawn below it';
	view_alignment(\%ab, 'return_only' => 1, 'output_file' => $titled, title => 'x' x 20);
	like slurp($titled), qr{<svg [^>]*width="184" }, 'view_alignment: a "title" wider than the alignment widens the SVG to hold it (8 + 20 x 8.4 + 8)';

	# "color" (2026-11-16): every residue on plot_msa's color for it, which
	# is share/msa_plot.py's AA or NT. Its text is white or black, whichever
	# _text_on picks: white on K (#0038a2, L = 0.0544) and black on M
	# (#c9c433, L = 0.5214) and on red (L = 0.2126), the WCAG 2.2 line being
	# L = 0.1791. The x and y are the 7.2 px layout above, with the name
	# column 1 character wide, so the residues start at 8 + 3 * 7.2 = 29.6.
	my $py = slurp(catfile($FindBin::Bin, File::Spec->updir, 'share', 'msa_plot.py'));
	foreach my $table (['AA', 'aa'], ['NT', 'nt']) {
		my ($name, $key) = @{ $table };
		my ($dict) = $py =~ /^$name = dict\((.*?)\)\n/ms;
		ok defined $dict, "view_alignment: msa_plot.py has its $name table";
		my %want = ($dict // '') =~ /\b([A-Z])='(#[0-9a-f]{6})'/gi;
		while (($dict // '') =~ /\{c: '(#[0-9a-f]{6})' for c in '([A-Z]+)'\}/g) {
			my $hex = $1;
			$want{$_} = $hex foreach split //, $2;
		}
		is_deeply Cn::Bioinf::_residue_colors()->{$key}, \%want, "view_alignment: \"color\" has msa_plot.py's $name colors, so that it colors as plot_msa does";
	}
	my $colored = catfile($dir, 'colored.svg');
	view_alignment(\%ab, color => 1, 'row_width' => 5, 'output_file' => $colored, 'return_only' => 1);
	$got = slurp($colored);
	like $got, qr{\Q  <rect x="29.6" y="24" width="7.2" height="16" fill="rgb(201,196,51)"/>\E\n\Q  <rect x="36.8" y="24" width="7.2" height="16" fill="rgb(0,56,162)"/>\E\n\Q  <rect x="51.2" y="24" width="14.4" height="16" fill="rgb(86,174,108)"/>\E\n},
		'view_alignment: with "color", a background under each residue, one for each run of a color, and none under a gap';
	like $got, qr{\Q<tspan x="33.2">M</tspan><tspan x="40.4" fill="rgb(255,255,255)">K</tspan><tspan x="47.6">-</tspan><tspan x="54.8">L</tspan><tspan x="62">V</tspan></text>\E},
		'view_alignment: and white text where it reads better than black, each letter centered on its background';
	like $got, qr{, every residue on its color from CIAlign's CBS amino acid palette, as plot_msa colors it</dc:title>}, 'view_alignment: which its provenance says';
	view_alignment(\%ab, color => 1, 'row_width' => 5, 'output_file' => $colored, 'return_only' => 1, 'color_residues' => { a => { 2 => 'red' } });
	like slurp($colored), qr{\Q<tspan x="40.4" font-weight="bold" text-decoration="underline">K</tspan>\E},
		'view_alignment: one of "color_residues" is on its own color, bold and underlined';
	view_alignment({ x => 'ACGT', y => 'AC-T' }, color => 1, 'output_file' => $colored, 'return_only' => 1);
	$got = slurp($colored);
	like $got, qr{CIAlign's CBS nucleotide palette}, 'view_alignment: sequences of nucleotide codes are on the nucleotide palette';
	like $got, qr{fill="rgb\(162,44,73\)"/>}, 'view_alignment: and sequences of nucleotide codes are on the nucleotide colors (T #a22c49, not the amino acid #e57700)';
	is view_alignment(\%ab, %show, color => 1), $text, 'view_alignment: "color" adds nothing to the text returned, which has no escapes';
	my $ctex = catfile($dir, 'colored.tex');
	view_alignment(\%ab, color => 1, 'row_width' => 5, 'output_file' => $ctex, 'return_only' => 1, 'color_residues' => { a => { 2 => 'red' } });
	my $tex_body = slurp($ctex);
	like $tex_body, qr/^\\begin\{table\}\[htp\]\\footnotesize\n\\setlength\{\\fboxsep\}\{0pt\}\n\\begin\{tabular\}/m, 'view_alignment: the LaTeX\'s boxes have no margin, so that they meet';
	unlike $tex_body, qr/\\textbf\{[^}]*\}\\par/, 'view_alignment: and with no "title", no title line';
	# "title" (2026-11-16): a bold line above each table, as LaTeX prints it
	view_alignment(\%ab, 'row_width' => 2, split => 1, 'output_file' => $ctex, 'return_only' => 1, title => 'A_1 & 50%');
	is_deeply [slurp($ctex) =~ /^\\begin\{table\}\[htp\]\\footnotesize\n(.*)\n\\begin\{tabular\}/mg],
		['\textbf{A\_1 \& 50\%}\par', '\textbf{A\_1 \& 50\%} (continued)\par', '\textbf{A\_1 \& 50\%} (continued)\par'],
		'view_alignment: a "title" heads each LaTeX table, escaped, and is "(continued)" after the first';
	is +($tex_body =~ /^(\\textit\{a\} & .*)$/m)[0],
		'\textit{a} & \texttt{\colorbox[RGB]{201,196,51}{\strut{}M}\colorbox[RGB]{255,0,0}{\strut{}\textbf{K}}-\colorbox[RGB]{86,174,108}{\strut{}L}\colorbox[RGB]{86,174,108}{\strut{}V}} & 4',
		'view_alignment: and each residue is a \colorbox, with no command run on into the letter, as \strutM was';
	like $tex_body, qr/^\\textit\{b\} & \\texttt\{\\colorbox\[RGB\]\{201,196,51\}\{\\strut\{\}M\}\\colorbox\[RGB\]\{255,0,0\}\{\\strut\{\}\\textbf\{-\}\}/m,
		'view_alignment: and a gap in a column of "color_residues" is boxed too';
	# the terminal, which a test cannot be, from _alignment_text itself
	$blocks = [{ start => 0, width => 2, rows => [{ label => 'a', track => 0, chars => ['K', 'M'], colors => [undef, 'red'],
		bg => [[0, 56, 162], [255, 0, 0]], strong => [undef, 1], count => 2 }] }];
	is Cn::Bioinf::_alignment_text($blocks, '#', 1), "#\n   1\na  \e[38;2;255;255;255;48;2;0;56;162mK\e[0m\e[1;4;38;2;0;0;0;48;2;255;0;0mM\e[0m  2\n#\n",
		'view_alignment: in a terminal, a residue is on its background, and one of "color_residues" is bold and underlined';
	dies_like sub { view_alignment(\%ab, color => 'true') }, qr/^view_alignment: "color" must be 0 or 1, not "true"/, 'view_alignment: a "color" of "true" dies';

	foreach my $case (
		[[\%ab, 'msa_file' => $fa],             qr/^view_alignment: was given the alignment both first and as "msa_file"/],
		[[[1], 'return_only' => 1],             qr/^view_alignment: the alignment must be a hash ref of name => sequence or a FASTA file name, not an ARRAY ref/],
		[['', 'return_only' => 1],              qr/^view_alignment: the alignment must be a hash ref of name => sequence or a FASTA file name, not ""/],
		[['return_only' => 1],                  qr/^view_alignment: needs an alignment, first or as "msa_file"/],
		[[\%ab, 'output_file' => 'x.png'],      qr/^view_alignment: "output_file" must end in \.svg or \.tex, which say what to write, not "x\.png"/],
		[[\%ab, 'output_file' => 'x.svg', caption => 'C', split => 2], qr/^view_alignment: "caption", "split" only shape a LaTeX "output_file" \(\.tex\)/],
		[[\%ab, label => 'L'],                  qr/^view_alignment: "label" only shape a LaTeX "output_file" \(\.tex\)/],
		[[\%ab, title => 'T'],                  qr/^view_alignment: "title" is drawn only in an "output_file" \(\.svg or \.tex\), and none was given/],
		[[\%ab, 'output_file' => 'x.svg', title => ['T']], qr/^view_alignment: "title" must be a string, not an ARRAY ref/],
		[[\%ab, 'output_file' => 'x.svg', title => "two\nlines"], qr/^view_alignment: "title" holds a control character, \\x\{0a\}/],
		[[\%ab, 'return_only' => 'yes'],        qr/^view_alignment: "return_only" must be 0 or 1, not "yes"/],
		[[\%ab, to => []],                      qr/^view_alignment: "to" must be an open filehandle, not an ARRAY ref/],
		[[\%ab, 'color_residues' => { a => { 1 => 'ForestGreen' } }],
			qr/^view_alignment: the color of a residue 1 must be one of xcolor's base colors \(black, blue, .+, yellow\) or \[r, g, b\], each 0 to 1, not "ForestGreen"/],
		[[\%ab, 'color_residues' => { a => { 1 => [2, 0, 0] } }], qr/^view_alignment: the color of a residue 1 must be one of xcolor's base colors/],
		[[\%ab, 'color_residues' => { a => { 1 => ['x', 0, 0] } }], qr/^view_alignment: the color of a residue 1 must be one of xcolor's base colors/],
		[[{}],                                  qr/^view_alignment: has no sequences to show in the hash ref/],
		[[{ a => '' }],                         qr/^view_alignment: has no residues to show in the hash ref/],
		[[{ a => [] }],                         qr/^view_alignment: sequence "a" must be a string of residues, not an ARRAY ref/],
		[[{ a => "MK\nV" }],                    qr/^view_alignment: sequence "a" holds a control character, \\x\{0a\}/],
	) {
		my ($list, $re) = @{ $case };
		dies_like sub { view_alignment(@{ $list }) }, $re, "dies: $re";
	}
}

# ---- hirisplex_genotypes and trait_predict
#
# Neither needs any of Alien::Bioinf's programs, so every one of these runs
# wherever the module builds. The VCF below is a well-formed one that holds
# none of the panel's markers; what is being checked is the arguments, which
# are refused before it is opened.
{
	my $vcf = spew('checks.vcf', "##fileformat=VCFv4.2\n##contig=<ID=1,length=249250621>\n"
		. join("\t", '#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT S)) . "\n"
		. join("\t", 1, 100, 'rs1', 'A', 'G', '.', '.', '.', 'GT', '0/1') . "\n");
	my $bam = spew('checks.bam', "not a VCF\n");
	my $model = spew('checks_model.tsv', "trait\tcategory\tmarker\tbeta\neye\tblue\t(intercept)\t1\neye\tbrown\t(intercept)\t0\n");
	my @bad = (
		[['nowhere.vcf'], qr/^hirisplex_genotypes: "vcf" file "nowhere\.vcf" doesn't exist or isn't readable/, 'a missing file'],
		[[vcf => $vcf, match => 'rsid'], qr/^hirisplex_genotypes: "match" must be "position" or "id", not "rsid"/, 'an unknown match'],
		[[vcf => $vcf, build => 'hg18'], qr/^hirisplex_genotypes: "build" must be hg19, b37, hg38 or b38, not "hg18"/, 'an unknown build'],
		[[vcf => $vcf, min_depth => -1], qr/^hirisplex_genotypes: "min_depth" must be a whole number, 0 or more, not "-1"/, 'a negative min_depth'],
		[[vcf => $vcf, min_depth => '7.5'], qr/^hirisplex_genotypes: "min_depth" must be a whole number, 0 or more, not "7\.5"/, 'a fractional min_depth'],
		[[vcf => $vcf, report => 2], qr/^hirisplex_genotypes: "report" must be 0 or 1, not "2"/, 'a report of 2'],
		[[vcf => $vcf, file => []], qr/^hirisplex_genotypes: "file" must be a file name, not an ARRAY ref/, 'a file that is a ref'],
		[[vcf => $vcf, colour => 1], qr/^hirisplex_genotypes: doesn't know "colour"; it takes build, file, match, min_depth, report, vcf/, 'an unknown option'],
		[[vcf => $bam], qr/^hirisplex_genotypes: "vcf" file \Q$bam\E must end in \.vcf, \.vcf\.gz, \.vcf\.bgz or \.vcf\.bz2/, 'a file whose name says it is not a VCF'],
	);
	foreach my $case (@bad) {
		my ($args, $re, $name) = @{ $case };
		dies_like sub { hirisplex_genotypes(@{ $args }) }, $re, "hirisplex_genotypes: $name dies";
	}
	# A VCF whose header gives a length for none of the chromosomes the build
	# is told by, and one whose lengths are neither build's.
	my $nolen = spew('nolen.vcf', "##fileformat=VCFv4.2\n" . join("\t", '#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT S)) . "\n");
	dies_like sub { hirisplex_genotypes(vcf => $nolen, report => 0) },
		qr/^hirisplex_genotypes: "vcf" .* has no ##contig line giving a length for chromosome 1, 15, 16, 20/,
		'hirisplex_genotypes: a header with no length to tell the build by dies';
	my $odd = spew('oddlen.vcf', "##fileformat=VCFv4.2\n##contig=<ID=1,length=1000>\n"
		. join("\t", '#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT S)) . "\n");
	dies_like sub { hirisplex_genotypes(vcf => $odd, report => 0) },
		qr/^hirisplex_genotypes: "vcf" .* gives chromosome lengths that are neither GRCh37's nor GRCh38's \(1 is 1000\)/,
		'hirisplex_genotypes: a header whose lengths are neither build\'s dies';
	# Matching by rs number needs no build, so a header with no lengths is
	# enough for it; the file holds no marker, so every one is missing.
	{
		my $g;
		my $warned = '';
		local $SIG{__WARN__} = sub { $warned .= $_[0] };
		$g = hirisplex_genotypes(vcf => $vcf, match => 'id', report => 0);
		is $g->{S}{called}, 0, 'hirisplex_genotypes: a VCF with none of the markers calls none of them';
		is $g->{S}{markers}, 41, 'hirisplex_genotypes: and still counts the whole panel';
		is $g->{S}{eye}, 0, 'hirisplex_genotypes: with no HERC2 marker, no eye prediction is allowed';
		like $warned, qr/^hirisplex_genotypes: "vcf" .* holds none of the 41 HIrisPlex-S markers/,
			'hirisplex_genotypes: and it says so, rather than returning an empty answer quietly';
	}
	# The panel's insertion is checked to count one base, as every other marker
	# is; with none it used to be stored as base 0 and never counted.
	dies_like sub { Cn::Bioinf::_hirisplex_dosage(sub { undef }, 'x.vcf', 0, [[16, 89985751, '', 1, 'rs312262906', 0]], 1, 0) },
		qr/^hps_panel: entry 0 of the panel counts "", which isn't one base/, 'hirisplex_genotypes: a panel insertion of no base dies';
	dies_like sub { Cn::Bioinf::_hirisplex_dosage(sub { undef }, 'x.vcf', 0, [[16, 89985751, 'A', 1, 'rs312262906', 0]], 1, 0) },
		qr/^vcf_read: x\.vcf has no #CHROM line/, 'hirisplex_genotypes: and one of a base gets as far as reading the VCF';

	# a model that uses one marker, for checking the dosages given for it
	my $dose_model = [{ trait => 'eye', category => 'blue', marker => 'rs12913832_T', beta => 1 },
		{ trait => 'eye', category => 'brown', marker => '(intercept)', beta => 0 }];
	my @bad_model = (
		[[genotypes => 'x', model => $model], qr/^trait_predict: "genotypes" must be a hash ref of sample => genotypes, as hirisplex_genotypes returns, not "x"/, 'genotypes that are a string'],
		[[genotypes => {}, model => $model], qr/^trait_predict: "genotypes" has no samples/, 'no samples'],
		[[genotypes => { S => 'x' }, model => $model], qr/^trait_predict: "genotypes" sample "S" must be a hash ref, not "x"/, 'a sample that is a string'],
		[[genotypes => { S => {} }, model => 'nowhere.tsv'], qr/^trait_predict: "model" file "nowhere\.tsv" doesn't exist or isn't readable/, 'a missing model'],
		[[genotypes => { S => {} }, model => [{ trait => 'eye' }]], qr/^trait_predict: "model" has no "category", "marker", "beta" columns; a model table has trait, category, marker and beta/, 'a model missing columns'],
		[[genotypes => { S => {} }, model => [{ trait => 'eye', category => 'blue', marker => 'm', beta => 'x' }]],
			qr/^trait_predict: row 1 of "model" has beta "x", which isn't a number/, 'a beta that is not a number'],
		[[genotypes => { S => {} }, model => [{ trait => 'eye', category => 'blue', marker => '', beta => 1 }]],
			qr/^trait_predict: row 1 of "model" has no marker/, 'a row with no marker'],
		[[genotypes => { S => {} }, model => [{ trait => 'eye', category => 'blue', marker => 'm', beta => 1 },
			{ trait => 'eye', category => 'blue', marker => 'm', beta => 2 }]],
			qr/^trait_predict: row 2 of "model" gives eye category "blue" a second beta for m/, 'a marker given two betas'],
		[[genotypes => { S => {} }, model => $model, force => 2], qr/^trait_predict: "force" must be 0 or 1, not "2"/, 'a force of 2'],
		# a dosage used to be multiplied in whatever it held, so that "NA" was a
		# called genotype of 0 copies, with only perl's "isn't numeric" warning
		[[genotypes => { S => { 'rs12913832_T' => 'NA' } }, model => $dose_model],
			qr/^trait_predict: "genotypes" sample "S" has rs12913832_T "NA", which isn't a dosage from 0 to 2; a missing genotype is undef/,
			'a dosage of "NA", rather than counting it 0 copies'],
		[[genotypes => { S => { genotype => { 'rs12913832_T' => 3 } } }, model => $dose_model],
			qr/^trait_predict: "genotypes" sample "S" has rs12913832_T "3", which isn't a dosage from 0 to 2/, 'a dosage of 3'],
		[[genotypes => { S => { 'rs12913832_T' => -1 } }, model => $dose_model],
			qr/^trait_predict: "genotypes" sample "S" has rs12913832_T "-1", which isn't a dosage/, 'a dosage of -1'],
		[[genotypes => { S => { 'rs12913832_T' => [] } }, model => $dose_model],
			qr/^trait_predict: "genotypes" sample "S" has rs12913832_T an ARRAY ref, which isn't a dosage/, 'a dosage that is a ref'],
		[[genotypes => { S => {} }, model => $model, shade => 1], qr/^trait_predict: doesn't know "shade"; it takes force, genotypes, model, report/, 'an unknown option'],
	);
	foreach my $case (@bad_model) {
		my ($args, $re, $name) = @{ $case };
		dies_like sub { trait_predict(@{ $args }) }, $re, "trait_predict: $name dies";
	}
	# A model of one category is still a model: its probability is 1.
	my $one = trait_predict(genotypes => { S => { m => 2 } },
		model => [{ trait => 't', category => 'only', marker => '(intercept)', beta => '-3' }], report => 0);
	is $one->{S}{t}{p}{only}, 1, 'trait_predict: a model of one category gives it a probability of 1';
	is $one->{S}{t}{call}, 'only', 'trait_predict: and calls it';
	# A dosage between 0 and 2, as imputation gives, is a dosage; one the model
	# does not use is not looked at. The probability differs from the formula's
	# by 0 on perl 5.44.0; _softmax takes the larger predictor out first, which
	# can move the last bit, and 1e-12 is t/hirisplex.t's bound for the same.
	my $frac = trait_predict(genotypes => { S => { 'rs12913832_T' => '1.5', other => 'NA' } }, model => $dose_model, report => 0);
	cmp_ok abs($frac->{S}{eye}{p}{blue} - exp(1.5) / (exp(1.5) + 1)), '<', 1e-12, 'trait_predict: a dosage of 1.5 is multiplied in';
	is $frac->{S}{eye}{called}, 1, 'trait_predict: and is a called genotype';

	# Up to 2026-11-16 a data frame's rows were not checked against its
	# header or its columns against each other: an array row's extra field was
	# dropped, and a hash of arrays had as many rows as whichever column each
	# happened to give first, the others padded with undef or cut short.
	my @one = (['t', 'only', '(intercept)', -3]);
	is trait_predict(genotypes => { S => {} }, model => [[qw(trait category marker beta)], @one], report => 0)->{S}{t}{call}, 'only',
		'trait_predict: a model as an array of arrays is read';
	dies_like sub { trait_predict(genotypes => { S => {} }, model => [[qw(trait category marker beta)], [@{ $one[0] }, 'extra']], report => 0) },
		qr/^trait_predict: row 1 of "model" has 5 fields, and its header 4/, 'trait_predict: an array row longer than its header dies, rather than losing the extra field';
	dies_like sub { trait_predict(genotypes => { S => {} }, model => [[qw(trait category marker beta)], ['t', 'only', '(intercept)']], report => 0) },
		qr/^trait_predict: row 1 of "model" has 3 fields, and its header 4/, 'trait_predict: and one shorter than it';
	my %columns = (trait => ['t', 't'], category => ['only', 'only'], marker => ['(intercept)', 'm'], beta => [-3, 1]);
	is trait_predict(genotypes => { S => { m => 1 } }, model => \%columns, report => 0)->{S}{t}{call}, 'only',
		'trait_predict: a model as a hash of arrays is read';
	dies_like sub { trait_predict(genotypes => { S => {} }, model => { %columns, note => ['x'] }, report => 0) },
		qr/^trait_predict: column "note" of "model" has 1 value, and "beta" 2/,
		'trait_predict: a hash of arrays whose columns differ in length dies, rather than taking the length of whichever comes first';

	# Up to 2026-11-16 a gzipped "model" or "weights" file that ended early was
	# read as if it ended there. 20,000 rows compress to about 40 KB, and half
	# of that holds thousands of them.
	my $rows = join '', "trait\tcategory\tmarker\tbeta\n", "t\tonly\t(intercept)\t-3\n", map { "t\tonly\tm$_\t0\n" } 1 .. 20_000;
	my $tsv = spew('long_model.tsv', $rows);
	my $gz = catfile($dir, 'long_model.tsv.gz');
	IO::Compress::Gzip::gzip($tsv => $gz) or die "gzip $tsv: $IO::Compress::Gzip::GzipError";
	is trait_predict(genotypes => { S => {} }, model => $gz, report => 0)->{S}{t}{call}, 'only', 'trait_predict: a whole gzipped model is read';
	truncate $gz, int((-s $gz) / 2) or die "truncate $gz: $!";
	dies_like sub { trait_predict(genotypes => { S => {} }, model => $gz, report => 0) },
		qr/^trait_predict: "model" file .+long_model\.tsv\.gz ends early or is corrupt, after row [0-9]+: unexpected end of file/,
		'trait_predict: a truncated gzipped model dies, rather than being read as far as it goes';
}

# ---- pdb_search
#
# Each of these is refused before RCSB is asked, so _rcsb_post is replaced by
# one that dies, which would show in the message if it were reached.
{
	no warnings 'redefine';
	local *Cn::Bioinf::_rcsb_post = sub { die "the network was used\n" };
	my $seq = 'MVLSPADKTNVKAAWGKV';
	my @bad = (
		[[], qr/^pdb_search: needs "seq"/, 'no sequence'],
		[[seq => ['MK']], qr/^pdb_search: "seq" must be a sequence, as a string, not an ARRAY ref/, 'a sequence that is a ref'],
		[[seq => " \n*"], qr/^pdb_search: "seq" has no residues/, 'a sequence of only whitespace and a stop'],
		[[seq => 'MVLS-PADK'], qr/^pdb_search: "seq" has "-" at residue 5, which isn't a residue letter/, 'a gap in the sequence'],
		[[seq => 'MV*LSPADK'], qr/^pdb_search: "seq" has "\*" at residue 3, which isn't a residue letter/, 'a stop that is not at the end'],
		[[seq => $seq, evalue => 0], qr/^pdb_search: "evalue" must be a number above 0, not "0"/, 'an evalue of 0'],
		[[seq => $seq, evalue => 'x'], qr/^pdb_search: "evalue" must be a number above 0, not "x"/, 'an evalue that is not a number'],
		[[seq => $seq, identity => 101], qr/^pdb_search: "identity" must be a percentage, from 0 to 100, not "101"/, 'an identity above 100'],
		[[seq => $seq, identity => -1], qr/^pdb_search: "identity" must be a percentage, from 0 to 100, not "-1"/, 'a negative identity'],
		[[seq => $seq, max_hits => 0], qr/^pdb_search: "max_hits" must be a whole number from 1 to 10000, RCSB's limit, not "0"/, 'a max_hits of 0'],
		[[seq => $seq, max_hits => 10001], qr/^pdb_search: "max_hits" must be a whole number from 1 to 10000, RCSB's limit, not "10001"/, 'a max_hits past RCSB\'s limit'],
		[[seq => $seq, max_hits => 2.5], qr/^pdb_search: "max_hits" must be a whole number from 1 to 10000, RCSB's limit, not "2\.5"/, 'a fractional max_hits'],
		[[seq => $seq, computed => 'yes'], qr/^pdb_search: "computed" must be 0 or 1, not "yes"/, 'a computed of "yes"'],
		[[seq => $seq, type => 'DNA'], qr/^pdb_search: "type" must be protein, dna or rna, not "DNA"/, 'an unknown type'],
		[[seq => $seq, report => 2], qr/^pdb_search: "report" must be 0 or 1, not "2"/, 'a report of 2'],
		[[seq => $seq, timeout => 0], qr/^pdb_search: "timeout" must be a number of seconds above 0, not "0"/, 'a timeout of 0'],
		[[seq => $seq, fasta => 'x.fa'], qr/^pdb_search: doesn't know "fasta"; it takes computed, evalue, identity, max_hits, report, seq, timeout, type/, 'an unknown option'],
	);
	foreach my $case (@bad) {
		my ($args, $re, $name) = @{ $case };
		dies_like sub { pdb_search(@{ $args }) }, $re, "pdb_search: $name dies";
	}
	# the positive sentinel: a good call does get as far as asking RCSB
	dies_like sub { pdb_search(seq => $seq) }, qr/^the network was used/, 'pdb_search: a good call reaches RCSB';
}

# ---- blood_type
#
# It needs none of Alien::Bioinf's programs either. The VCF is a well-formed
# one with none of the panel's markers; the arguments are refused before it is
# opened.
{
	my $vcf = spew('blood_checks.vcf', "##fileformat=VCFv4.2\n##contig=<ID=1,length=249250621>\n"
		. join("\t", '#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT S)) . "\n"
		. join("\t", 1, 100, 'rs1', 'A', 'G', '.', '.', '.', 'GT', '0/1') . "\n");
	my $bam = spew('blood_checks.bam', "not a VCF\n");
	my @bad = (
		[['nowhere.vcf'], qr/^blood_type: "vcf" file "nowhere\.vcf" doesn't exist or isn't readable/, 'a missing file'],
		[[], qr/^blood_type: needs "vcf"/, 'no file'],
		[[{ vcf => $vcf }], qr/^blood_type: takes name => value pairs, not a hash ref/, 'a hash ref'],
		[[vcf => []], qr/^blood_type: "vcf" must be a file name, not an ARRAY ref/, 'a file that is a ref'],
		[[vcf => $vcf, build => 'hg18'], qr/^blood_type: "build" must be hg19, b37, hg38 or b38, not "hg18"/, 'an unknown build'],
		[[vcf => $vcf, min_depth => -1], qr/^blood_type: "min_depth" must be a whole number, 0 or more, not "-1"/, 'a negative min_depth'],
		[[vcf => $vcf, min_depth => '7.5'], qr/^blood_type: "min_depth" must be a whole number, 0 or more, not "7\.5"/, 'a fractional min_depth'],
		[[vcf => $vcf, report => 2], qr/^blood_type: "report" must be 0 or 1, not "2"/, 'a report of 2'],
		[[vcf => $vcf, assume_ref => 'yes'], qr/^blood_type: "assume_ref" must be 0 or 1, not "yes"/, 'an assume_ref that is neither 0 nor 1'],
		[[vcf => $vcf, assume_ref => []], qr/^blood_type: "assume_ref" must be 0 or 1, not an ARRAY ref/, 'an assume_ref that is a ref'],
		[[vcf => $vcf, rhesus => 1], qr/^blood_type: doesn't know "rhesus"; it takes assume_ref, build, min_depth, report, vcf/, 'an unknown option'],
		[[vcf => $bam], qr/^blood_type: "vcf" file \Q$bam\E must end in \.vcf, \.vcf\.gz, \.vcf\.bgz or \.vcf\.bz2/, 'a file whose name says it is not a VCF'],
		[[$vcf, 'report'], qr/^blood_type: "\Q$vcf\E" is the file, so the options after it must be name => value pairs, and are an odd number/, 'a file followed by an option with no value'],
	);
	foreach my $case (@bad) {
		my ($args, $re, $name) = @{ $case };
		dies_like sub { blood_type(@{ $args }) }, $re, "blood_type: $name dies";
	}
	my $nolen = spew('blood_nolen.vcf', "##fileformat=VCFv4.2\n" . join("\t", '#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT S)) . "\n");
	dies_like sub { blood_type(vcf => $nolen, report => 0) },
		qr/^blood_type: "vcf" .* has no ##contig line giving a length for chromosome 1, 15, 16, 20/,
		'blood_type: a header with no length to tell the build by dies';
	# the positive sentinel: a good call reads the file and returns its sample
	my $r = blood_type(vcf => $vcf, report => 0);
	is_deeply [sort keys %{ $r }], ['S'], 'blood_type: a good call returns the file\'s sample';
	# an error raised in Bioinf.xs is given at the caller's line
	my $short = spew('blood_short.vcf', "##fileformat=VCFv4.2\n##contig=<ID=1,length=249250621>\n"
		. join("\t", '#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT S)) . "\n1\t100\trs1\tA\n");
	dies_like sub { blood_type(vcf => $short, report => 0) },
		qr/^vcf_columns: \Q$short\E line 4 has 4 columns, and a record needs 9 and a sample at \Q${\ __FILE__}\E line \d+\.?\n\z/,
		'blood_type: a record cut short dies in the reader, at the caller\'s line';
	# the gene a deletion has to cover is checked before the file is read
	dies_like sub { Cn::Bioinf::_blood_type_tally(sub { undef }, 'x.vcf', 0, [[9, 100, 'T', 0, 'rs1', 0]], 1, 25, 1, 2) },
		qr/^bt_tally_vcf: the gene is chromosome 25, 1 to 2, which isn't a stretch of a chromosome/, 'blood_type: a gene on no chromosome dies';
	dies_like sub { Cn::Bioinf::_blood_type_tally(sub { undef }, 'x.vcf', 0, [[9, 100, 'T', 0, 'rs1', 0]], 1, 1, 9, 2) },
		qr/^bt_tally_vcf: the gene is chromosome 1, 9 to 2, which isn't a stretch of a chromosome/, 'blood_type: a gene that ends before it starts dies';
	dies_like sub { Cn::Bioinf::_blood_type_tally(sub { undef }, 'x.vcf', 0, [[9, 100, 'T', 0, 'rs1', 0]], 1, 1, 1, 2) },
		qr/^vcf_read: x\.vcf has no #CHROM line/, 'blood_type: and a good one gets as far as reading the VCF';
}

# ---- found by review on 2026-11-10; each failed against the code of that day

# sex_check and hirisplex_genotypes compared an undef first argument with 'vcf'
# before asking whether it was defined, and _args then made a hash key of it,
# so each warned "uninitialized" and died of something else.
foreach my $case (
	['sex_check(undef, 1)', sub { sex_check(undef, 1) }, qr/^sex_check: takes name => value pairs, and the name of pair 1 is undef/],
	['hirisplex_genotypes(undef, 1)', sub { hirisplex_genotypes(undef, 1) }, qr/^hirisplex_genotypes: takes name => value pairs, and the name of pair 1 is undef/],
	['sex_check(undef, report => 0)', sub { sex_check(undef, report => 0) }, qr/^sex_check: takes name => value pairs, and was given an odd number of arguments/],
	['parent(child => "C", undef, 1)', sub { parent(child => 'C', undef, 1) }, qr/^parent: takes name => value pairs, and the name of pair 2 is undef/],
) {
	my ($name, $code, $re) = @{ $case };
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	dies_like $code, $re, "$name dies saying what is wrong with its arguments";
	is "@w", '', 'and with no "uninitialized" warning';
}

# A file name that was a reference was used as its text, so that
# plot_msa(filename => []) wrote an image named "ARRAY(0x5ea732db32c8)", and
# "threads" reached clustalo as it was, which refused it under _run's name.
foreach my $case (
	[sub { plot_msa(%two_noq, filename => []) },            qr/^plot_msa: "filename" must be a file name, not an ARRAY ref/],
	[sub { plot_msa(%two_noq, filename => '') },            qr/^plot_msa: "filename" must be a file name, not ""/],
	[sub { plot_msa(%two_noq, 'msa_file' => {}) },          qr/^plot_msa: "msa_file" must be a file name, not a HASH ref/],
	[sub { plot_msa(%two_noq, 'tree_file' => \'t') },       qr/^plot_msa: "tree_file" must be a file name, not a SCALAR ref/],
	[sub { plot_msa(%two_noq, threads => 'many') },         qr/^plot_msa: "threads" must be a whole number, 1 or more, not "many"/],
	[sub { plot_msa(%two_noq, threads => 0) },              qr/^plot_msa: "threads" must be a whole number, 1 or more, not "0"/],
	[sub { plot_phylo(fasta => { a => 'MK', b => 'MV' }, 'output_file' => []) }, qr/^plot_phylo: "output_file" must be a file name, not an ARRAY ref/],
	[sub { plot_phylo(fasta => { a => 'MK', b => 'MV' }, threads => 1.5) },      qr/^plot_phylo: "threads" must be a whole number, 1 or more, not "1\.5"/],
	[sub { msa_quality_table(%q, filename => []) },         qr/^msa_quality_table: "filename" must be a file name, not an ARRAY ref/],
	[sub { view_alignment('msa_file' => $ab, 'output_file' => []) },  qr/^view_alignment: "output_file" must be a file name, not an ARRAY ref/],
	[sub { view_alignment('msa_file' => $ab, 'output_file' => $tex, threads => 'many') },
		qr/^view_alignment: "threads" must be a whole number, 1 or more, not "many"/],
) {
	my ($code, $re) = @{ $case };
	my ($what) = $re =~ /\^(\w+: "\w+")/;
	dies_like $code, $re, "$what is refused before anything runs";
}

# msa_quality_table drew a name in "order" that the report lacks as a row and
# a column of grey cells, drew a number that was not one as 0 after an "isn't
# numeric" warning, and died with perl's own message, naming no function, for
# a report whose parts were of the wrong kind.
foreach my $case (
	[[order => ['A.b', 'E.f']],       qr/^msa_quality_table: "order" names sequences that aren't in the BLAST report: E\.f/, 'a name in "order" that the report lacks'],
	[['cb_min' => 'low'],             qr/^msa_quality_table: "cb_min" must be a number, not "low"/, 'a cb_min that is not a number'],
	[['cb_max' => []],                qr/^msa_quality_table: "cb_max" must be a number, not an ARRAY ref/, 'a cb_max that is a reference'],
	[['default_undefined' => 'NA'],   qr/^msa_quality_table: "default_undefined" must be a number, not "NA"/, 'a default_undefined that is not a number'],
	[['logscale_add' => '1e'],        qr/^msa_quality_table: "logscale_add" must be a number, not "1e"/, 'a logscale_add that is not a number'],
	[[normalize => 'yes'],            qr/^msa_quality_table: "normalize" must be a number, not "yes"/, 'a normalize that is not a number'],
	[['alignment_json' => { BlastOutput2 => ['x'] }], qr/^msa_quality_table: report 1 of "alignment_json" has no report\.results/, 'a report that is not an object'],
	[['alignment_json' => { BlastOutput2 => [{ report => { results => { bl2seq => {} } } }] }],
		qr/^msa_quality_table: report 1 of "alignment_json" has a "bl2seq" that isn't an array, but a HASH ref/, 'a bl2seq that is not an array'],
	[['alignment_json' => { BlastOutput2 => [{ report => { results => { bl2seq => [{ query_title => 'A.b', hits => {} }] } } }] }],
		qr/^msa_quality_table: report 1 of "alignment_json" has a comparison that isn't one/, 'hits that are not an array'],
	[['alignment_json' => { BlastOutput2 => [{ report => { results => { bl2seq => [{ query_title => 'A.b', hits => [1] }] } } }] }],
		qr/^msa_quality_table: report 1 of "alignment_json" has a hit of "A\.b" that isn't one/, 'a hit that is not an object'],
) {
	my ($more, $re, $name) = @{ $case };
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	dies_like sub { msa_quality_table(%q, @{ $more }) }, $re, "msa_quality_table: $name dies";
	is "@w", '', 'and with no warning';
}

# get_best_alignment_hit died with perl's "Not an ARRAY reference" for "hits"
# that was an object, and warned "uninitialized" each time an hsp with no
# bit_score broke a tie.
{
	my $search = sub { qq({"BlastOutput2":[{"report":{"results":{"search":{"query_title":"q","hits":$_[0]}}}}]}) };
	dies_like sub { get_best_alignment_hit(spew('hits_object.json', $search->('{}'))) },
		qr/^get_best_alignment_hit: report 1 of .+hits_object\.json has "hits" that isn't an array, but a HASH ref/, 'get_best_alignment_hit: "hits" that is an object dies';
	dies_like sub { get_best_alignment_hit(spew('hit_number.json', $search->('[1]'))) },
		qr/^get_best_alignment_hit: hit 1 of report 1 of .+hit_number\.json isn't a hit/, 'get_best_alignment_hit: a hit that is a number dies';
	dies_like sub { get_best_alignment_hit(spew('hsps_object.json', $search->('[{"hsps":{}}]'))) },
		qr/^get_best_alignment_hit: hit 1 of report 1 of .+hsps_object\.json isn't a hit/, 'get_best_alignment_hit: "hsps" that is an object dies';
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $got = get_best_alignment_hit(spew('no_bits.json', $search->('[{"len":5,"description":[{"title":"t"}],"hsps":[{"evalue":1,"num":1},{"evalue":1,"num":2}]}]')));
	is_deeply [map { [@{ $_ }{qw(title num evalue)}] } @{ $got->{q} }], [['t', 1, 1]], 'get_best_alignment_hit: of two hsps that tie and have no bit_score, the first is kept';
	is "@w", '', 'and with no "uninitialized" warning';
	$got = get_best_alignment_hit(spew('no_description.json', $search->('[{"len":5,"hsps":[{"evalue":1,"bit_score":2}]}]')));
	is_deeply [@{ $got->{q}[0] }{qw(title id accession descriptions hit_len)}], [undef, undef, undef, [], 5], 'get_best_alignment_hit: a hit with no description has undef names and no descriptions';
	is "@w", '', 'and no warning either';
}

#  the XSUBs that read a VCF, when the reader grows perl's stack
#
# Up to 2026-10-26 each XSUB that reads a VCF through a perl callback pushed
# its results with the stack pointer it took on entry. A callback that grew
# perl's stack moved it, and the results went to freed memory: _vcf_samples
# returned nothing instead of its samples, found by review. Each XSUB is run
# in a child perl, where the stack is still small, once with a reader that
# calls a sub with 2,000,000 arguments (16 MB of stack on a 64-bit perl, which
# glibc's malloc cannot grow in place from its heap, so the stack moves), and
# once with one that does not. The expected value is the second run's: what
# each XSUB counts is tested in t/sex.t, t/parent.t, t/relatedness.t,
# t/concordance.t, t/hirisplex.t and t/blood.t, and this checks only that a
# moved stack does not change it.
{
	my $two = spew('stack.two.vcf', join '', map { join("\t", @{ $_ }) . "\n" }
		['##fileformat=VCFv4.2'],
		['#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT A B)],
		[qw(1 100 rs1 A G . PASS . GT:DP 0/1:30 1/1:30)],
		[qw(1 200 rs2 C T . PASS . GT:DP 0/0:30 0/1:30)],
		[qw(X 5000000 rs3 G A . PASS . GT:DP 1/1:30 0/1:30)]);
	my $one_a = spew('stack.a.vcf', "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tA\n"
		. "1\t100\trs1\tA\tG\t.\tPASS\t.\tGT\t0/1\n");
	my $one_b = spew('stack.b.vcf', "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tB\n"
		. "1\t100\trs1\tA\tG\t.\tPASS\t.\tGT\t1/1\n");
	# The child's reader hands over 16 bytes at a time, so that lines span
	# blocks; $grown is 1 once its first call has grown the stack, for the
	# sentinel.
	my $child = spew('stack.pl', <<'CHILD');
use strict;
use warnings FATAL => 'all';
use Storable ();
use Cn::Bioinf ();
my ($case, $grow, $out, $two, $one_a, $one_b) = @ARGV;
my $grown = 0;
sub deep { scalar @_ }
sub reader {
	my ($file) = @_;
	open my $fh, '<:raw', $file or die "$file: $!";
	sub {
		if ($grow && !$grown) {
			deep((1) x 2_000_000);
			$grown = 1;
		}
		my $n = read $fh, my $block, 16;
		die "$file: $!" unless defined $n;
		$n ? $block : undef;
	};
}
my %call = (
	vcf_samples      => sub { Cn::Bioinf::_vcf_samples(reader($two), $two) },
	sex_tally        => sub { Cn::Bioinf::_sex_tally(reader($two), $two, 0) },
	parent_one       => sub { Cn::Bioinf::_parent_one(reader($two), $two, 0, 'A', 'B') },
	parent_own       => sub { Cn::Bioinf::_parent_own(reader($one_a), $one_a, reader($one_b), $one_b, 0) },
	relatedness_one  => sub { Cn::Bioinf::_relatedness_one(reader($two), $two, 0) },
	relatedness_own  => sub { Cn::Bioinf::_relatedness_own([reader($one_a), reader($one_b)], [$one_a, $one_b], 0) },
	concordance      => sub { Cn::Bioinf::_concordance(reader($two), $two, reader($two), $two, ['A', 'B'], 0, 1) },
	hirisplex_dosage => sub { Cn::Bioinf::_hirisplex_dosage(reader($two), $two, 0, [[1, 100, 'G', 0, 'rs1', 0], [1, 200, 'T', 0, 'rs2', 1]], 2, 0) },
	blood_type_tally => sub { Cn::Bioinf::_blood_type_tally(reader($two), $two, 0, [[1, 100, 'G', 0, 'rs1', 0], [1, 200, 'T', 0, 'rs2', 1]], 2, 1, 50, 150) },
);
my @result = $call{$case}->();
Storable::nstore({ grown => $grown, result => \@result }, $out);
CHILD
	require Storable;
	# each XSUB and how many values it returns
	my @cases = ([vcf_samples => 1], [sex_tally => 3], [parent_one => 12], [parent_own => 12],
		[relatedness_one => 3], [relatedness_own => 3], [concordance => 2], [hirisplex_dosage => 3], [blood_type_tally => 6]);
	foreach my $case (@cases) {
		my ($name, $values) = @{ $case };
		my %run; # 0 = the stack left alone, 1 = grown by the reader
		foreach my $grow (0, 1) {
			my $out = catfile($dir, "stack.$name.$grow");
			my $status = system($^X, @inc, $child, $name, $grow, $out, $two, $one_a, $one_b);
			is $status, 0, "_$name: the child perl exits 0 " . ($grow ? 'with' : 'without') . ' the stack grown';
			$run{$grow} = $status == 0 ? Storable::retrieve($out) : { grown => -1, result => [] };
		}
		is $run{1}{grown}, 1, "_$name: the reader grew the stack";
		is scalar @{ $run{0}{result} }, $values, "_$name: returns $values values";
		is_deeply $run{1}{result}, $run{0}{result}, "_$name: returns the same when the reader grows the stack, rather than losing its results";
	}
}

#  the sequence functions (2026-11-11): the arguments each one refuses

{
	my %with_seq = (
		complement => sub { complement(@_) }, reverse_complement => sub { reverse_complement(@_) }, transcribe => sub { transcribe(@_) },
		back_transcribe => sub { back_transcribe(@_) }, translate => sub { translate(@_) }, translate_six_frames => sub { translate_six_frames(@_) },
		find_orfs => sub { find_orfs(@_) }, gc_content => sub { gc_content(@_) }, kmer_count => sub { kmer_count($_[0], 3) },
		molecular_weight => sub { molecular_weight(@_) }, isoelectric_point => sub { isoelectric_point(@_) },
		protein_charge => sub { protein_charge($_[0], 7) }, subseq => sub { subseq($_[0], 1, 2) }, motif_search => sub { motif_search($_[0], 'ACGT') },
	);
	foreach my $f (sort keys %with_seq) {
		dies_like(sub { $with_seq{$f}->(undef) }, qr/^\Q$f\E: the sequence must be a string, not undef/, "$f: an undef sequence dies");
		dies_like(sub { $with_seq{$f}->(['ACGT']) }, qr/^\Q$f\E: the sequence must be a string, not an ARRAY ref/, "$f: a sequence that is a reference dies");
	}
	# those that take name => value pairs after the sequence
	my %with_options = (
		complement => sub { complement('ACGT', @_) }, reverse_complement => sub { reverse_complement('ACGT', @_) },
		translate => sub { translate('ATGAAA', @_) }, translate_six_frames => sub { translate_six_frames('ATGAAA', @_) },
		find_orfs => sub { find_orfs('ATGAAA', @_) }, gc_content => sub { gc_content('ACGT', @_) }, kmer_count => sub { kmer_count('ACGT', 2, @_) },
		molecular_weight => sub { molecular_weight('ACGT', @_) }, motif_search => sub { motif_search('ACGT', 'CG', @_) },
	);
	foreach my $f (sort keys %with_options) {
		dies_like(sub { $with_options{$f}->(nonesuch => 1) }, qr/^\Q$f\E: doesn't know "nonesuch"; it takes /, "$f: an option it does not have dies");
		dies_like(sub { $with_options{$f}->('type') }, qr/^\Q$f\E: takes name => value pairs, and was given an odd number of arguments/, "$f: an option with no value dies");
		dies_like(sub { $with_options{$f}->({ type => 'DNA' }) }, qr/^\Q$f\E: takes name => value pairs, not a hash ref/, "$f: a hash ref of options dies");
	}
	dies_like(sub { transcribe('ACGT', type => 'RNA') }, qr/^transcribe: takes one argument, the sequence/, 'transcribe: a second argument dies');
	dies_like(sub { back_transcribe('ACGU', 1) }, qr/^back_transcribe: takes one argument, the sequence/, 'back_transcribe: a second argument dies');
	dies_like(sub { isoelectric_point('MK', 7) }, qr/^isoelectric_point: takes one argument, the sequence/, 'isoelectric_point: a second argument dies');
	dies_like(sub { protein_charge('MK', 7, 8) }, qr/^protein_charge: takes two arguments, the sequence and the pH/, 'protein_charge: a third argument dies');
	dies_like(sub { subseq('ACGT', 1, 2, 3) }, qr/^subseq: takes the sequence, where to start and where to end/, 'subseq: a fourth argument dies');
	dies_like(sub { assembly_stats(['ACGT'], 1) }, qr/^assembly_stats: takes one argument, the sequences/, 'assembly_stats: a second argument dies');

	dies_like(sub { complement('ACGT', type => 'protein') }, qr/^complement: "type" must be "DNA" or "RNA", not "protein"/, 'complement: a protein dies');
	dies_like(sub { reverse_complement('ACGT', type => []) }, qr/^reverse_complement: "type" must be "DNA" or "RNA", not an ARRAY ref/, 'reverse_complement: a "type" that is a reference dies');
	dies_like(sub { molecular_weight('ACGT', type => 'lipid') }, qr/^molecular_weight: "type" must be "DNA", "RNA" or "protein", not "lipid"/, 'molecular_weight: a "type" it does not know dies');
	dies_like(sub { molecular_weight('MK', type => 'protein', double_stranded => 1) }, qr/^molecular_weight: a protein has one strand, so "double_stranded" can't be used with it/,
		'molecular_weight: a double-stranded protein dies');
	dies_like(sub { motif_search('ACGT', 'CG', type => 'lipid') }, qr/^motif_search: "type" must be "DNA", "RNA" or "protein", not "lipid"/, 'motif_search: a "type" it does not know dies');
	dies_like(sub { motif_search('MKV', 'KV', type => 'protein', strand => 'both') }, qr/^motif_search: a protein has one strand, so "strand" can only be "\+" with it/,
		'motif_search: the minus strand of a protein dies');
	dies_like(sub { motif_search('ACGT', 'CG', strand => 'up') }, qr/^motif_search: "strand" must be "\+", "-" or "both", not "up"/, 'motif_search: a "strand" it does not know dies');
	dies_like(sub { find_orfs('ATGAAA', strand => 2) }, qr/^find_orfs: "strand" must be "\+", "-" or "both", not "2"/, 'find_orfs: a "strand" it does not know dies');
	foreach my $motif (undef, '', ['ACGT']) {
		dies_like(sub { motif_search('ACGT', $motif) }, qr/^motif_search: the motif must be a string of IUPAC letters or a qr\/\/ pattern, not /,
			'motif_search: a motif that is ' . (!defined $motif ? 'undef' : ref $motif ? 'a reference' : 'empty') . ' dies');
	}
	dies_like(sub { motif_search('ACGT', 'AC.T') }, qr/^motif_search: "\." of the motif "AC\.T" isn't a letter of DNA; a pattern is given as qr\/\//,
		'motif_search: a motif of letters with a "." dies, rather than being read as a pattern');
	dies_like(sub { motif_search('ACGT', 'ACXT') }, qr/"X" of the motif "ACXT" isn't a letter of DNA/, 'motif_search: X in a nucleotide motif dies');
	dies_like(sub { motif_search('MKV', 'M1V', type => 'protein') }, qr/"1" of the motif "M1V" isn't a letter of protein/, 'motif_search: a digit in a protein motif dies');

	foreach my $f (qw(translate translate_six_frames find_orfs)) {
		my $call = $with_options{$f};
		dies_like(sub { $call->(table => 7) }, qr/^\Q$f\E: "table" must be the number or the name of an NCBI genetic code, not "7"; the numbers are 1, 2, 3, 4, 5, 6, 9, 10, 11, /,
			"$f: genetic code 7, which NCBI withdrew, dies");
		dies_like(sub { $call->(table => 'Martian') }, qr/^\Q$f\E: "table" must be the number or the name of an NCBI genetic code, not "Martian"/, "$f: a code's name that is not one dies");
		dies_like(sub { $call->(table => {}) }, qr/^\Q$f\E: "table" must be .*, not a HASH ref/, "$f: a \"table\" that is a reference dies");
	}
	foreach my $t (['stop_symbol', '**'], ['stop_symbol', ''], ['gap', '--'], ['gap', []], ['stop_symbol', "\x{3b1}"]) {
		my ($k, $v) = @{ $t };
		dies_like(sub { translate('ATGAAA', $k => $v) }, qr/^translate: "\Q$k\E" must be one character, below 256, not /, "translate: a \"$k\" that is not one character below 256 dies");
	}
	dies_like(sub { translate_six_frames('ATGAAA', stop_symbol => 'ab') }, qr/^translate_six_frames: "stop_symbol" must be one character/, 'translate_six_frames: a "stop_symbol" of two characters dies');
	# An error that Bioinf.xs raises is placed at the caller's line, as the
	# others are. The period after the line number is optional: Carp wrote none
	# before its 1.25, so perl 5.12.5's does not.
	dies_like(sub { translate('ATGAA?') }, qr/^translate_codons: codon 2, "AA\?", has a letter that isn't a nucleotide's at \Q${\ __FILE__}\E line \d+\.?\n\z/,
		"translate: a bad codon is reported at the caller's line");
	dies_like(sub { find_orfs('ATGAA?TTT') }, qr/^translate_codons: codon 2, "AA\?"/, 'find_orfs: a bad codon dies');
	dies_like(sub { translate_six_frames('ATGAA?') }, qr/^translate_codons: codon 2, "AA\?"/, 'translate_six_frames: a bad codon dies');
	foreach my $v (0, -1, 1.5, 'ten', [10]) {
		dies_like(sub { find_orfs('ATGAAA', min_length => $v) }, qr/^find_orfs: "min_length" must be a whole number, 1 or more, not /, 'find_orfs: a "min_length" of ' . (ref $v ? 'a reference' : $v) . ' dies');
	}
	dies_like(sub { find_orfs('ATGAAA', start => 'atg') }, qr/^find_orfs: "start" must be "any", "ATG" or "code", not "atg"/, 'find_orfs: a "start" it does not know dies');
	dies_like(sub { gc_content('ACGT', ambiguous => 'other string') }, qr/^gc_content: "ambiguous" must be "remove", "ignore" or "weighted", not "other string"/,
		'gc_content: an "ambiguous" it does not know dies');
	foreach my $k (undef, 0, -3, 1.5, 'three', [3], 2147483648, '99999999999') {
		dies_like(sub { kmer_count('ACGT', $k) }, qr/^kmer_count: k must be a whole number from 1 to 2147483647, not /,
			'kmer_count: a k of ' . (!defined $k ? 'undef' : ref $k ? 'a reference' : $k) . ' dies');
	}
	is_deeply kmer_count('ACGT', 2147483647), {}, 'kmer_count: the largest k there is counts nothing in a short sequence';
	foreach my $seqs (undef, 'ACGT', \'ACGT') {
		dies_like(sub { assembly_stats($seqs) }, qr/^assembly_stats: the sequences must be a hash ref, as fasta2hash returns, or an array ref, not /,
			'assembly_stats: sequences that are ' . (!defined $seqs ? 'undef' : ref $seqs ? 'a SCALAR ref' : 'a string') . ' die');
	}
	dies_like(sub { assembly_stats(['ACGT', undef]) }, qr/^assembly_stats: every sequence must be a string, and one is undef/, 'assembly_stats: an undef sequence dies');
	dies_like(sub { assembly_stats({ a => ['ACGT'] }) }, qr/^assembly_stats: every sequence must be a string, and one is an ARRAY ref/, 'assembly_stats: a sequence that is a reference dies');
	dies_like(sub { isoelectric_point('') }, qr/^isoelectric_point: the sequence is empty/, 'isoelectric_point: an empty sequence dies');
	dies_like(sub { protein_charge('', 7) }, qr/^protein_charge: the sequence is empty/, 'protein_charge: an empty sequence dies');
	foreach my $ph (undef, 'neutral', '', [7], 9**9**9, -9**9**9) {
		dies_like(sub { protein_charge('MK', $ph) }, qr/^protein_charge: the pH must be a number, not /,
			'protein_charge: a pH of ' . (!defined $ph ? 'undef' : ref $ph ? 'a reference' : "\"$ph\"") . ' dies');
	}
	foreach my $t ([undef, 2], ['a', 2], [1.5, 2], [1, 'b'], [1, -2], [[1], 2]) {
		dies_like(sub { subseq('ACGT', @{ $t }) }, qr/^subseq: the (?:start|end) must be a whole number, 1 or more, not /, 'subseq: a start or an end that is not a position dies');
	}
	foreach my $file (undef, '', ['x.fa']) {
		my $what = !defined $file ? 'undef' : ref $file ? 'a reference' : 'empty';
		dies_like(sub { fasta_index($file) }, qr/^fasta_index: the FASTA must be a file name, not /, "fasta_index: a file name that is $what dies");
		dies_like(sub { fasta_region($file, 'a') }, qr/^fasta_region: the FASTA must be a file name, not /, "fasta_region: a file name that is $what dies");
	}
	my $fa = spew('regions.fa', ">a\nACGT\n");
	dies_like(sub { fasta_index($fa, 1) }, qr/^fasta_index: takes one argument, the FASTA file/, 'fasta_index: a second argument dies');
	dies_like(sub { fasta_region($fa) }, qr/^fasta_region: needs at least one region, such as "chr1:100-200"/, 'fasta_region: no regions die');
	dies_like(sub { fasta_region($fa, 'a', undef) }, qr/^fasta_region: a region must be a string, such as "chr1:100-200", not undef/, 'fasta_region: an undef region dies');
	dies_like(sub { fasta_region($fa, ['a', 1, 2]) }, qr/^fasta_region: a region must be a string, .*, not an ARRAY ref/, 'fasta_region: a region that is a reference dies');
	ok !-e "$fa.fai", 'and none of those wrote an index';
}

done_testing;
