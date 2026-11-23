require 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);
use Sys::Hostname ();
use Cn::Bioinf qw(:all);
# These run the clustalo, blastp and Python that Alien::Bioinf installed, on
# t/data/DEG20010421.fa (see t/data/make_fixtures.pl). The view_alignment
# expectations are worked out by hand from the 2-sequence alignment below.
# Alien::Bioinf is only recommended, so without a working one this is skipped;
# the argument checks that need none of its programs are in t/checks.t.
unless (eval { require Alien::Bioinf; !grep { !-x $_ } Alien::Bioinf->clustalo, Alien::Bioinf->blast('blastp'), Alien::Bioinf->python }) {
	# the reason up to "(@INC contains: ...", which would fill the screen
	my ($why) = $@ ? $@ =~ /\A(.*?)(?: \(| at .+ line \d|\n|\z)/ : 'no clustalo, blastp or python';
	plan skip_all => "Alien::Bioinf can't run its tools here: $why";
}

my $dir = tempdir(CLEANUP => 1);
my $fa = "$FindBin::Bin/data/DEG20010421.fa";
my $seqs = fasta2hash($fa);
tr/-//d foreach values %{ $seqs };
sub png { open my $fh, '<:raw', $_[0] or return ''; read $fh, my $b, 8; $b }
sub slurp { open my $fh, '<:raw', $_[0] or return ''; local $/; <$fh> }
# the Creator each image's metadata carries, its whole provenance on one line:
# an SVG's <dc:title> in its <dc:creator>, a PNG's tEXt chunk
sub creator { my ($sub, $by) = @_; qr/\Q$FindBin::RealScript\E called using "$sub" in .+Bioinf\.pm version \Q$Cn::Bioinf::VERSION\E with Alien::Bioinf [\d.]+ by user \S.* on host \Q${\ Sys::Hostname::hostname()}\E \(\Q$^O\E\) with Perl [\d.]+ \(\Q$^X\E\), drawn by $by/ }
my $by_py = qr/.+msa_plot\.py with Python [\d.]+\S* \(.+?\), matplotlib [\d.]+/;
my $sha = qr/\(SHA-256 [0-9a-f]{64}\)/;
# what _align_provenance says of an alignment of $fa, by a run of clustalo
# that matched $cmd; the last argument is single-quoted when it holds a space,
# as a TMPDIR may
sub aligned { my ($cmd) = @_; qr/; from the FASTA file \Q$fa\E $sha of 4 sequences, written with its gaps stripped and the sequences numbered s1 to s4 to [^;]+ $sha, which Clustal Omega [\d.]+ from Alien::Bioinf [\d.]+ aligned into [^;]+ $sha \(with the names put back\), run as: [^;]*clustalo --in $cmd'?/ }
# an SVG's metadata, which should hold nothing but the date, format, type and Creator
sub svg_dc { my ($svg) = @_; my ($md) = $svg =~ m{<metadata>(.*?)</metadata>}s; [sort $md =~ /<dc:(\w+)/g] }

# ---- plot_msa and plot_phylo -----------------------------------------------

my %out = map { $_ => catfile($dir, $_) } qw(msa.svg tree.png aln.fa t.newick);
my $r = plot_msa(
	fasta => $fa, filename => $out{'msa.svg'}, 'msa_file' => $out{'aln.fa'}, 'tree_file' => $out{'t.newick'},
	title => 'DEG20010421', 'active_site_aa' => { Lys100 => 100 }, query => 'S.cerevisiae',
	labels => { 'S.cerevisiae' => '$\it{S. cerevisiae}$' },
);
like $r->{'python_file'}, qr/\.py\z/, 'plot_msa returns the script that drew the image';
is_deeply $r, { filename => $out{'msa.svg'}, 'msa_file' => $out{'aln.fa'}, 'tree_file' => $out{'t.newick'}, 'python_file' => $r->{'python_file'} },
	'plot_msa, a file in: every output named';
my $aln = fasta2hash($out{'aln.fa'});
is_deeply [sort keys %{ $aln }], [sort keys %{ $seqs }], 'the alignment has every sequence';
is scalar(keys %{ { map { length $_ => 1 } values %{ $aln } } }), 1, 'all of one length';
is_deeply { map { (my $s = $aln->{$_}) =~ tr/-//d; $_ => uc $s } keys %{ $aln } }, $seqs, 'and gapped copies of the input';
ok -s $out{'msa.svg'} && do { open my $fh, '<', $out{'msa.svg'}; local $/; <$fh> =~ /<svg/ }, 'an SVG alignment image';
my $msa_svg = slurp($out{'msa.svg'});
like $msa_svg, creator('plot_msa', $by_py . qr/; titled "DEG20010421"/ . aligned(qr/.*--guidetree-out=\Q$out{'t.newick'}\E/)
	. qr/; kept with it: msa_file \Q$out{'aln.fa'}\E, tree_file \Q$out{'t.newick'}\E<\/dc:title>/),
	'whose Creator names this script, the sub, the versions, the user, the host, Python, matplotlib, the title, the alignment and the files kept';
is_deeply svg_dc($msa_svg), [qw(creator date format title type)], 'and that is all its metadata, as from Matplotlib::Simple';
open my $nw, '<', $out{'t.newick'} or die $!;
like do { local $/; <$nw> }, qr/S\.cerevisiae:[\d.]+/, 'the guide tree is newick with the sequence names';
close $nw;

$r = plot_phylo('tree_file' => $out{'t.newick'}, 'output_file' => $out{'tree.png'}, title => 'DEG20010421',
	labels => { 'S.cerevisiae' => '$\it{S. cerevisiae}$' });
is_deeply $r, { 'output_file' => $out{'tree.png'}, 'tree_file' => $out{'t.newick'}, 'python_file' => $r->{'python_file'} },
	'plot_phylo draws the tree plot_msa kept';
is png($out{'tree.png'}), "\x89PNG\r\n\x1a\n", 'a PNG tree image';
my $tree_png = slurp($out{'tree.png'});
like $tree_png, creator('plot_phylo', $by_py . qr/, Biopython [\d.]+, NumPy [\d.]+; titled "DEG20010421"; from the newick file \Q$out{'t.newick'}\E $sha/
	. qr/; 4 tips: [^;]*S\.cerevisiae \(shown as \$\\it\{S\. cerevisiae\}\$\)[^;]*; the tree as drawn, in newick: \(\S*S\.cerevisiae:[\d.]+\S*\);/),
	'and its Creator, which names Biopython and NumPy, the title, the newick file with its digest, the tips with their labels and the newick';
unlike $tree_png, qr/(?:Source|Description|Title)\0/, 'and no other text chunks of provenance';

$r = plot_msa(fasta => $seqs, filename => catfile($dir, 'h.png'), order => ['S.cerevisiae', 'C.neoformans.JEC21']);
is_deeply [sort keys %{ $r }], ['filename', 'msa_file', 'python_file'], 'plot_msa, a hash in: the image and a temporary alignment';
is png($r->{filename}), "\x89PNG\r\n\x1a\n", 'a PNG, drawing only the sequences in "order"';

$r = plot_phylo(fasta => $seqs, 'output_file' => catfile($dir, 'p.png'));
is_deeply [sort keys %{ $r }], ['msa_file', 'output_file', 'python_file'], 'plot_phylo, a hash in: it aligns, and the tree is temporary';
is png($r->{'output_file'}), "\x89PNG\r\n\x1a\n", 'a PNG tree image from the sequences';

# "fh" and "execute", as Matplotlib::Simple's plt takes them: plot_msa and
# plot_phylo append to one File::Temp with "execute => 0", and the last call,
# which runs it, draws both images.
{
	require File::Temp;
	my $fh = File::Temp->new(DIR => $dir, SUFFIX => '.py');
	my ($msa, $tree) = map { catfile($dir, $_) } ('fh msa.svg', 'fh tree.png');
	my $nwk = catfile($dir, 'fh.newick');
	$r = plot_msa(fasta => $fa, filename => $msa, 'tree_file' => $nwk, fh => $fh, execute => 0);
	is $r->{'python_file'}, $fh->filename, 'plot_msa with "fh": returns its file name';
	ok -s $fh->filename && !-e $msa, 'and has written the script, but not run it';
	like slurp($fh->filename), qr/\A# plot_msa, from Cn::Bioinf \Q$Cn::Bioinf::VERSION\E: msa_plot\.py run/, 'which says where it came from';
	$r = plot_phylo('tree_file' => $nwk, 'output_file' => $tree, fh => $fh);
	is $r->{'python_file'}, $fh->filename, 'plot_phylo with the same "fh"';
	like slurp($msa), qr/<svg/, 'runs the script, which draws plot_msa\'s image';
	like slurp($msa), creator('plot_msa', $by_py . qr/; untitled/ . aligned(qr/.*--guidetree-out=\Q$nwk\E/)), 'with its Creator';
	is png($tree), "\x89PNG\r\n\x1a\n", 'and its own';
	unlike slurp($fh->filename), qr/\Q$dir\E/, 'and no path is pasted into the Python';

	# The script carries its inputs, so that it still draws once perl has
	# removed the temporary alignment that it was written from.
	my $later = catfile($dir, 'later.png');
	my $said = catfile($dir, 'said.txt');
	{
		open my $saved, '>&', \*STDOUT or die $!;
		open STDOUT, '>', $said or die $!;
		$r = plot_msa(fasta => $seqs, filename => $later, execute => 0);
		open STDOUT, '>&', $saved or die $!;
	}
	# Read in text mode, as STDOUT wrote it: on Windows each "\n" printed is
	# "\r\n" in the file, which slurp, being :raw, would hand back as it is.
	open my $said_fh, '<', $said or die "$said: $!";
	is do { local $/; <$said_fh> }, "will write $later\n", 'it says the image will be written, not that it was';
	close $said_fh;
	my $kept = $r->{'python_file'};
	ok -s $kept && !-e $later, 'plot_msa with "execute => 0" and no "fh": a script kept, and not run';
	unlink $r->{'msa_file'} or die "can't remove $r->{'msa_file'}: $!";
	is system(Alien::Bioinf->python, '-I', $kept), 0, 'which runs on its own, without the alignment it was made from';
	is png($later), "\x89PNG\r\n\x1a\n", 'and draws the image';
	unlink $kept;
}

# "output_file" defaults to phylo.svg, in the working directory
{
	require Cwd;
	require Digest::SHA;
	my $was = Cwd::getcwd();
	chdir $dir or die "can't chdir to $dir: $!";
	my $keep = catfile($dir, 'kept.newick');
	$r = plot_phylo(fasta => $fa, 'tree_file' => $keep, title => 'DEG20010421');
	chdir $was or die "can't chdir back to $was: $!";
	is_deeply [sort keys %{ $r }], ['msa_file', 'output_file', 'python_file', 'tree_file'], 'plot_phylo with no "output_file"';
	is $r->{'output_file'}, 'phylo.svg', 'reports phylo.svg';
	my $svg = slurp(catfile($dir, 'phylo.svg'));
	like $svg, qr/<svg/, 'and writes it';
	my $nw_sha = Digest::SHA->new(256)->addfile($keep, 'b')->hexdigest;
	like $svg, creator('plot_phylo', $by_py . qr/, Biopython [\d.]+, NumPy [\d.]+; titled "DEG20010421"/ . aligned(qr/.*--guidetree-out=\Q$keep\E/)
		. qr/; drawing the guide tree it wrote, \Q$keep\E \(SHA-256 $nw_sha\); kept with it: tree_file \Q$keep\E; 4 tips: [^;]+; the tree as drawn, in newick: \(\S+\);<\/dc:title>/),
		'whose Creator names the FASTA, the ungapped copy, the alignment and the tree, each with its digest, the clustalo command, the tree kept, the tips and the newick';
	is_deeply svg_dc($svg), [qw(creator date format title type)], 'and that is all its metadata';
	unlike $svg, qr{<dc:title>DEG20010421</dc:title>}, 'with no Title beside the Creator';
}

# Up to 2026-10-17 the names went to clustalo as they were: it cut each at its
# first space in the guide tree and wrote "(),:" unquoted, so these 4
# sequences were drawn as the 5 tips "four, Candida, Candida, three, y".
{
	my @k = sort keys %{ $seqs };
	my %odd = ('Candida albicans' => $seqs->{ $k[0] }, 'Candida auris' => $seqs->{ $k[1] }, 'three,y' => $seqs->{ $k[2] },
		"it's (x:1)" => $seqs->{ $k[3] });
	my ($nwk, $odd_aln, $svg) = map { catfile($dir, $_) } qw(odd.newick odd.aln.fa odd.svg);
	plot_msa(fasta => \%odd, filename => catfile($dir, 'odd.png'), 'msa_file' => $odd_aln, 'tree_file' => $nwk);
	my $kept = fasta2hash($odd_aln);
	is_deeply [sort keys %{ $kept }], [sort keys %odd], 'the alignment kept has the names as they were given, spaces and all';
	is_deeply { map { (my $s = $kept->{$_}) =~ tr/-//d; $_ => uc $s } keys %{ $kept } }, { map { $_ => uc $odd{$_} } keys %odd },
		'each under its own name';
	like slurp($nwk), qr/\A(?=.*^'Candida albicans':)(?=.*^'Candida auris':)(?=.*^'three,y':)(?=.*^'it''s \(x:1\)':)/ms,
		'and the tree has them quoted as newick quotes them';
	plot_phylo('tree_file' => $nwk, 'output_file' => $svg, labels => { 'Candida auris' => 'C. auris' });
	my $apos = qr/(?:'|&apos;|&#39;)/;
	like slurp($svg), qr/; 4 tips: (?=[^;]*Candida albicans)(?=[^;]*Candida auris \(shown as C\. auris\))(?=[^;]*three,y)(?=[^;]*it${apos}s \(x:1\))/,
		'which are drawn as 4 tips, not 5, under those names and that label';
}

# Up to 2026-10-17 a label was written into the FASTA that msa_plot.py reads
# as Latin-1 or as UTF-8 by how perl happened to hold it, and Python, which
# reads UTF-8, died on the Latin-1 "caf\xe9".
ok eval { plot_msa(fasta => $seqs, filename => catfile($dir, 'u.png'), labels => { 'S.cerevisiae' => "caf\x{e9}", 'C.neoformans.JEC21' => "\x{3b2}-tub" }); 1 },
	'labels with an e-acute and a beta are drawn, rather than Python dying' or diag $@;

foreach my $f ([\&plot_msa, 'filename'], [\&plot_phylo, 'output_file']) {
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	is_deeply $f->[0]->(fasta => { a => 'MKV' }, $f->[1] => catfile($dir, 'one.png')), {}, 'one sequence: nothing made';
	like $w[0], qr/clustalo needs at least 2 sequences, and there is only 1/, 'and a warning says why';
}
my %two = (fasta => $seqs, filename => catfile($dir, 'x.png'));
foreach my $bad (
	[{ %two, fasta => [] }, qr/"fasta" must be a FASTA file name or a hash ref/],
	[{ %two, colour => 1 }, qr/doesn't know "colour"/],
	[{ fasta => $seqs }, qr/needs "filename"/],
	[{ filename => 'x.png' }, qr/needs "fasta"/],
	[{ %two, 'active_site_aa' => { X => 1 } }, qr/needs "query" to place "active_site_aa"/],
	[{ %two, 'active_site_aa' => { X => 1 }, query => 'nope' }, qr/the query "nope" isn't in the alignment/],
	[{ %two, 'active_site_aa' => { X => 9999 }, query => 'S.cerevisiae' }, qr/active site X \(9999\) is past the end of "S.cerevisiae", which has 713 residues/],
	[{ %two, order => ['nope'] }, qr/"order" names sequences that aren't in the alignment: nope/],
	[{ %two, labels => { 'C.neoformans.JEC21' => 'S.cerevisiae' } }, qr/"C.neoformans.JEC21", "S.cerevisiae" would all be drawn as "S.cerevisiae"/],
) {
	eval { plot_msa(%{ $bad->[0] }) };
	like $@, $bad->[1], "plot_msa dies: $bad->[1]";
}
# "tooltips": one <title> per residue of the 4 sequences of $fa, which are 142,
# 142, 142 and 713 residues long; S.cerevisiae's 100th is N (Asn), and its
# column is read from the alignment the same call keeps.
my ($tips_svg, $tips_aln) = (catfile($dir, 'tips.svg'), catfile($dir, 'tips.aln.fa'));
plot_msa(fasta => $fa, filename => $tips_svg, 'msa_file' => $tips_aln, tooltips => 1, labels => { 'S.cerevisiae' => '$\it{S. cerevisiae}$' });
my $tips = slurp($tips_svg);
my @titles = $tips =~ m{<g id="cnbtip[0-9]+" pointer-events="all"><title>([^<]*)</title>}g;
is scalar(@titles), 3 * 142 + 713, 'plot_msa with "tooltips": a tooltip on every residue, and none on a gap';
like $tips, qr/; a tooltip on each of its 1139 residues/, 'which the Creator says';
my $sc = fasta2hash($tips_aln)->{'S.cerevisiae'};
my $col = do { my $n = 0; my $c = 0; foreach (split //, $sc) { $c++; last if $_ ne '-' && ++$n == 100 } $c };
ok scalar(grep { $_ eq "S.cerevisiae: Asn100, alignment column $col" } @titles), "naming the sequence as given, not its label, the residue, its number and its column ($col)";
unlike $msa_svg, qr/<title>|cnbtip/, 'whereas without "tooltips" there are none';

foreach my $bad (
	[{ 'output_file' => 'x.png' }, qr/needs "fasta" to align, or "tree_file" to draw/],
	[{}, qr/needs "fasta" to align, or "tree_file" to draw/],
	[{ 'output_file' => 'x.png', 'tree_file' => catfile($dir, 'none.newick') }, qr/none\.newick" doesn't exist/],
	[{ 'output_file' => 'x.png', 'tree_file' => $out{'t.newick'}, threads => 2 }, qr/was given "threads" but no "fasta" to align/],
	[{ fasta => $seqs, 'output_file' => 'x.png', order => [] }, qr/doesn't know "order"/],
	[{ fasta => $seqs, filename => 'x.png' }, qr/doesn't know "filename"/],
) {
	eval { plot_phylo(%{ $bad->[0] }) };
	like $@, $bad->[1], "plot_phylo dies: $bad->[1]";
}
foreach my $f (\&plot_msa, \&plot_phylo, \&msa_quality_table) {
	eval { $f->('x') };
	like $@, qr/takes name => value pairs, and was given an odd number of arguments/, 'dies on an odd number of arguments';
	eval { $f->({ %two }) };
	like $@, qr/takes name => value pairs, not a hash ref/, 'dies on a hash ref';
}

# ---- msa_quality_table ------------------------------------------------------

my $unaligned = hash2fasta_file($seqs, catfile($dir, 'u.fa'));
my $json = catfile($dir, 'all.json');
my $img = catfile($dir, 'q.png');
is msa_quality_table(fasta => $fa, filename => $img), $img, 'a FASTA file in: blastp is run, into a temporary report';
is png($img), "\x89PNG\r\n\x1a\n", 'a PNG table';
unlink $img;
msa_quality_table(fasta => $aln, filename => $img);
is png($img), "\x89PNG\r\n\x1a\n", 'an aligned hash in: its gaps are stripped for blastp';
unlink $img;
is msa_quality_table('alignment_json' => $json, 'unaligned_fa' => $unaligned, filename => $img, metric => 'bit_score'), $img,
	'blastp is run when "alignment_json" does not exist yet, on "unaligned_fa", the old name for "fasta"';
ok -s $json, 'and its report kept';
is png($img), "\x89PNG\r\n\x1a\n", 'a PNG table';
like slurp($img), creator('msa_quality_table', $by_py . qr/; untitled; showing each pair's "bit_score"; from the FASTA file \Q$unaligned\E $sha of \d+ sequences, written with its gaps stripped to [^;]+ $sha, which blastp [\d.]+ from Alien::Bioinf [\d.]+ compared all against all into \Q${\ File::Spec->rel2abs($json)}\E $sha, run as: [^;]*blastp[^;]*; kept with it: alignment_json \Q${\ File::Spec->rel2abs($json)}\E/),
	'and its Creator, with the FASTA, the blastp command and the report kept';
unlink $img;
msa_quality_table('alignment_json' => $json, filename => $img, normalize => 1, order => [sort keys %{ $seqs }]);
is png($img), "\x89PNG\r\n\x1a\n", 'the existing report is read';
unlink $img;
msa_quality_table('alignment_json' => $json, filename => $img, normalize => 1, cblogscale => 1);
is png($img), "\x89PNG\r\n\x1a\n", 'normalize and cblogscale together: a log scale from the smallest value above 0 to 1';
# Up to 2026-10-17 the title went to Python through encode_json, which read its
# UTF-8 as Latin-1, so "caf\xc3\xa9" was drawn as "caf\xc3\x83\xc2\xa9".
{
	my $svg = catfile($dir, 'q.svg');
	msa_quality_table('alignment_json' => $json, filename => $svg, title => "caf\xc3\xa9");
	like slurp($svg), qr/; titled "caf\xc3\xa9";/, 'a UTF-8 title reaches the image as itself, rather than encoded twice';
}
foreach my $bad (
	[{ filename => $img }, qr/needs "fasta" to align, or an existing "alignment_json"/],
	[{ filename => $img, fasta => $fa, 'unaligned_fa' => $fa }, qr/both "fasta" and "unaligned_fa"/],
	[{ filename => $img, fasta => [] }, qr/"fasta" must be a FASTA file name or a hash ref/],
	[{ filename => $img, 'alignment_json' => $json, metric => 'hseq' }, qr/"hseq" isn't one of the metrics/],
	[{ filename => $img, 'alignment_json' => catfile($dir, 'new.json') }, qr/needs "fasta" to align, or an existing "alignment_json" \(.+new\.json doesn't exist yet\)/],
	# a sequence the report holds: since 2026-11-10 a name in "order" that it
	# lacks, as "nodot" was here, dies of that first (t/checks.t)
	[{ filename => $img, 'alignment_json' => { BlastOutput2 => [{ report => { results => { bl2seq => [{ query_title => 'nodot',
		hits => [{ description => [{ title => 'nodot' }], hsps => [{ score => 1 }] }] }] } } }] } }, qr/can't get a genus and species from "nodot"/],
	[{ filename => $img, 'alignment_json' => $json, order => ['nodot'] }, qr/"order" names sequences that aren't in the BLAST report: nodot/],
) {
	eval { msa_quality_table(%{ $bad->[0] }) };
	like $@, $bad->[1], "dies: $bad->[1]";
}

# ---- view_alignment ---------------------------------------------------------

# a: M K - L V   residues 1 2 . 3 4
# b: M - Q L V
# Residue 2 of a is column 1 and residue 3 is column 3; 3 columns per block.
my $tex = catfile($dir, 'r.tex');
my $ab = hash2fasta_file({ a => 'MK-LV', b => 'M-QLV' }, catfile($dir, 'ab.aln.fa'));
my %view = ('msa_file' => $ab, 'output_file' => $tex, 'return_only' => 1, 'row_width' => 3, track => 'a',
	'color_residues' => { a => { 2 => 'red', 3 => [1, 0, 0] } });
sub body { open my $fh, '<', $_[0] or die $!; <$fh>; local $/; <$fh> } # all but the provenance line
my $rows = <<'EOT';
\textit{a} & \texttt{M\textcolor{red}{K}-} & 2
\\
\textit{a} track & \texttt{-2-} & 2
\\
\textit{b} & \texttt{M\textcolor{red}{-}Q} & 2
\\
\hline
\textit{a} & \texttt{{\color[rgb]{1,0,0}L}V} & 4
\\
\textit{a} track & \texttt{3-} & 4
\\
\textit{b} & \texttt{{\color[rgb]{1,0,0}L}V} & 4
\\
\hline
EOT
my $head = "\\begin{table}[htp]\\footnotesize\n\\begin{tabular}{|c|l|c|} \\hline\n\\textbf{Track} & \\textbf{Sequence} & \\textbf{Length}\\\\ \\hline\n";
like view_alignment(%view), qr/^a  +MK-  2$/m, 'returns the alignment as text';
is body($tex), "$head$rows\\end{tabular}\n\\caption{}\n\\end{table} \\FloatBarrier\n", 'one table, coloured and tracked';
my @rows = split /(?<=\\hline\n)/, $rows;
view_alignment(%view, split => 1, caption => 'C', label => 'L');
is body($tex), "$head$rows[0]\\end{tabular}\n\\caption{C}\n\\label{tab:L0}\n\\end{table} \\FloatBarrier\n"
	. "$head$rows[1]\\end{tabular}\n\\caption{C (continued)}\n\\label{tab:L1}\n\\end{table} \\FloatBarrier\n", 'split into one block per table';
view_alignment(%view, 'msa_file' => $out{'aln.fa'}, 'color_residues' => {}, track => undef, 'row_width' => 100);
like body($tex), qr/^\\textit\{S\.cerevisiae\} & \\texttt\{\Q${\ substr($aln->{'S.cerevisiae'}, 0, 100)}\E\} & \d+$/m,
	'plot_msa\'s alignment is shown as it is';
my $before = slurp($unaligned);
like view_alignment(%view, 'msa_file' => $unaligned, 'color_residues' => {}, track => undef, 'row_width' => 1e5), qr/, aligned by Clustal Omega/, # 1 block, so every row is the full width
	'sequences of different lengths are aligned rather than dying';
my @shown = body($tex) =~ /^\\textit\{[^}]+\} & \\texttt\{([^}]*)\}/mg;
ok @shown && (grep { /-/ } @shown) && !(grep { length $_ != length $shown[0] } @shown), 'into gapped rows of one width';
is slurp($unaligned), $before, 'and "msa_file" is left as it was';
# the provenance of what view_alignment writes itself, which names
# Alien::Bioinf only in the clause that says how clustalo aligned it
my $own = qr/\Q$FindBin::RealScript\E called using "view_alignment" in .+Bioinf\.pm version \Q$Cn::Bioinf::VERSION\E by user \S.* on host \Q${\ Sys::Hostname::hostname()}\E \(\Q$^O\E\) with Perl [\d.]+ \(\Q$^X\E\), written as /;
{
	open my $fh, '<', $tex or die $!;
	my $first = <$fh>;
	# joined qr// objects are a string, which like() refuses, until compiled again
	my $tex_prov = qr/^% .*$own\QLaTeX by \E.+Bioinf\.pm itself; from the FASTA file \Q$unaligned\E $sha of 4 sequences, .+ which Clustal Omega [\d.]+ from Alien::Bioinf [\d.]+ aligned into [^;]+/
		. qr/; showing 4 of 4 sequences in blocks of 100000 columns, coloring 0 columns$/;
	like $first, qr/$tex_prov/, 'the LaTeX\'s first line is its provenance, with the clustalo run';
	my $svg = catfile($dir, 'view.svg');
	view_alignment($fa, 'output_file' => $svg, 'return_only' => 1, 'row_width' => 60, track => 'S.cerevisiae',
		'color_residues' => { 'S.cerevisiae' => { 3 => 'red' } });
	my $body = slurp($svg);
	my $svg_prov = qr{<dc:title>[^<]*$own\QSVG by \E.+Bioinf\.pm itself} . aligned(qr/.*--threads 1/)
		. qr{; showing 4 of 4 sequences in blocks of 60 columns, tracking S\.cerevisiae, coloring 1 column</dc:title>};
	like $body, qr/$svg_prov/, 'and an SVG\'s, in its <dc:creator>, from a FASTA file given first';
	is_deeply svg_dc($body), [qw(creator title)], 'which is all the metadata it has';
}
foreach my $bad (
	[{ %view, track => 'z' }, qr/tracker "z" isn't in the alignment/],
	[{ %view, 'color_residues' => { z => {} } }, qr/names proteins that aren't in the alignment: z/],
	[{ %view, 'color_residues' => { a => { 9 => 'red' } } }, qr/a has no residue 9/],
	[{ %view, 'color_residues' => { a => { 1 => [1, 0] } } }, qr/the color of a residue 1 must be one of xcolor's base colors \(.+\) or \[r, g, b\], each 0 to 1, not an ARRAY ref/],
	[{ %view, order => ['z'] }, qr/"order" names proteins that aren't in the alignment: z/],
	[{ %view, 'msa_file' => catfile($dir, 'none.fa') }, qr/the FASTA file .+none\.fa doesn't exist/],
	[{ %view, fasta => $ab }, qr/doesn't know "fasta"/],
	[{ %view, alignment => '\\centering' }, qr/doesn't know "alignment"/],
	[{ 'output_file' => $tex }, qr/needs an alignment, first or as "msa_file"/],
) {
	eval { view_alignment(%{ $bad->[0] }) };
	like $@, $bad->[1], "dies: $bad->[1]";
}

# A title, label or file name that starts with "-" reaches msa_plot.py as the
# value of its option. argparse used to read it as an option instead and exit
# 2 ("argument --t: expected one argument"), once clustalo had run.
{
	my $svg = catfile($dir, '-dash.svg');
	my $r = eval { plot_msa(fasta => $fa, filename => $svg, title => '-log10', xlabel => '-x', ylabel => '--t') };
	is $@, '', 'plot_msa: a title "-log10", an xlabel "-x" and a ylabel "--t" do not die';
	like slurp($svg), qr/<svg.*titled "-log10"/s, 'plot_msa: and the image is written, titled as it was asked';
	my $png = catfile($dir, '-tree.png');
	eval { plot_phylo(fasta => $fa, 'output_file' => $png, title => '--l') };
	is $@, '', 'plot_phylo: a title "--l" does not die';
	is png($png), "\x89PNG\r\n\x1a\n", 'plot_phylo: and the image is written';
}
done_testing;
