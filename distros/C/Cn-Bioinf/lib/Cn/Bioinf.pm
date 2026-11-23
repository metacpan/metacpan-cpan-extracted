package Cn::Bioinf;
# ABSTRACT: FASTA I/O in XS, BLAST hit ranking, and alignment plots and tables
#
# Taken from ~/Scripts/bioinf.pm (as it stood on 2026-08-19): fasta2hash,
# get_best_alignment_hit, hash2fasta_file, msa_quality_table, msa_phylo_plot and
# clustal_view_residues (now view_alignment, since 2026-11-16, which also shows
# the alignment in the terminal and draws it as an SVG). fasta2hash and
# hash2fasta_file are now XS (Bioinf.xs).
# msa_phylo_plot is now plot_msa and plot_phylo, and no longer takes a BLAST
# report and a proteome database: each is given the sequences, aligns them with
# Clustal Omega and draws the result itself, with share/msa_plot.py (from
# ~/Scripts/HitList/scripts/x.my.align.py) in place of that script and of the
# R/ggtree tree. msa_quality_table's table is drawn by that script too, where
# bioinf.pm had Matplotlib::Simple's colored_table draw it. clustalo, blastp and
# that Python all come from Alien::Bioinf, never from PATH. Alien::Bioinf is only
# recommended, not required, since it cannot be installed everywhere (NCBI
# builds BLAST+ for few platforms) and fasta2hash, hash2fasta_file and
# get_best_alignment_hit do not need it; the functions that do load it through
# _alien, which says what is missing.
#
# concordance is ~/Scripts/old/x.low_ram_local_concordance.pl (as it stood on
# 2026-10-19) made a function of two VCFs: its 45 kinds of comparison and its
# metrics are counted in Bioinf.xs, whose comments above CONC_NAME and CONC_TP
# say where it departs from that script; its XLSX, JSON and ACMG59 output are
# not made.
require 5.012;
use strict;
use warnings;
use Carp qw(croak carp);
use File::Spec;
use Sys::Hostname 'hostname';
use Exporter 'import';
use XSLoader;
our $VERSION = '0.031';
our @EXPORT_OK = qw(
	admixture assembly_stats back_transcribe blood_type complement concordance fasta2hash fasta_index
	fasta_region find_orfs fst gc_content get_best_alignment_hit gwas hardy_weinberg hash2fasta_file hirisplex_genotypes
	isoelectric_point kmer_count ld ld_prune molecular_weight motif_search msa_quality_table parent pca pdb_search
	pgs_score plot_msa plot_phylo protein_charge relatedness reverse_complement sex_check subseq trait_predict transcribe translate
	translate_six_frames view_alignment
);
# Nothing is in @EXPORT: a caller names what it wants, or asks for ":all".
our %EXPORT_TAGS = (all => \@EXPORT_OK);
XSLoader::load('Cn::Bioinf', $VERSION);
# The calling script's full path, for _creator. It is looked up at load time,
# as FindBin always does, but FindBin croaks when $0 is not a file on disk
# (after $0 is assigned to, or under an embedder), and that must not stop this
# module loading, so $0 made absolute stands in then. Up to 2026-10-17 this was
# the script's file name alone, which _creator joined to the working directory,
# so a script run from another directory was recorded at a path that wasn't it.
my $Script = eval { require FindBin; File::Spec->catfile($FindBin::RealBin, $FindBin::RealScript) } // File::Spec->rel2abs($0);

# ---- private helpers

# The name => value pairs in @$list as a hash ref. Dies unless they hold every
# @$required key and nothing outside @$required and @$optional. Its messages
# are prefixed with $sub, the public function whose arguments they are, not
# with "_args".
sub _args {
	my ($list, $sub, $required, $optional) = @_;
	croak "$sub: takes name => value pairs, not a hash ref" if @{ $list } == 1 && ref $list->[0] eq 'HASH';
	croak "$sub: takes name => value pairs, and was given an odd number of arguments" if @{ $list } % 2;
	# an undef name would only warn, as a hash key, and then be reported as ""
	my ($nameless) = grep { !defined $list->[2 * $_] } 0 .. @{ $list } / 2 - 1;
	croak "$sub: takes name => value pairs, and the name of pair " . ($nameless + 1) . ' is undef' if defined $nameless;
	my $args = { @{ $list } };
	my @missing = grep { !defined $args->{$_} } @{ $required };
	croak "$sub: needs " . join(', ', map { "\"$_\"" } @missing) if @missing;
	my %ok = map { $_ => 1 } @{ $required }, @{ $optional };
	my @bad = sort grep { !$ok{$_} } keys %{ $args };
	croak "$sub: doesn't know " . join(', ', map { "\"$_\"" } @bad) . '; it takes ' . join(', ', sort keys %ok) if @bad;
	$args;
}

# $v as a message names it: "a HASH ref", "an ARRAY ref", "undef", or the
# string quoted.
sub _what {
	my ($v) = @_;
	return 'undef' unless defined $v;
	ref $v ?(ref($v) =~ /\A[AEIOU]/ ? 'an ' : 'a ') . ref($v) . ' ref' : "\"$v\"";
}

# Dies unless each of @keys of $args that was given is a $type ('ARRAY' or
# 'HASH') ref, naming $sub, the public function whose arguments they are. Up to
# 2026-10-17 a wrong one died with perl's own "Not an ARRAY reference", naming
# no function, and often only once clustalo had run.
sub _refs {
	my ($sub, $args, $type, @keys) = @_;
	foreach my $k (@keys) {
		next if !defined $args->{$k} || ref $args->{$k} eq $type;
		croak "$sub: \"$k\" must be " . ($type eq 'ARRAY' ? 'an array' : 'a hash') . ' ref, not ' . _what($args->{$k});
	}
}

# Dies unless each of @keys of $args that was given is a file name: a string
# that is not empty, naming $sub, the public function whose arguments they are.
# Up to 2026-11-10 a reference was used as its text, so that
# plot_msa(filename => []) wrote an image named "ARRAY(0x5ea732db32c8)".
sub _file_names {
	my ($sub, $args, @keys) = @_;
	foreach my $k (@keys) {
		next unless defined $args->{$k};
		croak "$sub: \"$k\" must be a file name, not " . _what($args->{$k}) if ref $args->{$k} || $args->{$k} eq '';
	}
}

# Dies unless "threads" of $sub's $args, clustalo's --threads, is a whole
# number, 1 or more, or was not given. Up to 2026-11-10 anything else reached
# clustalo, which refused it under _run's name once the sequences were written.
sub _threads {
	my ($sub, $args) = @_;
	croak "$sub: \"threads\" must be a whole number, 1 or more, not " . _what($args->{threads})
		if defined $args->{threads} && (ref $args->{threads} || $args->{threads} !~ /\A[1-9][0-9]*\z/);
}

# The error that Bioinf.xs's croak() ends with when it is raised in this file,
# which is where every XSUB is called from; compiled once, since perl 5.32
# leaks a pattern that is compiled at run time.
my $Located_here = qr/ at \Q${\ __FILE__}\E line [0-9]+\.\n\z/;

# What $code, a call of one of Bioinf.xs's XSUBs, returns, in list context. An
# error that Bioinf.xs raised is raised again at the caller's line, as croak
# raises this file's own: C's croak() gives the line of this file that called
# the XSUB, which up to 2026-11-10 was all a caller was told. Any other error,
# such as one a VCF's reader croaked with, has its place already and is passed
# on as it is. $@ is not localized, since before perl 5.14 leaving that scope
# by die restored it, and lost the error.
sub _located {
	my ($code) = @_;
	my @r;
	return @r if eval { @r = $code->(); 1 };
	my $error = $@;
	die $error if ref $error || $error !~ s/$Located_here//;
	croak $error;
}

# $s as characters. A string perl holds as characters is taken as it is; one it
# holds as bytes is taken to be UTF-8 if it decodes as such, which is how the
# command line used to pass it to Python, and Latin-1 otherwise.
sub _chars {
	my $s = "$_[0]";
	utf8::decode($s) unless utf8::is_utf8($s);
	$s;
}

# $s, read as _chars reads it, as UTF-8 bytes, which is what msa_plot.py reads
# a FASTA or newick file as.
sub _utf8 {
	my $s = _chars($_[0]);
	utf8::encode($s);
	$s;
}

# The start of the "Creator" written into an image's metadata, after the one
# Matplotlib::Simple 0.319 writes: which script, run where, called which sub of
# which version of this module (and of Alien::Bioinf, whose tools and Python
# draw every image), by whom, on which computer (its hostname and OS), with
# which perl and where it is. Like Matplotlib::Simple's, the Creator is the image's
# whole provenance, on one line, and the only metadata written: msa_plot.py
# appends the Python, matplotlib and Biopython versions as it runs, since only
# it knows them, and then each clause it is given with "--p" (what the image
# was made from, with digests, and the commands that made it). Matplotlib::Simple has to py_str() its
# Creator, which it pastes into a Python literal; this one reaches Python as a
# JSON string through _python's --argfile, so backslashes and quotes in a path
# need no escaping here.
#
# With $own, the file is written by this module itself (view_alignment's SVG
# and LaTeX), so Alien::Bioinf is neither needed nor named; the clause that
# says how an alignment was made names it when clustalo was run.
sub _creator {
	my ($sub, $own) = @_;
	_alien($sub) unless $own;
	"$Script called using \"$sub\" in " . __FILE__ . " version $VERSION" . ($own ? '' : " with Alien::Bioinf $Alien::Bioinf::VERSION")
		. ' by user ' . _user() . ' on host ' . hostname() . " ($^O) with Perl " . sprintf('%vd', $^V) . " ($^X)";
}

# The name of the user running this. getpwuid is unimplemented on MSWin32,
# where it dies, and getlogin is undef without a controlling terminal (under
# cron, or a batch scheduler), so the environment is the last resort.
sub _user {
	my $user = eval { (getpwuid $<)[0] };
	$user = getlogin() unless defined $user && length $user;
	$user = $ENV{USERNAME} // $ENV{USER} unless defined $user && length $user;
	defined $user && length $user ? $user : 'unknown';
}

# The data in the JSON file $file, which $sub was given; dies naming $sub, as
# the file is that caller's argument. Up to 2026-11-02 a file that was not JSON
# died with JSON::MaybeXS's message, naming no function, and an empty one with
# a "Usage:" message, since <$fh> passed decode_json an empty list.
sub _json_file {
	my ($sub, $file) = @_;
	require JSON::MaybeXS;
	open my $fh, '<:raw', $file or croak "$sub: can't read $file: $!";
	my $text = do { local $/; <$fh> } // ''; # undef for an empty file
	close $fh or croak "$sub: can't read $file: $!";
	my $data = eval { JSON::MaybeXS::decode_json($text) };
	unless (defined $data) {
		(my $why = $@) =~ s/ at .+ line \d+\.\n\z//; # the location is the module's, which says nothing of the file
		croak "$sub: $file isn't JSON: $why";
	}
	$data;
}

# @cmd run with list-form system, which needs no shell. $? is -1 when the
# program never started; otherwise its low 7 bits are the signal that killed
# it, and must be read before the shift, which leaves only the exit code.
sub _run {
	my @cmd = @_;
	system(@cmd) == 0 and return;
	my $why = $? == -1 ? "it didn't start: $!" : $? & 127 ? 'killed by signal ' . ($? & 127) : 'exit ' . ($? >> 8);
	croak "_run: \"@cmd\" failed: $why";
}

# Alien::Bioinf, loaded for $sub, or a message saying that $sub needs it.
sub _alien {
	my ($sub) = @_;
	eval { require Alien::Bioinf; 1 }
		or croak "_alien: $sub needs Alien::Bioinf, for Clustal Omega, BLAST+ and the plotting Python, and it can't be loaded: $@";
	'Alien::Bioinf';
}

# share/msa_plot.py run with @args under Alien::Bioinf's Python, for $sub. The
# arguments go in a JSON file rather than on the command line: perl's
# system(LIST) on Windows does not escape a '"' inside an argument, and the
# Creator and the JSON options are full of them. Each argument is read as
# _chars reads it; encode_json alone would read UTF-8 bytes as Latin-1. -I
# keeps PYTHONPATH, PYTHONHOME and the user's own site-packages out, so that
# nothing but Alien::Bioinf's venv is imported.
sub _python {
	my ($sub, @args) = @_;
	require JSON::MaybeXS;
	my @chars = map { _chars($_) } @args;
	my $argfile = _tmp('.json');
	open my $fh, '>:raw', $argfile or croak "_python: can't write $argfile: $!";
	print {$fh} JSON::MaybeXS::encode_json(\@chars);
	close $fh or croak "_python: can't write $argfile: $!";
	_run(_alien($sub)->python, '-I', _script(), '--argfile', $argfile);
}

# $data, whose strings the caller has made characters with _chars, as JSON
# text: characters, not UTF-8 bytes, since it is one argument that _python
# encodes along with the rest. It is held as UTF-8, so that _python takes it as
# it is: decoding it whole, as up to 2026-10-17, turned a byte string inside it
# to mojibake whenever another string in it held characters.
sub _json_text {
	my ($data) = @_;
	require JSON::MaybeXS;
	my $text = JSON::MaybeXS->new(utf8 => 0, canonical => 1)->encode($data);
	utf8::upgrade($text);
	$text;
}

# "wrote $file" to STDOUT, as LikeR's write_table prints it: $file in black
# (30) on $bg (an ANSI background, 43 = yellow or 46 = cyan) and then reset
# (0), written out rather than loaded from Term::ANSIColor; the reset comes
# before the newline so the colour doesn't run on into the next line. The
# colour is left out when STDOUT is not a terminal, where the escapes would
# only be noise in a log or a test harness.
sub _wrote {
	my ($file, $bg, $verb) = @_;
	$verb //= 'wrote'; # or 'will write', for an image whose script has not run yet
	print STDOUT -t STDOUT ? "$verb \e[30;${bg}m$file\e[0m\n" : "$verb $file\n";
}

# A new temporary file's name, with $suffix. It is removed when perl exits
# unless $keep is true.
sub _tmp {
	my ($suffix, $keep) = @_;
	require File::Temp;
	my ($fh, $name) = File::Temp::tempfile(SUFFIX => $suffix, UNLINK => $keep ? 0 : 1, TMPDIR => 1);
	close $fh or croak "_tmp: can't close $name: $!";
	$name;
}

# "fh" and "execute" of $sub's $args, resolved and checked before anything
# runs, as Matplotlib::Simple's plt takes them: "fh" is a File::Temp that the
# Python drawing the image is appended to, so that one script, run once, can
# draw several images (and those of Matplotlib::Simple, which takes the same
# File::Temp); "execute" says whether to run that script now.
sub _drawing {
	my ($sub, $args) = @_;
	my %r = (fh => $args->{fh});
	$r{execute} = $args->{execute} // 1; # 1 = run the script now; 0 = only write it
	croak "$sub: \"execute\" must be 0 or 1, not " . _what($r{execute})
		unless !ref $r{execute} && ($r{execute} eq '0' || $r{execute} eq '1');
	if (defined $r{fh}) {
		require Scalar::Util;
		croak "$sub: \"fh\" must be a File::Temp object, as for Matplotlib::Simple, not " . _what($r{fh})
			unless Scalar::Util::blessed($r{fh}) && $r{fh}->isa('File::Temp');
	}
	\%r;
}

# share/msa_plot.py run with @args for $sub, as Python appended to the script
# that $drawing (from _drawing) names, or to a new temporary one; the script is
# run under Alien::Bioinf's Python if $drawing->{execute}. Returns the script's
# file name. A new script is kept after perl exits only when it is not run
# here, since only then is it of use afterwards.
#
# The script is the whole of what it needs, so that it can be run later, after
# perl has removed its temporary files: each file passed with --f, --tree or
# --table is carried in it, and written out again, to a temporary directory,
# as the script runs. Nothing perl was given is pasted into the Python source:
# the arguments, the files and msa_plot.py's path are one JSON object, base64
# encoded, as Matplotlib::Simple's write_data passes data, since a Windows
# path's "\b" is a backspace in a Python literal and an apostrophe would close
# it. msa_plot.py is run by runpy in a namespace of its own, so that its
# globals meet neither those of another image in the script nor those of
# Matplotlib::Simple's code. -I keeps PYTHONPATH, PYTHONHOME and the user's own
# site-packages out, as for _python.
sub _draw {
	my ($sub, $drawing, @args) = @_;
	require JSON::MaybeXS;
	require MIME::Base64;
	my %file = map { $_ => 1 } qw(--f --tree --table); # the options whose value is a file msa_plot.py reads
	my @json;
	for (my $i = 0; $i < @args; $i++) {
		push @json, _chars($args[$i]);
		next unless $file{ $args[$i] } && $i < $#args;
		my $in = $args[++$i];
		open my $fh, '<:raw', $in or croak "_draw: can't read $in: $!";
		my $bytes = do { local $/; <$fh> };
		close $fh or croak "_draw: can't read $in: $!";
		# named by its place, so that no two collide, and with its own suffix
		push @json, { name => 'input' . scalar(@json) . ($in =~ /(\.[A-Za-z]+)\z/ ? $1 : ''), b64 => MIME::Base64::encode_base64($bytes // '', '') };
	}
	my $b64 = MIME::Base64::encode_base64(JSON::MaybeXS::encode_json({ script => _chars(_script()), args => \@json }), '');
	my $py = <<"PYTHON";
# $sub, from Cn::Bioinf $VERSION: msa_plot.py run on the arguments below
import base64, json, os, runpy, sys, tempfile
cn_bioinf = json.loads(base64.b64decode('$b64').decode('utf-8'))
with tempfile.TemporaryDirectory() as cn_bioinf_dir:
	cn_bioinf_argv = []
	for cn_bioinf_arg in cn_bioinf['args']:
		if isinstance(cn_bioinf_arg, dict):
			cn_bioinf_path = os.path.join(cn_bioinf_dir, cn_bioinf_arg['name'])
			with open(cn_bioinf_path, 'wb') as cn_bioinf_fh:
				cn_bioinf_fh.write(base64.b64decode(cn_bioinf_arg['b64']))
			cn_bioinf_arg = cn_bioinf_path
		cn_bioinf_argv.append(cn_bioinf_arg)
	sys.argv = [cn_bioinf['script']] + cn_bioinf_argv
	runpy.run_path(cn_bioinf['script'], run_name='__main__')
PYTHON
	my $script;
	if (defined $drawing->{fh}) {
		my $fh = $drawing->{fh};
		$script = $fh->filename;
		print {$fh} $py or croak "$sub: can't write to \"fh\", $script: $!";
		$fh->flush or croak "$sub: can't write to \"fh\", $script: $!";
	} else {
		$script = _tmp('.py', !$drawing->{execute});
		open my $fh, '>:raw', $script or croak "$sub: can't write $script: $!";
		print {$fh} $py or croak "$sub: can't write $script: $!";
		close $fh or croak "$sub: can't write $script: $!";
	}
	_run(_alien($sub)->python, '-I', $script) if $drawing->{execute};
	$script;
}

sub _script {
	require File::ShareDir;
	File::ShareDir::dist_file('Cn-Bioinf', 'msa_plot.py');
}

# The FASTA file's records and their deflines in file order.
sub _fasta_ordered {
	my ($file) = @_;
	my @order;
	my $fh = _open_fasta($file);
	my ($h) = _located(sub { _read_fasta($fh, undef, $file, \@order) });
	# a truncated or corrupt .gz shows only in gzip's exit status, as in
	# fasta2hash; the whole file was read, so no SIGPIPE is expected
	unless (close $fh) {
		my $why = $! ? "$!" : $? & 127 ? 'gzip was killed by signal ' . ($? & 127) : 'gzip exited ' . ($? >> 8);
		croak "_fasta_ordered: couldn't read all of $file: $why";
	}
	($h, \@order);
}

sub _open_fasta {
	my ($file) = @_;
	croak "_open_fasta: undef isn't a readable file" unless defined $file;
	croak "_open_fasta: \"$file\" doesn't exist or isn't a readable file" unless -f $file && -r _;
	my $fh;
	if ($file =~ /\.gz\z/i) { # any case, as _weight_rows takes it
		# in an eval, since a perl without list-form piped open (MSWin32 before
		# 5.22) dies in open itself, with no function name in the message
		# "--", or gzip would read a name that starts with "-" as its options
		eval { open $fh, '-|', 'gzip', '-dc', '--', $file } or croak "_open_fasta: can't run gzip on $file: " . ($@ || $!);
	} else {
		open $fh, '<:raw', $file or croak "_open_fasta: can't read $file: $!";
	}
	$fh;
}

sub _first_letter {
	my ($string) = @_;
	return $1 if $string =~ /^([A-Za-z])/;
	croak "_first_letter: \"$string\" doesn't start with a letter, so it has no first letter";
}

# Narrow but unambiguous labels, e.g. "$\it{C.al.}$", for [genus, species,
# strain] triples ('' for no strain). One letter of the species cannot tell
# C.albicans from C.auris, so this takes the shortest species prefix that
# separates every entry; the strain is always kept, since it is all that
# separates the three C.neoformans.
sub _abbreviated_labels {
	my ($names) = @_;
	my $max = 0;
	foreach my $n (@{ $names }) {
		$max = length $n->[1] if length $n->[1] > $max;
	}
	foreach my $n (1 .. $max) {
		my @labels = map {
			'$\it{' . ucfirst(_first_letter($_->[0])) . '.' . lc(substr($_->[1], 0, $n)) . '.}$' . ($_->[2] ne '' ? " $_->[2]" : '')
		} @{ $names };
		my %seen;
		return \@labels unless grep { $seen{$_}++ } @labels;
	}
	croak "_abbreviated_labels: can't tell " . join(', ', map { join '.', @{ $_ } } @{ $names }) . ' apart, even with the full species name and strain';
}

# ---- FASTA

sub fasta2hash {
	my ($file, $key) = @_;
	my $fh = _open_fasta($file);
	my ($r) = _located(sub { _read_fasta($fh, $key, $file) });
	# A gzip that fails part-way, on a truncated or corrupt .gz, has merely
	# stopped writing, so its exit status is the only sign of it. That is
	# checked unless $key was found, when reading may have stopped early and
	# the closed pipe have killed gzip with a SIGPIPE.
	unless (close $fh) {
		my $why = $! ? "$!" : $? & 127 ? 'gzip was killed by signal ' . ($? & 127) : 'gzip exited ' . ($? >> 8);
		croak "fasta2hash: couldn't read all of $file: $why" unless defined $key && defined $r;
	}
	if (defined $key) {
		return $r if defined $r;
		croak "fasta2hash: couldn't find \"$key\" in $file";
	}
	croak "fasta2hash: couldn't find any sequences in $file" unless %{ $r };
	$r;
}

sub hash2fasta_file {
	my ($hash, $filename, $order, $width) = @_;
	croak "hash2fasta_file: 1st argument must be a hash ref" unless ref $hash eq 'HASH';
	croak "hash2fasta_file: 2nd argument must be a file name" unless defined $filename && ref $filename eq '';
	croak "hash2fasta_file: 3rd argument must be an array ref or undef" if defined $order && ref $order ne 'ARRAY';
	# checked here because the XS takes it as a UV, where -1 would wrap round
	croak "hash2fasta_file: 4th argument must be a whole number, 0 or more, or undef, not \"$width\"" if defined $width && $width !~ /\A[0-9]+\z/;
	_fasta_file('hash2fasta_file', $hash, $filename, $order // [sort keys %{ $hash }], $width // 80);
	_wrote($filename, 46); # cyan
	$filename;
}

# hash2fasta_file without its checks, its defaults or its "wrote" line, for
# the FASTA files the module writes for itself, mostly temporary ones that a
# caller never asked for; $sub is the caller, to name in an error.
sub _fasta_file {
	my ($sub, $hash, $filename, $order, $width) = @_;
	open my $fh, '>:raw', $filename or croak "$sub: can't write $filename: $!";
	_located(sub { _write_fasta($fh, $hash, $order, $width) });
	close $fh or croak "$sub: can't write $filename: $!";
	$filename;
}

# ---- sequences
#
# complement to motif_search work on a sequence held as a perl string, and
# fasta_index and fasta_region on a FASTA file. Each says which function of
# which library it follows, and t/seq.t, t/protein.t and t/faidx.t take their
# expected values from that library's own tests.

# Dies, naming $sub, unless $seq is a sequence: a string, which may be empty.
sub _sequence {
	my ($sub, $seq) = @_;
	croak "$sub: the sequence must be a string, not " . _what($seq) if !defined $seq || ref $seq;
}

# "type" of $sub's $args, which says what kind of sequence it was given, as the
# one of @$allowed ('DNA', 'RNA', 'protein') that it names in any case; DNA
# when it was not given.
sub _seq_type {
	my ($sub, $args, $allowed) = @_;
	my $type = $args->{type} // 'DNA';
	my ($found) = ref $type ? () : grep { lc $_ eq lc $type } @{ $allowed };
	return $found if defined $found;
	my @q = map { "\"$_\"" } @{ $allowed };
	croak "$sub: \"type\" must be " . join(', ', @q[0 .. $#q - 1]) . " or $q[-1], not " . _what($type);
}

# "strand" of $sub's $args as 'both', '+' or '-'; $default when it was not
# given.
sub _strand {
	my ($sub, $args, $default) = @_;
	my $strand = $args->{strand} // $default;
	croak "$sub: \"strand\" must be \"+\", \"-\" or \"both\", not " . _what($strand)
		if ref $strand || $strand !~ /\A(?:\+|-|both)\z/;
	$strand;
}

# $seq with every nucleotide replaced by the one it pairs with, for $sub, which
# was given @opt. The pairs are Biopython 1.87's ambiguous_dna_complement and
# ambiguous_rna_complement (Bio/Data/IUPACData.py), in both cases, and U is
# read as T, as its Seq.complement() and Seq.complement_rna() read it. N and X
# pair with themselves, and so does every character that is not a nucleotide,
# a gap included.
sub _complement {
	my ($sub, $seq, @opt) = @_;
	_sequence($sub, $seq);
	my $type = _seq_type($sub, _args(\@opt, $sub, [], ['type']), ['DNA', 'RNA']);
	my $c = "$seq";
	if ($type eq 'RNA') {
		$c =~ tr/ACGTUMRWSYKVHDBacgtumrwsykvhdb/UGCAAKYWSRMBDHVugcaakywsrmbdhv/;
	} else {
		$c =~ tr/ACGTUMRWSYKVHDBacgtumrwsykvhdb/TGCAAKYWSRMBDHVtgcaakywsrmbdhv/;
	}
	$c;
}

sub complement { _complement('complement', @_) }

sub reverse_complement { scalar reverse _complement('reverse_complement', @_) }

sub transcribe {
	my ($seq, @rest) = @_;
	croak 'transcribe: takes one argument, the sequence' if @rest;
	_sequence('transcribe', $seq);
	(my $rna = "$seq") =~ tr/Tt/Uu/;
	$rna;
}

sub back_transcribe {
	my ($seq, @rest) = @_;
	croak 'back_transcribe: takes one argument, the sequence' if @rest;
	_sequence('back_transcribe', $seq);
	(my $dna = "$seq") =~ tr/Uu/Tt/;
	$dna;
}

# NCBI's genetic codes, from share/genetic_codes.tsv, which
# share/make_genetic_codes.pl writes and whose header comment says where each
# column comes from. %Code is id => { id, names, aas, start_mask, stop_mask,
# both } and %Code_id is each lower-cased name => id; both are empty until the
# file has been read. The three 64-letter strings are what Bioinf.xs's
# _translate() takes, a letter for each codon from TTT to GGG:
#
# - aas: the codon's amino acid, or * for a stop.
# - start_mask: M for a codon that can start a protein, and A for any other.
# - stop_mask: * for a codon that can end one, and A for any other.
#
# "Translating" a codon with a mask says whether it is a start or a stop by the
# rules that translate it, so that an ambiguous codon is a start only when
# every codon it stands for is one. "both" lists, as [codon, amino acid], the
# codons that aas gives an amino acid and stop_mask a stop: the organism reads
# them either way.
my (%Code, %Code_id);

# The 64 codons in the order of those strings.
my @Codon = map { my $x = $_; map { my $y = $_; map { "$x$y$_" } qw(T C A G) } qw(T C A G) } qw(T C A G);

# start_mask for ATG alone, which is codon 35: A is base 2 and G base 3 of
# T, C, A, G, so 16 * 2 + 4 * 0 + 3.
my $Atg_mask = ('A' x 35) . 'M' . ('A' x 28);

# Reads the genetic codes into %Code and %Code_id, once, for $sub.
sub _genetic_codes {
	my ($sub) = @_;
	return if %Code;
	my $file = _share_file($sub, 'genetic_codes.tsv');
	open my $fh, '<', $file or croak "$sub: can't read $file: $!";
	my (%code, %id);
	while (defined(my $line = <$fh>)) {
		$line =~ s/\r?\n\z//;
		next if $line eq '' || $line =~ /\A#/;
		my ($id, $names, $aas, $starts) = split /\t/, $line, -1;
		croak "$sub: line $. of $file isn't a genetic code: it needs a number, names, 64 amino acids and 64 start and stop marks"
			unless defined $starts && $id =~ /\A[1-9][0-9]*\z/ && length $names && $aas =~ /\A[A-Z*]{64}\z/ && $starts =~ /\A[M*-]{64}\z/;
		(my $start_mask = $starts) =~ tr/M*-/MAA/;
		(my $stop_mask = $starts) =~ tr/M*-/A*A/;
		my @both = map { [$Codon[$_], substr $aas, $_, 1] } grep { substr($starts, $_, 1) eq '*' && substr($aas, $_, 1) ne '*' } 0 .. 63;
		$code{$id} = { id => 0 + $id, names => [split /; /, $names], aas => $aas, start_mask => $start_mask, stop_mask => $stop_mask, both => \@both };
		# A code is known by each of its names, and by each part of a name that
		# lists several organisms, which is how Biopython's CodonTable.py
		# registers them: "Bacterial, Archaeal and Plant Plastid" is also
		# "Bacterial", "Archaeal" and "Plant Plastid".
		$id{lc $_} //= 0 + $id for $names, map { $_, split /, | and / } split /; /, $names;
	}
	close $fh or croak "$sub: can't read $file: $!";
	croak "$sub: $file has no genetic codes" unless %code;
	%Code = %code;
	%Code_id = %id;
}

# The genetic code that $table, "table" of $sub's arguments, names: one of
# %Code's values.
sub _genetic_code {
	my ($sub, $table) = @_;
	_genetic_codes($sub);
	my $id = ref $table ? undef : $table =~ /\A[0-9]+\z/ ? 0 + $table : $Code_id{lc $table};
	croak "$sub: \"table\" must be the number or the name of an NCBI genetic code, not " . _what($table)
		. '; the numbers are ' . join(', ', sort { $a <=> $b } keys %Code) unless defined $id && $Code{$id};
	$Code{$id};
}

# Warns, for $sub, when $code has codons that are read as an amino acid or as
# a stop, since they are translated as the amino acid; with $to_stop it dies
# instead, as the protein's end could not be told. Biopython 1.87's
# _translate_str() (Bio/Seq.py) does both.
sub _both_ways {
	my ($sub, $code, $to_stop) = @_;
	my @both = @{ $code->{both} } or return;
	my $reads = "genetic code $code->{id} reads " . join(' and ', map { "$_->[0] as $_->[1] or as a stop" } @both);
	croak "$sub: \"to_stop\" can't be used with \"table\" $code->{id}: $reads" if $to_stop;
	carp "$sub: $reads, and " . (@both > 1 ? 'they are' : 'it is') . ' translated as the amino acid';
}

# $v, the option $k of $sub, as a single byte for Bioinf.xs, which takes the
# first byte of the string it is handed; dies unless it is one character below
# 256. undef is passed through.
sub _one_char {
	my ($sub, $k, $v) = @_;
	return $v unless defined $v;
	croak "$sub: \"$k\" must be one character, below 256, not " . _what($v) if ref $v || $v !~ /\A[\x00-\xff]\z/s;
	utf8::downgrade($v); # a character from 128 to 255 can be held as two bytes
	$v;
}

sub translate {
	my ($seq, @opt) = @_;
	my $sub = 'translate';
	_sequence($sub, $seq);
	my $args = _args(\@opt, $sub, [], [qw(cds gap stop_symbol table to_stop)]);
	my %r; # the options, each resolved once
	$r{table} = $args->{table} // 1; # an NCBI genetic code's number or name
	$r{to_stop} = $args->{to_stop} ? 1 : 0; # 1 = the protein ends before the first stop
	$r{cds} = $args->{cds} ? 1 : 0; # 1 = $seq is a whole coding sequence, start codon to stop codon
	$r{stop_symbol} = _one_char($sub, 'stop_symbol', $args->{stop_symbol} // '*'); # the letter written for a stop
	$r{gap} = _one_char($sub, 'gap', $args->{gap}); # the gap character; undef = a gap is not a codon
	my $code = _genetic_code($sub, $r{table});
	_both_ways($sub, $code, $r{to_stop});
	my $len = length $seq;
	if ($r{cds}) {
		# Biopython's checks, in its order
		my ($first) = _located(sub { _translate(substr($seq, 0, 3), $code->{start_mask}, '*', 0, undef) });
		croak "$sub: with \"cds\", the first codon, \"" . substr($seq, 0, 3) . "\", must be a start codon of genetic code $code->{id}"
			unless $first eq 'M';
		croak "$sub: with \"cds\", the sequence's length, $len, must be a multiple of three" if $len % 3;
		my ($last) = _located(sub { _translate(substr($seq, -3), $code->{stop_mask}, '*', 0, undef) });
		croak "$sub: with \"cds\", the last codon, \"" . substr($seq, -3) . "\", must be a stop codon of genetic code $code->{id}"
			unless $last eq '*';
		# every codon but the last, up to the first stop, which there must not be
		my ($p) = _located(sub { _translate(substr($seq, 0, $len - 3), $code->{aas}, '*', 1, $r{gap}) });
		croak "$sub: with \"cds\", only the last codon may be a stop, and codon " . (length($p) + 1) . ', "'
			. substr($seq, 3 * length $p, 3) . '", is one' if length($p) < $len / 3 - 1;
		substr($p, 0, 1) = 'M'; # whatever the start codon stands for inside a protein
		return $p;
	}
	carp "$sub: the sequence's length, $len, is not a multiple of three, so its last " . ($len % 3 == 1 ? 'letter is' : '2 letters are')
		. ' not translated' if $len % 3;
	my ($p) = _located(sub { _translate($seq, $code->{aas}, $r{stop_symbol}, $r{to_stop}, $r{gap}) });
	$p;
}

sub translate_six_frames {
	my ($seq, @opt) = @_;
	my $sub = 'translate_six_frames';
	_sequence($sub, $seq);
	my $args = _args(\@opt, $sub, [], [qw(stop_symbol table)]);
	my %r; # the options, each resolved once
	$r{table} = $args->{table} // 1; # an NCBI genetic code's number or name
	$r{stop_symbol} = _one_char($sub, 'stop_symbol', $args->{stop_symbol} // '*'); # the letter written for a stop
	my $code = _genetic_code($sub, $r{table});
	_both_ways($sub, $code, 0);
	my %frame;
	foreach my $strand (1, -1) {
		my $nuc = $strand > 0 ? $seq : scalar reverse _complement($sub, $seq);
		foreach my $f (0 .. 2) {
			# a frame that starts beyond the sequence's end has no codons
			($frame{$strand * ($f + 1)}) = $f < length $nuc
				? _located(sub { _translate(substr($nuc, $f), $code->{aas}, $r{stop_symbol}, 0, undef) }) : '';
		}
	}
	\%frame;
}

sub find_orfs {
	my ($seq, @opt) = @_;
	my $sub = 'find_orfs';
	_sequence($sub, $seq);
	my $args = _args(\@opt, $sub, [], [qw(min_length start strand table)]);
	my %r; # the options, each resolved once
	$r{table} = $args->{table} // 1; # an NCBI genetic code's number or name
	# The fewest amino acids an open reading frame may have. 10 is the default
	# of EMBOSS 6.6.0's getorf, whose -minsize is 30 nucleotides.
	$r{min_length} = $args->{min_length} // 10;
	croak "$sub: \"min_length\" must be a whole number, 1 or more, not " . _what($r{min_length})
		if ref $r{min_length} || $r{min_length} !~ /\A[1-9][0-9]*\z/;
	# Where a reading frame opens: 'any' = at the codon after a stop, or the
	# first of the sequence; 'ATG' = at the first ATG after that; 'code' = at
	# the first of the genetic code's start codons after that.
	$r{start} = $args->{start} // 'any';
	croak "$sub: \"start\" must be \"any\", \"ATG\" or \"code\", not " . _what($r{start})
		if ref $r{start} || $r{start} !~ /\A(?:any|ATG|code)\z/;
	$r{strand} = _strand($sub, $args, 'both'); # '+', '-' or 'both'
	my $code = _genetic_code($sub, $r{table});
	_both_ways($sub, $code, 0);
	my $mask = $r{start} eq 'any' ? undef : $r{start} eq 'ATG' ? $Atg_mask : $code->{start_mask};
	my $len = length $seq;
	my @orf;
	foreach my $strand ($r{strand} eq 'both' ? (1, -1) : $r{strand} eq '+' ? 1 : -1) {
		my $nuc = $strand > 0 ? $seq : scalar reverse _complement($sub, $seq);
		foreach my $f (0 .. 2) {
			next unless $f < $len;
			my $frame = substr $nuc, $f;
			# the frame's codons as amino acids, and as M where one is a start
			my ($protein) = _located(sub { _translate($frame, $code->{aas}, '*', 0, undef) });
			my ($starts) = defined $mask ? _located(sub { _translate($frame, $mask, '*', 0, undef) }) : undef;
			my $codons = length $protein;
			# $from and $stop count codons: the frame is open over $from .. $stop - 1
			for (my $from = 0; $from < $codons;) {
				my $stop = index $protein, '*', $from;
				$stop = $codons if $stop < 0;
				my $next = $stop + 1;
				$from = index $starts, 'M', $from if defined $starts;
				if ($from >= 0 && $stop - $from >= $r{min_length}) {
					my $p = substr $protein, $from, $stop - $from;
					# a start codon stands for M at a protein's start, whatever
					# it stands for inside one, as getorf's -methionine has it
					substr($p, 0, 1) = 'M' if defined $starts;
					# the first and last base, counted from 0 on this strand
					my ($x, $y) = ($f + 3 * $from, $f + 3 * $stop - 1);
					push @orf, {
						start => $strand > 0 ? $x + 1 : $len - $y, end => $strand > 0 ? $y + 1 : $len - $x,
						strand => $strand, frame => $strand * ($f + 1), length => $stop - $from, protein => $p,
					};
				}
				$from = $next;
			}
		}
	}
	[sort { $a->{start} <=> $b->{start} || $a->{end} <=> $b->{end} || $b->{strand} <=> $a->{strand} } @orf];
}

sub gc_content {
	my ($seq, @opt) = @_;
	my $sub = 'gc_content';
	_sequence($sub, $seq);
	my $args = _args(\@opt, $sub, [], ['ambiguous']);
	# What a letter other than A, C, G, T, U, S and W counts for: 'remove' =
	# nothing, and it is left out of the length too; 'ignore' = nothing, but it
	# is part of the length; 'weighted' = the share of the bases it stands for
	# that are G or C.
	my $ambiguous = $args->{ambiguous} // 'remove';
	croak "$sub: \"ambiguous\" must be \"remove\", \"ignore\" or \"weighted\", not " . _what($ambiguous)
		if ref $ambiguous || $ambiguous !~ /\A(?:remove|ignore|weighted)\z/;
	my $gc = ($seq =~ tr/CGScgs//);
	my $len = $ambiguous eq 'remove' ? $gc + ($seq =~ tr/ATWUatwu//) : length $seq;
	if ($ambiguous eq 'weighted') {
		# Biopython 1.87's _gc_values (Bio/SeqUtils/__init__.py), added in the
		# order its gc_fraction() adds them, B D H K M N R V X Y, so that the
		# sum rounds as its sum does
		$gc += ($seq =~ tr/Bb//) * (2 / 3); # C, G or T
		$gc += ($seq =~ tr/Dd//) * (1 / 3); # A, G or T
		$gc += ($seq =~ tr/Hh//) * (1 / 3); # A, C or T
		$gc += ($seq =~ tr/Kk//) * 0.5; # G or T
		$gc += ($seq =~ tr/Mm//) * 0.5; # A or C
		$gc += ($seq =~ tr/Nn//) * 0.5; # any base
		$gc += ($seq =~ tr/Rr//) * 0.5; # A or G
		$gc += ($seq =~ tr/Vv//) * (2 / 3); # A, C or G
		$gc += ($seq =~ tr/Xx//) * 0.5; # any base
		$gc += ($seq =~ tr/Yy//) * 0.5; # C or T
	}
	$len ? $gc / $len : 0;
}

sub assembly_stats {
	my ($seqs, @rest) = @_;
	my $sub = 'assembly_stats';
	croak "$sub: takes one argument, the sequences" if @rest;
	croak "$sub: the sequences must be a hash ref, as fasta2hash returns, or an array ref, not " . _what($seqs)
		unless ref $seqs eq 'HASH' || ref $seqs eq 'ARRAY';
	my (@len, %nx, %lx);
	my ($total, $n_count, $gaps) = (0, 0, 0);
	foreach my $s (ref $seqs eq 'HASH' ? values %{ $seqs } : @{ $seqs }) {
		croak "$sub: every sequence must be a string, and one is " . _what($s) if !defined $s || ref $s;
		push @len, length $s;
		$total += length $s;
		$n_count += ($s =~ tr/Nn//);
		$gaps++ while $s =~ /[Nn]+/g;
	}
	@len = sort { $b <=> $a } @len;
	# Nx is the length of the sequence at which the lengths, added from the
	# longest down, first reach x% of their total, and Lx is how many
	# sequences that took. The comparison is in whole numbers, 10 * the sum
	# against the total * x / 10, where assembly-stats divides in floating point.
	my ($sum, $tenth) = (0, 1); # $tenth = the x / 10 that has not been reached yet
	# with a total of 0, 10 * 0 >= 0 * x would reach every tenth at the first
	# sequence, and give an Lx of 1 where the rule below says 0
	foreach my $i ($total ? (0 .. $#len) : ()) {
		$sum += $len[$i];
		while ($tenth <= 10 && 10 * $sum >= $total * $tenth) {
			$nx{10 * $tenth} = $len[$i];
			$lx{10 * $tenth} = $i + 1;
			$tenth++;
		}
	}
	# no sequences, or none with any length: every Nx and Lx is 0
	$nx{10 * $_} //= 0, $lx{10 * $_} //= 0 for 1 .. 10;
	{
		number => scalar @len, total_length => $total, mean_length => @len ? $total / @len : 0,
		longest => @len ? $len[0] : 0, shortest => @len ? $len[-1] : 0,
		n_count => $n_count, gaps => $gaps, n50 => $nx{50}, l50 => $lx{50}, nx => \%nx, lx => \%lx,
	};
}

sub kmer_count {
	my ($seq, $k, @opt) = @_;
	my $sub = 'kmer_count';
	_sequence($sub, $seq);
	# 2147483647 is the longest key a perl hash takes, I32_MAX
	croak "$sub: k must be a whole number from 1 to 2147483647, not " . _what($k)
		if !defined $k || ref $k || $k !~ /\A[1-9][0-9]{0,9}\z/ || $k > 2147483647;
	my $args = _args(\@opt, $sub, [], [qw(overlap relative)]);
	my %r; # the options, each resolved once
	$r{overlap} = ($args->{overlap} // 1) ? 1 : 0; # 1 = every k-mer; 0 = one every k letters, which do not overlap
	$r{relative} = $args->{relative} ? 1 : 0; # 1 = each count as a share of them all
	my $step = $r{overlap} ? 1 : 0 + $k;
	my $count;
	# Bioinf.xs counts bytes. A string that perl holds as characters is handed
	# over as bytes where it can be, and counted here where it cannot, which
	# is when it has a character above 255.
	my $bytes = $seq;
	if (!utf8::is_utf8($bytes) || utf8::downgrade($bytes, 1)) {
		($count) = _located(sub { _kmer_count($bytes, 0 + $k, $step) });
	} else {
		$count = {};
		for (my $i = 0; $i + $k <= length $seq; $i += $step) {
			$count->{ substr $seq, $i, $k }++;
		}
	}
	if ($r{relative}) {
		my $all = 0;
		$all += $_ for values %{ $count };
		$_ /= $all for values %{ $count };
	}
	$count;
}

# The weight of each nucleotide, as its monophosphate, and of each amino acid,
# in daltons: "average" with every element at its standard atomic weight and
# "monoisotopic" with each at its commonest isotope. They are Biopython 1.87's
# unambiguous_dna_weights, unambiguous_rna_weights and protein_weights, and
# the monoisotopic_ table of each (Bio/Data/IUPACData.py), which that file
# introduces with "Mass data taken from PubChem". O is pyrrolysine and U
# selenocysteine. "water" is what one bond between two residues gives up, from
# molecular_weight() of Bio/SeqUtils/__init__.py.
my %Weight = (
	average => {
		DNA => { A => 331.2218, C => 307.1971, G => 347.2212, T => 322.2085 },
		RNA => { A => 347.2212, C => 323.1965, G => 363.2206, U => 324.1813 },
		protein => {
			A => 89.0932, C => 121.1582, D => 133.1027, E => 147.1293, F => 165.1891, G => 75.0666, H => 155.1546,
			I => 131.1729, K => 146.1876, L => 131.1729, M => 149.2113, N => 132.1179, O => 255.3134, P => 115.1305,
			Q => 146.1445, R => 174.201, S => 105.0926, T => 119.1192, U => 168.0532, V => 117.1463, W => 204.2252,
			Y => 181.1885,
		},
		water => 18.0153,
	},
	monoisotopic => {
		DNA => { A => 331.06817, C => 307.056936, G => 347.063084, T => 322.056602 },
		RNA => { A => 347.063084, C => 323.051851, G => 363.057999, U => 324.035867 },
		protein => {
			A => 89.047678, C => 121.019749, D => 133.037508, E => 147.053158, F => 165.078979, G => 75.032028,
			H => 155.069477, I => 131.094629, K => 146.105528, L => 131.094629, M => 149.051049, N => 132.053492,
			O => 255.158292, P => 115.063329, Q => 146.069142, R => 174.111676, S => 105.042593, T => 119.058243,
			U => 168.964203, V => 117.078979, W => 204.089878, Y => 181.073893,
		},
		water => 18.010565,
	},
);

# A pattern for each capital letter, compiled once: perl 5.32 leaks a pattern
# that is compiled at run time, and molecular_weight would compile one for
# each letter on every call.
my %Letter_re = map { $_ => qr/$_/ } 'A' .. 'Z';

sub molecular_weight {
	my ($seq, @opt) = @_;
	my $sub = 'molecular_weight';
	_sequence($sub, $seq);
	my $args = _args(\@opt, $sub, [], [qw(circular double_stranded monoisotopic type)]);
	my %r; # the options, each resolved once
	$r{type} = _seq_type($sub, $args, ['DNA', 'RNA', 'protein']);
	$r{circular} = $args->{circular} ? 1 : 0; # 1 = the molecule has no ends
	$r{double_stranded} = $args->{double_stranded} ? 1 : 0; # 1 = with the strand that pairs with it
	$r{monoisotopic} = $args->{monoisotopic} ? 1 : 0; # 1 = every atom its commonest isotope
	croak "$sub: a protein has one strand, so \"double_stranded\" can't be used with it" if $r{double_stranded} && $r{type} eq 'protein';
	my $table = $Weight{ $r{monoisotopic} ? 'monoisotopic' : 'average' };
	my $weight = $table->{ $r{type} };
	# whitespace is dropped and case ignored, as Biopython does
	(my $left = uc $seq) =~ s/\s+//g;
	my $len = length $left;
	croak "$sub: the sequence is empty" unless $len;
	# Each letter is counted by taking it out, so that what is left when every
	# letter of the table has gone is what the table has no weight for.
	my %n;
	$n{$_} = ($left =~ s/$Letter_re{$_}//g) || 0 for sort keys %{ $weight };
	croak "$sub: \"" . substr($left, 0, 1) . "\" has no weight as a letter of $r{type}; only " . join('', sort keys %{ $weight }) . ' do'
		if length $left;
	# a chain of $len residues has $len - 1 bonds, and a ring has $len
	my $bonds = ($len - 1 + $r{circular}) * $table->{water};
	my $total = -$bonds;
	$total += $n{$_} * $weight->{$_} for sort keys %{ $weight };
	if ($r{double_stranded}) {
		# the other strand has as many of a letter's partner as this has of it
		my %pair = $r{type} eq 'DNA' ? (A => 'T', C => 'G', G => 'C', T => 'A') : (A => 'U', C => 'G', G => 'C', U => 'A');
		$total -= $bonds;
		$total += $n{$_} * $weight->{ $pair{$_} } for sort keys %{ $weight };
	}
	$total;
}

# The pK of each group of a protein that takes or gives up a proton, for its
# charge at a pH. They are positive_pKs, negative_pKs, pKnterminal and
# pKcterminal of Biopython 1.87's Bio/SeqUtils/IsoelectricPoint.py, which
# takes them from Bjellqvist et al., Electrophoresis 14:1023-1031 (1993) and
# 15:529-539 (1994): the values ExPASy's Compute pI/Mw uses. "N" and "C" are
# the two ends of the chain, whose pK depends on the residue that is there:
# %Pk_n_end and %Pk_c_end give it for the residues that change it.
my @Pk_positive = (['N', 7.5], ['K', 10.0], ['R', 12.0], ['H', 5.98]);
my @Pk_negative = (['C_end', 3.55], ['D', 4.05], ['E', 4.45], ['C', 9.0], ['Y', 10.0]);
my %Pk_n_end = (A => 7.59, M => 7.0, S => 6.93, P => 8.36, T => 6.82, V => 7.44, E => 7.7);
my %Pk_c_end = (D => 4.55, E => 4.75);

# How many of each charged group the protein $seq has, with the pK of each of
# its ends, for _charge(): [[count, pK], ...] for the groups that carry a
# positive charge when they hold a proton, and the same for those that carry a
# negative one when they have lost it. Dies, for $sub, when $seq is empty.
sub _charged_groups {
	my ($sub, $seq) = @_;
	_sequence($sub, $seq);
	croak "$sub: the sequence is empty" unless length $seq;
	my %n = (
		N => 1, C_end => 1, # one of each end
		K => ($seq =~ tr/Kk//), R => ($seq =~ tr/Rr//), H => ($seq =~ tr/Hh//),
		D => ($seq =~ tr/Dd//), E => ($seq =~ tr/Ee//), C => ($seq =~ tr/Cc//), Y => ($seq =~ tr/Yy//),
	);
	my ($first, $last) = (uc substr($seq, 0, 1), uc substr($seq, -1));
	my @positive = map { [$n{ $_->[0] }, $_->[0] eq 'N' && exists $Pk_n_end{$first} ? $Pk_n_end{$first} : $_->[1]] } @Pk_positive;
	my @negative = map { [$n{ $_->[0] }, $_->[0] eq 'C_end' && exists $Pk_c_end{$last} ? $Pk_c_end{$last} : $_->[1]] } @Pk_negative;
	(\@positive, \@negative);
}

# The charge at $ph of a protein with _charged_groups()'s $positive and
# $negative: by the Henderson-Hasselbalch equation, a group of pK p holds its
# proton for 1 / (1 + 10 ** (pH - p)) of the time. The sums are made in
# Biopython's order, so that they round as its charge_at_pH() does.
sub _charge {
	my ($positive, $negative, $ph) = @_;
	my ($plus, $minus) = (0, 0);
	$plus += $_->[0] * (1 / (10 ** ($ph - $_->[1]) + 1)) for @{ $positive };
	$minus += $_->[0] * (1 / (10 ** ($_->[1] - $ph) + 1)) for @{ $negative };
	$plus - $minus;
}

sub protein_charge {
	my ($seq, $ph, @rest) = @_;
	my $sub = 'protein_charge';
	croak "$sub: takes two arguments, the sequence and the pH" if @rest;
	my ($positive, $negative) = _charged_groups($sub, $seq);
	require Scalar::Util;
	croak "$sub: the pH must be a number, not " . _what($ph)
		if !defined $ph || ref $ph || !Scalar::Util::looks_like_number($ph) || $ph != $ph || $ph - $ph != 0;
	_charge($positive, $negative, $ph);
}

sub isoelectric_point {
	my ($seq, @rest) = @_;
	my $sub = 'isoelectric_point';
	croak "$sub: takes one argument, the sequence" if @rest;
	my ($positive, $negative) = _charged_groups($sub, $seq);
	# Bisection, as IsoelectricPoint.pi() of Biopython 1.87 does it, from its
	# own starting interval: 4.05 is below the pI of a protein that is all
	# aspartate and 12 above that of one that is all arginine, and 7.775 is
	# its first guess. It stops when the interval is 0.0001 wide or less,
	# which is that function's limit, so the answer is good to 4 decimal
	# places.
	my ($ph, $low, $high) = (7.775, 4.05, 12);
	while ($high - $low > 0.0001) {
		if (_charge($positive, $negative, $ph) > 0) {
			$low = $ph;
		} else {
			$high = $ph;
		}
		$ph = ($low + $high) / 2;
	}
	$ph;
}

sub subseq {
	my ($seq, $start, $end, @rest) = @_;
	my $sub = 'subseq';
	croak "$sub: takes the sequence, where to start and where to end" if @rest;
	_sequence($sub, $seq);
	my $len = length $seq;
	$end //= $len;
	foreach my $p (['start', $start], ['end', $end]) {
		croak "$sub: the $p->[0] must be a whole number, 1 or more, not " . _what($p->[1])
			if !defined $p->[1] || ref $p->[1] || $p->[1] !~ /\A[1-9][0-9]*\z/;
	}
	croak "$sub: the start, $start, is after the end, $end" if $start > $end;
	croak "$sub: the end, $end, is beyond the sequence's length, $len" if $end > $len;
	substr $seq, $start - 1, $end - $start + 1;
}

# ---- FASTA index
#
# The index is samtools's .fai: a line for each sequence, of its name, its
# length, the byte in the file where it starts, how many bases each of its
# lines holds, and how many bytes each takes with its line ending. What is and
# is not a sequence that can be indexed is decided as fai_build_core() of
# htslib 1.25's faidx.c decides it, by Bioinf.xs's fai_scan() (since
# 2026-11-18, and by a readline loop here until then), and t/faidx.t checks
# the result against that library's own expected index.

# The index of the FASTA $file, read from the file itself, for $sub: the text
# of its .fai, with the sequences in the file's order.
sub _fai_scan {
	my ($sub, $file) = @_;
	open my $fh, '<:raw', $file or croak "$sub: can't read $file: $!";
	# $error is undef or one of fai_scan()'s, which Bioinf.xs lists at
	# fai_state; $line and $name are the line and the sequence it is in, and
	# $why is the system's reason for a read error
	my ($index, $dups, $error, $line, $name, $why) = _located(sub { _fai_build($fh) });
	carp "$sub: $file has more than one sequence named \"$_\", and the first is the one indexed" foreach @{ $dups };
	if (!defined $error) {
		close $fh or croak "$sub: can't read $file: $!";
		return $index;
	}
	croak "$sub: can't read $file: $why" if $error eq 'read';
	croak "$sub: the last sequence of $file has a defline and nothing more" if $error eq 'no_sequence';
	croak "$sub: $file has no sequences" if $error eq 'none';
	croak "$sub: line $line of $file comes before any defline" if $error eq 'before_defline';
	croak "$sub: line $line of $file follows a shorter line of \"$name\", and only a sequence's last line can be shorter than its others"
		if $error eq 'after_short';
	croak "$sub: line $line of $file is longer than the lines before it of \"$name\", and only a sequence's last line can differ"
		if $error eq 'longer';
	croak "_fai_scan: Bioinf.xs's fai_scan() gave \"$error\", which it has no message for"; # cannot happen
}

# The entries of a FASTA index, read a line at a time from $fh, which is the
# .fai $what of $sub, for the names in %$want alone: a hash ref of name =>
# [name, length, offset, line bases, line width], each the first line of its
# name. Every line is checked, wanted or not, so that a file that isn't an
# index dies whatever was asked of it.
sub _fai_entries {
	my ($sub, $fh, $what, $want) = @_;
	my %entry;
	my $any = 0; # 1 = the index has had a line
	while (defined(my $line = <$fh>)) {
		$line =~ s/\r?\n\z//;
		my @f = split /\t/, $line, -1;
		# a FASTQ's index has a sixth column, where its qualities start
		croak "$sub: line $. of $what isn't a line of a FASTA index: it needs a name, a length, an offset, a line's bases and a line's width"
			unless @f == 5 && !grep { !/\A[0-9]+\z/ } @f[1 .. 4];
		$any = 1;
		$entry{ $f[0] } //= [$f[0], map { 0 + $_ } @f[1 .. 4]] if $want->{ $f[0] };
	}
	croak "$sub: $what has no sequences" unless $any;
	\%entry;
}

# Dies, for $sub, unless $file is a FASTA that can be indexed: a file that is
# there, and not gzip's, since a byte of it cannot be sought.
sub _fai_file {
	my ($sub, $file) = @_;
	croak "$sub: the FASTA must be a file name, not " . _what($file) if !defined $file || ref $file || $file eq '';
	croak "$sub: \"$file\" doesn't exist or isn't a readable file" unless -f $file && -r _;
	croak "$sub: $file is compressed, and a place in it can't be sought; decompress it first" if $file =~ /\.(?:gz|bz2|xz|zst)\z/i;
}

sub fasta_index {
	my ($file, @rest) = @_;
	my $sub = 'fasta_index';
	croak "$sub: takes one argument, the FASTA file" if @rest;
	_fai_file($sub, $file);
	my $index = _fai_scan($sub, $file);
	my $fai = "$file.fai";
	open my $fh, '>:raw', $fai or croak "$sub: can't write $fai: $!";
	print {$fh} $index or croak "$sub: can't write $fai: $!";
	close $fh or croak "$sub: can't write $fai: $!";
	_wrote($fai, 46); # cyan
	$fai;
}

sub fasta_region {
	my ($file, @regions) = @_;
	my $sub = 'fasta_region';
	_fai_file($sub, $file);
	croak "$sub: needs at least one region, such as \"chr1:100-200\"" unless @regions;
	foreach my $r (@regions) {
		croak "$sub: a region must be a string, such as \"chr1:100-200\", not " . _what($r) if !defined $r || ref $r;
	}
	# Only the entries of the index that a region could name are kept: the
	# region whole, and the name before the colon of one that could be a range
	# (by the pattern below). Until 2026-11-18 every entry was, as an array of
	# five: for two regions of a FASTA of 1,000,000 contigs (perl 5.44.0), the
	# peak RSS was 458 MB with its .fai and 468 MB without, and is now 13 MB
	# and 194 MB, most of the last being fai_scan()'s hash of every name, which
	# it keeps to warn of a name used twice.
	my %asked; # each name a region could be of => 1
	foreach my $r (@regions) {
		$asked{$r} = 1;
		$asked{$1} = 1 if $r =~ /\A(.*):[0-9,]*(?:-[0-9,]*)?\z/s;
	}
	my $fai = "$file.fai";
	my ($by, $ifh);
	if (-f $fai) {
		open $ifh, '<', $fai or croak "$sub: can't read $fai: $!";
		$by = _fai_entries($sub, $ifh, $fai, \%asked);
		close $ifh or croak "$sub: can't read $fai: $!";
		# as htslib warns; -M is the age in days, so the older file has the larger
		carp "$sub: $fai is older than $file, and may no longer describe it" if -M $fai > -M $file;
	} else {
		my $index = _fai_scan($sub, $file);
		open $ifh, '<', \$index or croak "$sub: can't read the index of $file: $!";
		$by = _fai_entries($sub, $ifh, "the index of $file", \%asked);
		close $ifh or croak "$sub: can't read the index of $file: $!";
	}
	open my $fh, '<:raw', $file or croak "$sub: can't read $file: $!";
	my %seq;
	foreach my $region (@regions) {
		next if exists $seq{$region};
		# A region that is a sequence's whole name is that sequence, even when
		# it could be read as a name and a range, which is how htslib's
		# hts_parse_region() reads "HLA-A*01:01:01:01".
		my ($entry, $start, $end) = ($by->{$region});
		# "name:start-end", "name:start", "name:start-" and "name:-end", with
		# commas allowed in the numbers
		if (!$entry && $region =~ /\A(.*):([0-9,]*)(?:-([0-9,]*))?\z/s && $by->{$1}) {
			my ($name, $from, $to) = ($1, $2, $3 // '');
			tr/,//d for $from, $to;
			($entry, $start, $end) = ($by->{$name}, $from, $to) if length "$from$to";
		}
		croak "$sub: $file has no sequence named \"$region\"" . ($region =~ /:/ ? ', nor is it a range of one' : '') unless $entry;
		my (undef, $len, $offset, $bases, $width) = @{ $entry };
		$start = 1 unless defined $start && length $start;
		my $to_end = !(defined $end && length $end); # 1 = no end was given, so it runs to the sequence's
		croak "$sub: the region \"$region\" starts at 0, and positions are counted from 1" if $start < 1;
		croak "$sub: the region \"$region\" ends before it starts" if !$to_end && $end < $start;
		# a range that runs past the sequence's end is cut short there, as
		# samtools faidx cuts it; one that starts past it is empty
		$end = $len if $to_end || $end > $len;
		my $want = $end - $start + 1;
		if ($want <= 0) {
			$seq{$region} = '';
			next;
		}
		croak "$sub: $fai gives \"$entry->[0]\" lines of no bases" unless $bases > 0 && $width >= $bases;
		my $skip = $start - 1; # bases before the first one wanted
		my $in_line = $skip % $bases; # those of them on its own line
		my $from = $offset + ($skip - $in_line) / $bases * $width + $in_line;
		# the bases wanted and the line endings between them
		my $bytes = $want + int(($in_line + $want - 1) / $bases) * ($width - $bases);
		seek $fh, $from, 0 or croak "$sub: can't seek to byte $from of $file: $!";
		my $buffer = '';
		my $got = read $fh, $buffer, $bytes;
		croak "$sub: can't read $file: $!" unless defined $got;
		$buffer =~ tr/\x21-\x7e//cd;
		croak "$sub: the index gives \"$entry->[0]\" " . ($skip + $want) . " bases, and $file has fewer where it says they are"
			. (-f $fai ? "; $fai doesn't describe this file" : '') unless length($buffer) == $want;
		$seq{$region} = $buffer;
	}
	close $fh or croak "$sub: can't read $file: $!";
	\%seq;
}

# ---- motifs

# What each letter of a motif matches, as the inside of a character class: the
# bases an IUPAC nucleotide letter stands for (Biopython 1.87's
# ambiguous_dna_values, Bio/Data/IUPACData.py, with U beside T so that a motif
# written either way finds DNA and RNA alike), and the amino acids that B, Z
# and J stand for (its extended_protein_values). X of a protein motif is any
# one character, as it is when Bio::Tools::SeqPattern of BioPerl expands it.
my %Motif_class = (
	nucleotide => {
		A => 'A', C => 'C', G => 'G', T => 'TU', U => 'TU', M => 'AC', R => 'AG', W => 'ATU', S => 'CG', Y => 'CTU',
		K => 'GTU', V => 'ACG', H => 'ACTU', D => 'AGTU', B => 'CGTU', N => 'ACGTU',
	},
	protein => { (map { $_ => $_ } split //, 'ACDEFGHIKLMNOPQRSTUVWY'), B => 'DN', Z => 'EQ', J => 'IL' },
);

# The compiled pattern of each motif that motif_search has been given: by
# "type" and then the motif for a string of letters, and under "pattern" by its
# own text for a qr//.
my %Motif_re;

sub motif_search {
	my ($seq, $motif, @opt) = @_;
	my $sub = 'motif_search';
	_sequence($sub, $seq);
	my $args = _args(\@opt, $sub, [], [qw(strand type)]);
	my %r; # the options, each resolved once
	$r{type} = _seq_type($sub, $args, ['DNA', 'RNA', 'protein']);
	$r{strand} = _strand($sub, $args, '+'); # '+', '-' or 'both'
	croak "$sub: a protein has one strand, so \"strand\" can only be \"+\" with it" if $r{type} eq 'protein' && $r{strand} ne '+';
	# The motif as a pattern that matches without moving on, so that the next
	# search starts one letter along and hits that overlap are all found. It
	# is compiled once for each motif and kept in %Motif_re, since perl 5.32
	# leaks a pattern that is compiled at run time, and is used alone in the
	# match below.
	my $re;
	if (re::is_regexp($motif)) {
		$re = $Motif_re{pattern}{"$motif"} //= qr/(?=($motif))/;
	} elsif (defined $motif && !ref $motif && $Motif_re{ $r{type} }{$motif}) {
		$re = $Motif_re{ $r{type} }{$motif};
	} else {
		croak "$sub: the motif must be a string of IUPAC letters or a qr// pattern, not " . _what($motif)
			if !defined $motif || ref $motif || $motif eq '';
		my $class = $Motif_class{ $r{type} eq 'protein' ? 'protein' : 'nucleotide' };
		my $pattern = '';
		foreach my $letter (split //, uc $motif) {
			if ($r{type} eq 'protein' && $letter eq 'X') {
				$pattern .= '.';
				next;
			}
			croak "$sub: \"$letter\" of the motif \"$motif\" isn't a letter of $r{type}; a pattern is given as qr//"
				unless exists $class->{$letter};
			$pattern .= length $class->{$letter} > 1 ? "[$class->{$letter}]" : $class->{$letter};
		}
		$re = $Motif_re{ $r{type} }{$motif} = qr/(?=($pattern))/is;
	}
	my $len = length $seq;
	my @hit;
	foreach my $strand ($r{strand} eq 'both' ? (1, -1) : $r{strand} eq '+' ? 1 : -1) {
		my $text = $strand > 0 ? "$seq" : scalar reverse _complement($sub, $seq, type => $r{type});
		while ($text =~ /$re/g) {
			next unless $+[1] > $-[1]; # a pattern that can match nothing does, everywhere
			push @hit, {
				start => $strand > 0 ? $-[1] + 1 : $len - $+[1] + 1, end => $strand > 0 ? $+[1] : $len - $-[1],
				strand => $strand, match => $1,
			};
		}
	}
	[sort { $a->{start} <=> $b->{start} || $a->{end} <=> $b->{end} || $b->{strand} <=> $a->{strand} } @hit];
}

# ---- BLAST

sub get_best_alignment_hit {
	my ($json_file, $sort_criterion) = @_;
	$sort_criterion //= 'evalue';
	# For each query in one BLAST JSON file (-outfmt 15), that query's hits as
	# an array sorted best-first on $sort_criterion, one element per hit: the
	# hit's single best hsp plus the fields that say which subject it is.
	#
	# The hits are an array, not a hash on the hit title, because two hits can
	# share a title (one protein deposited under two accessions): in
	# identify.target/potato/new/f.sambunicum.json 76 hits carry 44 distinct
	# titles, and a hash kept 44.
	croak "get_best_alignment_hit: undef isn't a readable file" unless defined $json_file;
	croak "get_best_alignment_hit: \"$json_file\" doesn't exist or isn't a readable file" unless -f $json_file && -r _;
	# Which way is better for each numeric hsp field: -1 = smaller, 1 = larger.
	# The other hsp keys (hseq, qseq, midline, num, *_from/*_to) are content
	# or position, not quality.
	my %better = (align_len => 1, bit_score => 1, evalue => -1, gaps => -1, identity => 1, positive => 1, score => 1);
	my $direction = $better{$sort_criterion}
		// croak "get_best_alignment_hit: \"$sort_criterion\" isn't a sortable hsp field; use one of " . join(', ', sort keys %better);
	my $blast = _json_file('get_best_alignment_hit', $json_file);
	croak "get_best_alignment_hit: $json_file isn't a BLAST report in JSON (-outfmt 15): it has no \"BlastOutput2\" array"
		unless ref $blast eq 'HASH' && ref $blast->{BlastOutput2} eq 'ARRAY';
	my %alignments;
	foreach my $i (0 .. $#{ $blast->{BlastOutput2} }) {
		my $report = $blast->{BlastOutput2}[$i];
		my $search = ref $report eq 'HASH' && ref $report->{report} eq 'HASH' && ref $report->{report}{results} eq 'HASH'
			? $report->{report}{results}{search} : undef;
		croak "get_best_alignment_hit: report " . ($i + 1) . " of $json_file has no report.results.search" unless ref $search eq 'HASH';
		# BLAST titles a query by its defline, and a query with none by its
		# query_id alone.
		my $query = $search->{query_title} // $search->{query_id};
		croak "get_best_alignment_hit: report " . ($i + 1) . " of $json_file names no query: it has no query_title or query_id" unless defined $query;
		# Each hit's shape is checked before it is read. Up to 2026-11-10 "hits"
		# as an object died with perl's "Not an ARRAY reference", naming no
		# function, and an hsp with no bit_score, which BLAST always writes,
		# warned "uninitialized" each time it broke a tie; it now ties.
		my $listed = $search->{hits} // [];
		croak "get_best_alignment_hit: report " . ($i + 1) . " of $json_file has \"hits\" that isn't an array, but " . _what($listed)
			unless ref $listed eq 'ARRAY';
		my @hits;
		foreach my $h (0 .. $#{ $listed }) {
			my $hit = $listed->[$h];
			croak "get_best_alignment_hit: hit " . ($h + 1) . " of report " . ($i + 1) . " of $json_file isn't a hit, which is an object whose \"description\" and \"hsps\" are arrays of objects"
				unless ref $hit eq 'HASH' && ref($hit->{description} // []) eq 'ARRAY' && ref($hit->{hsps} // []) eq 'ARRAY'
					&& !grep { ref $_ ne 'HASH' } @{ $hit->{description} // [] }, @{ $hit->{hsps} // [] };
			my $first = ($hit->{description} // [])->[0] // {}; # the description the hit is named by; empty when it has none
			my $best; # undef until an hsp is seen; a hit with no hsps has nothing to record
			foreach my $hsp (@{ $hit->{hsps} // [] }) {
				croak "get_best_alignment_hit: an hsp of " . _what($first->{title}) . " in $json_file has no \"$sort_criterion\" to sort on"
					unless defined $hsp->{$sort_criterion};
				unless (defined $best) {
					$best = $hsp;
					next;
				}
				my $cmp = $direction * ($hsp->{$sort_criterion} <=> $best->{$sort_criterion});
				# BLAST rounds any strong e-value to 0, so ties are the rule; the bit score breaks them
				$cmp = ($hsp->{bit_score} // 0) <=> ($best->{bit_score} // 0) if $cmp == 0 && $sort_criterion ne 'bit_score';
				$best = $hsp if $cmp > 0;
			}
			next unless defined $best;
			# A shallow copy (an hsp holds only numbers and strings), so these
			# fields are not written into $blast. The hit's own "num" is not
			# merged, as it would shadow the hsp's; its "len" is the subject's
			# full length, so it arrives as "hit_len" beside the hsp's "align_len".
			# A hit has one description for each identical sequence in a
			# non-redundant database such as nr; it is named by the first, as
			# BLAST lists it, and every one is in "descriptions". Up to
			# 2026-10-17 a hit with more than one died.
			push @hits, { %{ $best },
				accession => $first->{accession},
				descriptions => [map { +{ %{ $_ } } } @{ $hit->{description} // [] }],
				hit_len   => $hit->{len},
				id        => $first->{id},
				title     => $first->{title},
			};
		}
		# Indices are sorted so the last tiebreak can be BLAST's own order; the
		# array runs best-first, hence $b before $a.
		my @order = sort {
			   ($direction * ($hits[$b]{$sort_criterion} <=> $hits[$a]{$sort_criterion}))
			|| (($hits[$b]{bit_score} // 0) <=> ($hits[$a]{bit_score} // 0))
			|| ($a <=> $b)
		} 0 .. $#hits;
		# Two queries of one title would leave only the second's hits, so that
		# is refused rather than lost silently.
		croak "get_best_alignment_hit: two queries in $json_file are both titled \"$query\"" if exists $alignments{$query};
		$alignments{$query} = [ @hits[@order] ];
	}
	\%alignments;
}

# ---- polygenic scores

# The rows of $frame, given to $sub as $what, as an array ref of hash refs, in
# whichever of Stats::LikeR's four shapes it comes: an array of hashes
# (read_table's default), a hash of hashes (its default for a VCF), a hash of
# arrays, or an array of arrays whose first row is the header. A row of an AoH or
# HoH is the frame's own hash, and is only read; one of a HoA or AoA is made
# here. With $labelled, also returns how a message names each row: "row 3",
# counting data rows from 1, or 'row "key"' for a hash of hashes, whose rows are
# then in key order so that the first bad one is always the same one.
sub _frame_rows {
	my ($sub, $what, $frame, $labelled) = @_;
	my $shapes = 'an array of hashes or of arrays, or a hash of hashes or of arrays, as Stats::LikeR\'s read_table returns';
	my (@rows, @labels);
	if (ref $frame eq 'ARRAY') {
		croak "$sub: \"$what\" has no rows" unless @{ $frame };
		if (ref $frame->[0] eq 'HASH') {
			@rows = @{ $frame };
		} elsif (ref $frame->[0] eq 'ARRAY') {
			my ($head, @data) = @{ $frame };
			croak "$sub: \"$what\" has a header and no rows" unless @data;
			foreach my $i (0 .. $#data) {
				croak "$sub: row " . ($i + 1) . " of \"$what\" must be an array ref, as its header is, not " . _what($data[$i])
					unless ref $data[$i] eq 'ARRAY';
				croak "$sub: row " . ($i + 1) . " of \"$what\" has " . scalar(@{ $data[$i] }) . ' fields, and its header ' . scalar(@{ $head })
					unless @{ $data[$i] } == @{ $head };
				my %row;
				@row{ @{ $head } } = @{ $data[$i] };
				push @rows, \%row;
			}
		} else {
			croak "$sub: \"$what\" must be $shapes, not an array whose first row is " . _what($frame->[0]);
		}
		@labels = map { "row $_" } 1 .. @rows if $labelled;
	} elsif (ref $frame eq 'HASH') {
		my ($key, $first) = each %{ $frame };
		keys %{ $frame }; # resets the iterator that each left part-way
		croak "$sub: \"$what\" has no rows" unless defined $key;
		if (ref $first eq 'HASH') {
			if ($labelled) {
				my @keys = sort keys %{ $frame };
				@rows = @{ $frame }{@keys};
				@labels = map { "row \"$_\"" } @keys;
			} else {
				@rows = values %{ $frame };
			}
		} elsif (ref $first eq 'ARRAY') {
			# sorted, so that the column a length is compared with, and named
			# when it differs, is not the hash's order
			my @cols = sort keys %{ $frame };
			foreach my $c (@cols) {
				croak "$sub: column \"$c\" of \"$what\" must be an array ref, as \"$key\" is, not " . _what($frame->{$c})
					unless ref $frame->{$c} eq 'ARRAY';
				my $n = @{ $frame->{$c} };
				croak "$sub: column \"$c\" of \"$what\" has $n value" . ($n == 1 ? '' : 's') . ", and \"$cols[0]\" " . scalar(@{ $frame->{ $cols[0] } })
					unless $n == @{ $frame->{ $cols[0] } };
			}
			foreach my $i (0 .. $#{ $first }) {
				push @rows, { map { $_ => $frame->{$_}[$i] } @cols };
			}
			croak "$sub: \"$what\" has no rows" unless @rows;
			@labels = map { "row $_" } 1 .. @rows if $labelled;
		} else {
			croak "$sub: \"$what\" must be $shapes, not a hash whose \"$key\" is " . _what($first);
		}
	} else {
		croak "$sub: \"$what\" must be $shapes, not " . _what($frame);
	}
	foreach my $i (0 .. $#rows) {
		croak "$sub: row " . ($i + 1) . " of \"$what\" must be a hash ref, not " . _what($rows[$i]) unless ref $rows[$i] eq 'HASH';
	}
	$labelled ? (\@rows, \@labels) : \@rows;
}

# A chromosome's name as a VCF, PLINK 2 and a scoring file are compared on: in
# upper case, without UCSC's "chr" prefix (GRCh37's own names, and the PGS
# Catalog's, have none), with PLINK's numeric codes for the sex and
# mitochondrial chromosomes and UCSC's "M" named as Ensembl names them, and with
# X's pseudo-autosomal regions, which PLINK 2 names PAR1 and PAR2 (or XY, its
# 25) once --split-par has split them off, taken as X.
my %Chrom_alias = (23 => 'X', 24 => 'Y', 25 => 'X', 26 => 'MT', M => 'MT', PAR1 => 'X', PAR2 => 'X', XY => 'X');
sub _chrom {
	my $c = uc $_[0];
	$c =~ s/\ACHR//;
	$Chrom_alias{$c} // $c;
}

# A decimal number, as an effect_weight must be. Infinity and NaN, which
# looks_like_number would take, are left out, as either would make every score
# the same non-number.
my $Number = qr/\A[-+]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][-+]?[0-9]+)?\z/;

# The rows of the option $what ("weights" for pgs_score, "model" for
# trait_predict) one at a time, each a hash ref with how a message names it,
# and the column names: from a data frame (see _frame_rows), or read from a
# tab-separated file a line at a time, so that a score of millions of variants
# is never held whole. An empty field of a file is '', where read_table gives
# undef; every check below treats the two alike.
sub _weight_rows {
	my ($sub, $weights, $what) = @_;
	$what //= 'weights';
	if (ref $weights) {
		my ($rows, $labels) = _frame_rows($sub, $what, $weights, 1);
		my $i = 0;
		return (sub { $i < @{ $rows } ? ($rows->[$i], $labels->[$i++]) : () }, [keys %{ $rows->[0] }]);
	}
	croak "$sub: \"$what\" file \"$weights\" doesn't exist or isn't readable" unless -f $weights && -r _;
	my $fh;
	if ($weights =~ /\.gz\z/i) {
		require IO::Uncompress::Gunzip;
		$fh = IO::Uncompress::Gunzip->new($weights, MultiStream => 1)
			or croak "$sub: can't read $weights: $IO::Uncompress::Gunzip::GunzipError";
	} else {
		open $fh, '<:raw', $weights or croak "$sub: can't read $weights: $!";
	}
	my $n = 0; # rows read so far
	# IO::Uncompress::Gunzip ends a truncated or corrupt stream as if it were
	# the end of the file, and says so only in its error(), which reading a
	# .gz to the end therefore checks
	my $whole = sub {
		return unless ref $fh ne 'GLOB' && $fh->error;
		croak "$sub: \"$what\" file $weights ends early or is corrupt, " . ($n ? "after row $n" : 'before its first row') . ': ' . $fh->error;
	};
	my $head;
	while (defined(my $line = <$fh>)) {
		$line =~ s/\r?\n\z//;
		next if $line eq '' || $line =~ /\A#/;
		$head = $line;
		last;
	}
	$whole->() unless defined $head;
	croak "$sub: \"$what\" file $weights has no header line" unless defined $head;
	my @cols = split /\t/, $head, -1;
	my $next = sub {
		while (defined(my $line = <$fh>)) {
			$line =~ s/\r?\n\z//;
			next if $line eq '';
			my %row;
			@row{@cols} = split /\t/, $line, -1;
			return (\%row, 'row ' . ++$n);
		}
		$whole->();
		return;
	};
	($next, \@cols);
}

# The data frame $frame written to $file as a VCF of GT alone, for PLINK 2 to
# read. Its rows are sorted by chromosome and position, as PLINK 2 needs them
# to be, under the names _chrom gives the chromosomes, so that "chr1" and "1"
# are one chromosome. A row with no CHROM, POS, REF or ALT is left out, and so
# matches nothing, and a missing or empty GT is written "./.". Returns how many
# rows were written.
sub _frame_vcf {
	my ($sub, $frame, $file, $match) = @_;
	my $rows = _frame_rows($sub, 'vcf', $frame);
	# read_table names each sample's genotype column "<sample>.GT" when it splits
	# the sample columns by FORMAT, as it does by default for a VCF
	my @samples = sort map { /\A(.+)\.GT\z/s ? $1 : () } keys %{ $rows->[0] };
	croak "$sub: \"vcf\" has no <sample>.GT column; read the VCF with read_table's default of explode => 1" unless @samples;
	my @absent = grep { !exists $rows->[0]{$_} } qw(CHROM POS REF ALT), $match eq 'id' ? 'ID' : ();
	croak "$sub: \"vcf\" has no " . join(', ', map { "\"$_\"" } @absent) . ' column' . (@absent > 1 ? 's' : '') if @absent;
	my @keep = sort { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] }
		map { [_chrom($_->{CHROM}), $_->{POS}, $_] }
		grep { defined $_->{CHROM} && length $_->{CHROM} && defined $_->{POS} && $_->{POS} =~ /\A[1-9][0-9]*\z/
			&& defined $_->{REF} && length $_->{REF} && defined $_->{ALT} && length $_->{ALT} } @{ $rows };
	open my $fh, '>:raw', $file or croak "_frame_vcf: can't write $file: $!";
	print {$fh} "##fileformat=VCFv4.2\n##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n",
		join("\t", '#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT), @samples), "\n";
	foreach my $k (@keep) {
		my $r = $k->[2];
		my $id = defined $r->{ID} && length $r->{ID} ? $r->{ID} : '.';
		print {$fh} join("\t", $k->[0], $k->[1], $id, $r->{REF}, $r->{ALT}, '.', '.', '.', 'GT',
			map { my $gt = $r->{"$_.GT"}; defined $gt && length $gt ? $gt : './.' } @samples), "\n";
	}
	close $fh or croak "_frame_vcf: can't write $file: $!";
	scalar @keep;
}

# plink2 run with @args for $sub, its output in $dir/plink2.out rather than on
# the caller's terminal; a failure dies with the lines of it that say why.
sub _plink2 {
	my ($sub, $plink2, $dir, @args) = @_;
	my $log = File::Spec->catfile($dir, 'plink2.out');
	open my $out, '>&', \*STDOUT or croak "_plink2: can't save STDOUT: $!";
	open my $err, '>&', \*STDERR or croak "_plink2: can't save STDERR: $!";
	# Puts the caller's STDOUT and STDERR back, so that a failure to redirect
	# them does not leave the rest of the caller's output in the log.
	my $restore = sub {
		open STDOUT, '>&', $out or croak "_plink2: can't restore STDOUT: $!";
		open STDERR, '>&', $err or croak "_plink2: can't restore STDERR: $!";
	};
	unless (open STDOUT, '>', $log) {
		my $why = "$!";
		$restore->();
		croak "_plink2: can't write $log: $why";
	}
	unless (open STDERR, '>&', \*STDOUT) {
		my $why = "$!";
		$restore->();
		croak "_plink2: can't send STDERR to $log: $why";
	}
	my $rc = system($plink2, @args);
	# taken before $restore's opens can set $! to their own errors
	my ($status, $errno) = ($?, "$!");
	$restore->();
	return if $rc == 0;
	my $why = $status == -1 ? "it didn't start: $errno" : $status & 127 ? 'killed by signal ' . ($status & 127) : 'exit ' . ($status >> 8);
	# what PLINK 2 says from its "Error:" on, or else its last line; it
	# rewrites its progress lines with a CR
	my @said;
	if (open my $fh, '<', $log) {
		# less the "End time:" it ends every run with, which says nothing of why
		@said = grep { /\S/ && !/\AEnd time: / } map { (my $l = $_) =~ s/\s+\z//; $l } map { split /\r/ } <$fh>;
	}
	my ($first) = grep { $said[$_] =~ /\AError/ } 0 .. $#said;
	my $said = join ' ', defined $first ? @said[$first .. $#said] : @said ? $said[-1] : 'nothing';
	croak "$sub: \"$plink2 @args\" failed ($why): $said";
}

# Dies unless "memory" and "threads" of $sub's $args are numbers PLINK 2
# takes, or were not given. Returns plink2's arguments for them, after the
# --allow-extra-chr that every run here passes, so that a contig PLINK 2 has no
# code for (chrUn_..., say) is read rather than refused.
sub _plink2_resources {
	my ($sub, $args) = @_;
	foreach my $k (qw(memory threads)) {
		# undef = PLINK 2's own default: half the machine's memory, every CPU
		croak "$sub: \"$k\" must be a whole number, 1 or more, not " . _what($args->{$k})
			if defined $args->{$k} && (ref $args->{$k} || $args->{$k} !~ /\A[1-9][0-9]*\z/);
	}
	my ($memory, $threads) = @{ $args }{qw(memory threads)};
	# PLINK 2 v2.0.0-a.7.13LM refuses less: "Invalid --memory argument '256' (minimum 640)"
	croak "$sub: \"memory\" must be 640 or more (MiB), the least PLINK 2 takes, not $memory" if defined $memory && $memory < 640;
	('--allow-extra-chr', (defined $memory ? ('--memory', $memory) : ()), (defined $threads ? ('--threads', $threads) : ()));
}

# plink2's arguments that read "vcf" of $sub, a file, which dies unless it is
# one PLINK 2 reads by its name; or () for a data frame, which the caller
# writes to a VCF with _frame_vcf once its other arguments have been checked.
sub _plink2_input {
	my ($sub, $vcf) = @_;
	if (!ref $vcf) {
		croak "$sub: \"vcf\" file \"$vcf\" doesn't exist or isn't readable" unless -f $vcf && -r _;
		if ($vcf =~ /\A(.*)\.pgen\z/is) {
			my $prefix = $1;
			croak "$sub: \"vcf\" $vcf has no $prefix.pvar (or .pvar.zst) beside it" unless grep { -f "$prefix.$_" } qw(pvar pvar.zst);
			croak "$sub: \"vcf\" $vcf has no $prefix.psam beside it" unless -f "$prefix.psam";
			return ('--pfile', $prefix);
		}
		return ('--bcf', $vcf) if $vcf =~ /\.bcf\z/i;
		return ('--vcf', $vcf) if $vcf =~ /\.vcf(?:\.b?gz)?\z/i;
		croak "$sub: \"vcf\" file $vcf must end in .vcf, .vcf.gz, .vcf.bgz, .bcf or .pgen, as PLINK 2 reads it by its name";
	}
	croak "$sub: \"vcf\" must be a VCF, BCF or PLINK 2 .pgen file, or a data frame, not " . _what($vcf)
		unless ref $vcf eq 'ARRAY' || ref $vcf eq 'HASH';
	();
}

# Alien::Bioinf's plink2, for $sub, or a death that says why there is none.
sub _plink2_program {
	my ($sub) = @_;
	my $plink2 = eval { _alien($sub)->plink2 };
	return $plink2 if defined $plink2;
	(my $why = $@) =~ s/ at \S+ line \d+\.?\n?\z//;
	croak "$sub: needs PLINK 2, which Alien::Bioinf installs, and hasn't here: $why";
}

# The IIDs of the .psam $file, in its order, for $sub, which returns its
# $what (such as "scores") keyed by IID. PLINK 2 tells samples apart by FID and
# IID together, so two samples that share an IID, in different families, die
# here, rather than having their results added into one.
sub _psam_iids {
	my ($sub, $file, $what) = @_;
	open my $psam, '<', $file or croak "$sub: can't read $file: $!";
	my ($iid, $fid); # the columns of the IID and of the FID, which a .psam need not have
	my %family; # IID => its FID, or '' with no FID column
	my @samples;
	while (my $line = <$psam>) {
		chomp $line;
		my @f = split /\t/, $line;
		if ($line =~ /\A#/) {
			($iid) = grep { $f[$_] =~ /\A#?IID\z/ } 0 .. $#f;
			($fid) = grep { $f[$_] =~ /\A#?FID\z/ } 0 .. $#f;
			next;
		}
		my $id = $f[$iid // 0];
		my $family = defined $fid ? $f[$fid] : '';
		croak "$sub: \"vcf\" has two samples whose IID is \"$id\"" . (defined $fid ? ", in families \"$family{$id}\" and \"$family\"" : '')
			. "; the $what are returned by IID, so each sample's must be unique" if exists $family{$id};
		$family{$id} = $family;
		push @samples, $id;
	}
	close $psam;
	@samples;
}

sub pgs_score {
	my $sub = 'pgs_score';
	my $args = _args(\@_, $sub, [qw(vcf weights)], [qw(build match memory threads)]);
	my %r;
	$r{match} = $args->{match} // 'position'; # 'position' = CHROM and POS against chr_name and chr_position; 'id' = ID against rsID
	croak "$sub: \"match\" must be \"position\" or \"id\", not " . _what($r{match})
		unless !ref $r{match} && ($r{match} eq 'position' || $r{match} eq 'id');
	$r{build} = $args->{build}; # undef = the sex chromosomes are left out; hg19, b37, hg38 or b38 = PLINK 2 reads them, with X's pseudo-autosomal regions placed for that build
	croak "$sub: \"build\" must be hg19, b37, hg38 or b38, not " . _what($r{build})
		if defined $r{build} && (ref $r{build} || $r{build} !~ /\A(?:hg19|b37|hg38|b38)\z/);
	my @common = _plink2_resources($sub, $args);
	my $vcf = $args->{vcf};
	my @input = _plink2_input($sub, $vcf); # plink2's arguments that read the genotypes; set below for a data frame

	my ($next, $cols) = _weight_rows($sub, $args->{weights});
	my %have = map { $_ => 1 } @{ $cols };
	# A harmonized (hmPOS) scoring file has its variants on the build its name
	# gives in the hm_ columns, and on the author's build in chr_name,
	# chr_position and rsID, so the hm_ columns are the ones read when present.
	my @key_cols = $r{match} eq 'id' ? ($have{hm_rsID} ? 'hm_rsID' : 'rsID')
		: $have{hm_pos} ? qw(hm_chr hm_pos) : qw(chr_name chr_position);
	my $chr_col = $have{hm_chr} ? 'hm_chr' : $have{chr_name} ? 'chr_name' : undef;
	my @absent = grep { !$have{$_} } @key_cols, 'effect_allele', 'effect_weight';
	croak "$sub: \"weights\" has no " . join(', ', map { "\"$_\"" } @absent) . ' column' . (@absent > 1 ? 's' : '')
		. ', which a PGS Catalog scoring file has' if @absent;
	# Only an additive weight is a weight times the dosage. These columns of the
	# PGS Catalog's format 2.0 mark a variant that is scored some other way, which
	# this function would get wrong, so a variant marked so is refused.
	my @flags = grep { $have{$_} } qw(is_haplotype is_diplotype is_interaction is_dominant is_recessive);
	my @dosage_weights = grep { $have{$_} } qw(dosage_0_weight dosage_1_weight dosage_2_weight);
	# removed as pgs_score returns, or, after an error, as the program ends;
	# File::Temp's newdir, which would do both, is newer than 5.10.0's File::Temp
	require File::Temp;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my $regions = File::Spec->catfile($dir, 'regions.txt');
	open my $rfh, '>', $regions or croak "$sub: can't write $regions: $!";
	# Each row of weights is kept as a line "effect\tother\tweight\n" of $rows,
	# the alleles in upper case and the weight as written, and where its line
	# starts is packed into $row_at as a C double, exact to 2^53 on every perl.
	# Until 2026-11-18 each row was a perl string of its own, of 82 bytes on
	# perl 5.44.0, and these take 8 and the line. With @use an array, the bit vector $taken and
	# %at freed early (all below), a score of 1,000,000 variants against a VCF
	# of all of them peaked at 325 MB rather than 629 MB (perl 5.44.0, on
	# 2026-11-18), and scored the same.
	my ($rows, $row_at, $n_rows) = ('', '', 0);
	my $row = sub { # row $_[0] of weights as (effect, other, weight)
		my $from = unpack 'd', substr $row_at, 8 * $_[0], 8;
		split /\t/, substr($rows, $from, index($rows, "\n", $from) - $from), -1;
	};
	my %at;     # key (CHROM:POS or rsID) => the rows of weights at it, joined by commas
	my %chroms; # chromosome, as _chrom names it => 1, for each of the rows' chromosomes
	while (my ($w, $label) = $next->()) {
		foreach my $c (@flags) {
			croak "$sub: $label of \"weights\" has $c \"$w->{$c}\", and only additive weights can be scored"
				if defined $w->{$c} && $w->{$c} =~ /\A(?:true|1)\z/i;
		}
		foreach my $c (@dosage_weights) {
			croak "$sub: $label of \"weights\" has a $c, and only additive weights can be scored"
				if defined $w->{$c} && length $w->{$c};
		}
		my ($e, $o, $weight) = @{ $w }{qw(effect_allele other_allele effect_weight)};
		croak "$sub: $label of \"weights\" has no effect_allele" unless defined $e && length $e;
		croak "$sub: $label of \"weights\" has effect_weight " . _what($weight) . ', which isn\'t a number'
			unless defined $weight && !ref $weight && $weight =~ $Number;
		my $i = $n_rows++;
		$row_at .= pack 'd', length $rows;
		$rows .= join("\t", uc $e, defined $o && length $o ? uc $o : '', $weight) . "\n";
		my $chr = defined $chr_col && defined $w->{$chr_col} && length $w->{$chr_col} ? _chrom($w->{$chr_col}) : undef;
		my $key;
		if ($r{match} eq 'id') {
			$key = $w->{ $key_cols[0] };
		} else {
			my $pos = $w->{ $key_cols[1] };
			# A harmonized file leaves hm_chr and hm_pos empty for a variant it
			# could not place, and that variant is then not found, rather than an error.
			if (defined $chr && defined $pos && length $pos) {
				croak "$sub: $label of \"weights\" has $key_cols[1] \"$pos\", which isn't a position"
					unless $pos =~ /\A[1-9][0-9]*\z/;
				$key = "$chr:$pos";
				# X's positions are given under PAR1 and PAR2 too, which --split-par
				# may have moved them to
				print {$rfh} map { "$_\t$pos\t$pos\n" } $chr, $chr eq 'X' ? qw(PAR1 PAR2) : ();
			}
		}
		$chroms{$chr} = 1 if defined $chr;
		$at{$key} = defined $at{$key} ? "$at{$key},$i" : $i if defined $key && length $key;
	}
	close $rfh or croak "$sub: can't write $regions: $!";
	croak "$sub: \"weights\" has no rows" unless $n_rows;
	my @sex = grep { $chroms{$_} } qw(X Y);
	croak "$sub: \"weights\" has variants on " . join(' and ', @sex) . ', which PLINK 2 reads only when "build" says where X\'s'
		. ' pseudo-autosomal regions are: hg19 (b37) or hg38 (b38)' if @sex && !defined $r{build};
	_frame_vcf($sub, $vcf, File::Spec->catfile($dir, 'frame.vcf'), $r{match}) if ref $vcf;
	@input = ('--vcf', File::Spec->catfile($dir, 'frame.vcf')) if ref $vcf;

	my $plink2 = _plink2_program($sub);
	push @input, '--vcf-half-call', 'missing' unless $input[0] eq '--pfile';
	# The samples, each of unknown sex, written by PLINK 2 without reading the
	# sex chromosomes, which it would refuse to without each one's sex.
	my $samples = File::Spec->catfile($dir, 'samples');
	my @psam = ('--not-chr', 'X,Y,XY', '--make-just-psam', '--out', $samples);
	unless (eval { _plink2($sub, $plink2, $dir, @input, @common, @psam); 1 }) {
		# PLINK 2 refuses a single-sample VCF with no 0/0 among its first 1,000
		# called genotypes, as one that lists only the sites where the sample
		# carries an ALT allele; scored, every other variant is missing.
		# die, not croak, which would give _plink2's message a second "at ... line"
		die $@ unless $@ =~ /contain at least one ALT allele/;
		carp "$sub: \"vcf\" lists only the sites where its sample carries an ALT allele, so every variant where it matches"
			. ' the reference is missing, and its score is not comparable with one from a VCF of every site';
		push @input, '--vcf-allow-no-nonvar';
		_plink2($sub, $plink2, $dir, @input, @common, @psam);
	}
	my @import = (@input, @common);
	# Only the chromosomes the score uses are read, or, where it gives none
	# (matching by ID alone), all but the sex chromosomes, unless "build" says
	# where X's pseudo-autosomal regions are. PLINK 2 needs that, and each
	# sample's sex, before it reads X at all; the sex is given as unknown, which
	# counts a haploid call on X as homozygous.
	if (%chroms) {
		push @import, '--chr', join ',', sort(keys %chroms), $chroms{X} ? qw(PAR1 PAR2) : ();
	} elsif (!defined $r{build}) {
		push @import, '--not-chr', 'X,Y,XY';
	}
	push @import, '--psam', "$samples.psam", '--split-par', $r{build} if defined $r{build} && $input[0] ne '--pfile';
	push @import, '--extract', 'bed1', $regions if $r{match} eq 'position';
	my $g = File::Spec->catfile($dir, 'g');
	# PLINK 2 exits 13 when none of the score's positions is in the VCF, and 7
	# when none of its chromosomes is (a VCF, filtered by --chr as it is
	# imported; a --pfile is filtered later, and exits 13). Either is a result
	# here: every variant is missing.
	my $none = eval { _plink2($sub, $plink2, $dir, @import, '--make-pgen', '--out', $g); 0 }
		// ($@ =~ /\((?:exit 13\): Error: No variants remaining|exit 7\): Error: All \d+ variant\(s\) in --vcf file excluded by --chr)/ ? 1 : die $@);

	my @samples = _psam_iids($sub, "$samples.psam", 'scores'); # in PLINK 2's order

	# The .pvar a record at a time, matched against the rows of weights, and
	# written again with each record's ID made v1, v2, ..., which --score finds
	# it by, since a VCF's own IDs are often "." and need not be unique.
	my $found = ''; # bit $i set: row $i of weights is at a position (or ID) of the VCF
	my @use;        # row $i => "record number\tA1 as the record writes it\tits CHROM:POS:REF:ALT\t1, or 0 when the record lacks the effect allele", for the record whose alleles agree with it; an array, whose slot is 8 bytes a row, where a hash gave each a key and an entry too
	my ($in, $out);
	unless ($none) {
		open $in, '<', "$g.pvar" or croak "$sub: can't read $g.pvar: $!";
		open $out, '>', "$g.ids.pvar" or croak "$sub: can't write $g.ids.pvar: $!";
	}
	my ($n, %col) = (0);
	while (!$none && defined(my $line = <$in>)) {
		if ($line =~ /\A##/) {
			print {$out} $line;
			next;
		}
		chomp $line;
		my @f = split /\t/, $line, -1;
		if ($line =~ /\A#CHROM/) {
			%col = map { $f[$_] => $_ } 0 .. $#f;
			print {$out} "$line\n";
			next;
		}
		$n++;
		my ($chrom, $pos, $id, $ref, $alt) = @f[ @col{'#CHROM', 'POS', 'ID', 'REF', 'ALT'} ];
		$f[ $col{ID} ] = "v$n";
		print {$out} join("\t", @f), "\n";
		my @keys = $r{match} eq 'id' ? grep { length && $_ ne '.' } split(/;/, $id) : (_chrom($chrom) . ":$pos");
		my @here = map { split /,/, $at{$_} // '' } @keys;
		next unless @here;
		# An ALT of "." is a site with no alternate allele, which a VCF of every
		# site writes where the sample matches the reference.
		my @alleles = ($ref, $alt eq '.' ? () : split /,/, $alt);
		my %named; # allele in upper case => as the record writes it
		$named{ uc $_ } //= $_ foreach @alleles;
		my $sort = join ':', $chrom, $pos, $ref, $alt;
		foreach my $i (@here) {
			vec($found, $i, 1) = 1;
			my ($e, $o) = $row->($i);
			# The alleles agree when both of the variant's are the record's, or,
			# for a record with no ALT, when either is its REF.
			next unless @alleles == 1
				? $e eq uc $ref || (length $o && $o eq uc $ref)
				: defined $named{$e} && (!length $o || defined $named{$o});
			# Of two records that agree, as a multi-allelic site split in two
			# can give, the one whose "CHROM:POS:REF:ALT" sorts first as a
			# string is used, so that the order of the file does not decide it.
			# That is not genomic order ("1:100" sorts before "1:99"), and need
			# not be: the choice only has to be the same every time.
			next if defined $use[$i] && (split /\t/, $use[$i])[2] le $sort;
			# An effect allele the record lacks (its REF being the other allele)
			# has no copies; it is given as the REF with a weight of 0, which
			# counts the sample's alleles there and adds nothing.
			$use[$i] = join "\t", $n, $named{$e} // $ref, $sort, defined $named{$e} ? 1 : 0;
		}
	}
	unless ($none) {
		close $in;
		close $out or croak "$sub: can't write $g.ids.pvar: $!";
	}
	undef %at; # no longer needed, and the largest of these, with a key and an entry for every row

	my %score = map { $_ => { alleles => 0, mismatched => 0, missing => 0, score => 0, variants => 0 } } @samples;
	my $agree = grep { defined } @use;
	my $disagree = unpack('%32b*', $found) - $agree;
	# --score takes one line for each record, so a record that two rows of
	# weights fall on is scored in a second pass, and so on.
	# Pass $p's score file and list of records are written as the rows are
	# read, rather than gathered first, so that a score of millions of variants
	# is not held twice.
	# A record is in pass 0 when it is the first row's to take it, and in pass
	# $again{record} when it is a later one's; nearly every record is taken by
	# one row alone, so a bit for each is all that most need.
	my $taken = ''; # bit $rec set: a row has taken record $rec
	my %again;      # record => how many rows have taken it, less 1, for a record taken by more than one
	my @pass;       # pass => [its file's prefix, score file handle, ID list handle]
	foreach my $i (grep { defined $use[$_] } 0 .. $#use) {
		my ($rec, $a1, undef, $has) = split /\t/, $use[$i];
		my $p = 0;
		if (vec $taken, $rec, 1) {
			$p = ++$again{$rec};
		} else {
			vec($taken, $rec, 1) = 1;
		}
		unless ($pass[$p]) {
			my $file = File::Spec->catfile($dir, "score$p");
			open my $fh, '>', "$file.txt" or croak "$sub: can't write $file.txt: $!";
			open my $ids, '>', "$file.ids" or croak "$sub: can't write $file.ids: $!";
			print {$fh} "ID\tA1\tWEIGHT\n";
			$pass[$p] = [$file, $fh, $ids];
		}
		print { $pass[$p][1] } "v$rec\t$a1\t", ($has ? ($row->($i))[2] : 0), "\n";
		print { $pass[$p][2] } "v$rec\n";
	}
	undef $taken;
	undef %again;
	undef @use;
	foreach my $pass (@pass) {
		my ($file, $fh, $ids) = @{ $pass };
		close $fh or croak "$sub: can't write $file.txt: $!";
		close $ids or croak "$sub: can't write $file.ids: $!";
		_plink2($sub, $plink2, $dir, '--pgen', "$g.pgen", '--pvar', "$g.ids.pvar", '--psam', "$g.psam", @common,
			'--extract', "$file.ids", '--score', "$file.txt", 1, 2, 3, 'header', 'no-mean-imputation', 'cols=+scoresums',
			'--missing', 'sample-only', '--out', $file);
		# .smiss's OBS_CT is how many genotypes there were to see, and
		# MISSING_CT how many of those were missing, so a sample's variants are
		# the one less the other.
		foreach my $part (['sscore', ALLELE_CT => ['alleles', 1], SCORE1_SUM => ['score', 1]],
			['smiss', OBS_CT => ['variants', 1], MISSING_CT => ['variants', -1]]) {
			my ($ext, %field) = @{ $part };
			open my $res, '<', "$file.$ext" or croak "$sub: can't read $file.$ext: $!";
			chomp(my $head = <$res>);
			my @h = split /\t/, $head;
			my %at_col = map { $h[$_] => $_ } 0 .. $#h;
			my $id_col = $at_col{'#IID'} // $at_col{IID};
			while (my $line = <$res>) {
				chomp $line;
				my @f = split /\t/, $line;
				$score{ $f[$id_col] }{ $field{$_}[0] } += $field{$_}[1] * $f[ $at_col{$_} ] foreach keys %field;
			}
			close $res;
		}
	}
	foreach my $s (values %score) {
		$s->{missing} = $n_rows - $s->{variants};
		$s->{mismatched} = $disagree;
		$s->{average} = $s->{alleles} ? $s->{score} / $s->{alleles} : undef;
	}
	# On 2026-10-17, PGS000138 (whose header says genome_build=NR) against a
	# GRCh37 genome had 12,015 of its 22,274 variants at their positions, and
	# the alleles agreed at all 12,015; with every position moved on one base,
	# as a stand-in for the wrong build, they agreed at 9 of the 58 found.
	# Disagreement at more than half the variants found is the second case.
	if (!$agree) {
		carp "$sub: none of the $n_rows" . ' variants of "weights" was found in "vcf" with its alleles; check that the two'
			. ($r{match} eq 'id' ? ' use the same rsIDs' : ' are on the same genome build and name chromosomes alike');
	} elsif ($disagree > $agree) {
		carp "$sub: the alleles disagree at $disagree of the " . ($agree + $disagree) . ' variants of "weights" found in "vcf"; check that'
			. ' the two are on the same ' . ($r{match} eq 'id' ? 'strand' : 'genome build');
	}
	require File::Path;
	File::Path::rmtree($dir);
	\%score;
}

# ---- population genetics, by PLINK 2 (since 2026-11-17)

# The genotypes of "vcf" of $sub, given as plink2's arguments @$input (from
# _plink2_input) and @$common (from _plink2_resources), made a PLINK 2 fileset
# in $dir of the autosomes' biallelic variants alone, with each variant's ID
# made v1, v2, ... in the fileset's order, which every command's output then
# names it by: a VCF's own IDs are often "." and need not be unique, and
# --indep-pairwise refuses IDs that are not. The sex chromosomes are left out,
# since PLINK 2 reads them only once told each sample's sex and where X's
# pseudo-autosomal regions are. Returns plink2's arguments that read the
# fileset, the variants in its order, for _popgen_variant to look up, and the
# samples' IIDs in its order, $what being what $sub returns by IID.
#
# The variants are a hash ref, whose "count" is how many there are. With
# $keep, each one's CHROM, POS, ID, REF and ALT are also written, a line of
# them for each, to $dir/variants.tsv ("file"), and where each line starts in
# it is packed into "offsets" as a C double, exact to 2^53 bytes on every
# perl. Until 2026-11-18 they were held as a perl string each, 98 bytes a
# variant (measured on perl 5.44.0), which for the 70 million or so of a
# whole-genome cohort is about 7 GB; the offsets take 8 bytes a variant, and
# pca, which reports only the count, keeps nothing.
sub _popgen_genotypes {
	my ($sub, $vcf, $input, $common, $plink2, $dir, $what, $keep) = @_;
	my @input = @{ $input };
	if (ref $vcf) {
		my $file = File::Spec->catfile($dir, 'frame.vcf');
		_frame_vcf($sub, $vcf, $file, 'position');
		@input = ('--vcf', $file);
	}
	push @input, '--vcf-half-call', 'missing' unless $input[0] eq '--pfile';
	my $g = File::Spec->catfile($dir, 'g');
	# PLINK 2 exits 7 when a VCF has nothing on the autosomes (it filters by
	# --autosome as it reads), and 13 when a fileset has none left
	unless (eval { _plink2($sub, $plink2, $dir, @input, @{ $common }, '--autosome', '--min-alleles', 2, '--max-alleles', 2, '--make-pgen', '--out', $g); 1 }) {
		# die, not croak, which would give _plink2's message a second "at ... line"
		die $@ unless $@ =~ /\((?:exit 13\): Error: No variants remaining|exit 7\): Error: All \d+ variant\(s\) in --[bv]cf file excluded)/;
		croak "$sub: \"vcf\" has no biallelic variant on the autosomes (1 to 22), which are all that $sub reads";
	}
	my %variants = (count => 0, file => File::Spec->catfile($dir, 'variants.tsv'), offsets => '');
	my $at = 0; # bytes written to variants.tsv
	my ($list, %col);
	if ($keep) {
		open $list, '>:raw', $variants{file} or croak "$sub: can't write $variants{file}: $!";
	}
	open my $in, '<', "$g.pvar" or croak "$sub: can't read $g.pvar: $!";
	open my $out, '>', "$g.ids.pvar" or croak "$sub: can't write $g.ids.pvar: $!";
	while (my $line = <$in>) {
		if ($line =~ /\A##/) {
			print {$out} $line;
			next;
		}
		chomp $line;
		my @f = split /\t/, $line, -1;
		if ($line =~ /\A#CHROM/) {
			%col = map { $f[$_] => $_ } 0 .. $#f;
			print {$out} "$line\n";
			next;
		}
		if ($keep) {
			my $v = join("\t", @f[ @col{'#CHROM', 'POS', 'ID', 'REF', 'ALT'} ]) . "\n";
			print {$list} $v or croak "$sub: can't write $variants{file}: $!";
			$variants{offsets} .= pack 'd', $at;
			$at += length $v;
		}
		$f[ $col{ID} ] = 'v' . ++$variants{count};
		print {$out} join("\t", @f), "\n";
	}
	close $in;
	close $out or croak "$sub: can't write $g.ids.pvar: $!";
	if ($keep) {
		close $list or croak "$sub: can't write $variants{file}: $!";
	} else {
		delete @variants{qw(file offsets)};
	}
	my @samples = _psam_iids($sub, "$g.psam", $what);
	(['--pgen', "$g.pgen", '--pvar', "$g.ids.pvar", '--psam', "$g.psam", @{ $common }], \%variants, \@samples);
}

# The variant that PLINK 2's output names $id ("v<n>", as _popgen_genotypes
# named it) as a hash ref of chrom, pos, id, ref and alt, read from the file
# of $variants (which _popgen_genotypes kept). Its handle is kept open in
# $variants, with "next" the variant it will read next, so that variants
# asked for in order, as every output but --r2's lists them, are read on
# without a seek.
sub _popgen_variant {
	my ($variants, $id) = @_;
	croak "_popgen_variant: PLINK 2 named a variant \"$id\", which it was not given"
		unless defined $id && $id =~ /\Av([1-9][0-9]*)\z/ && $1 <= $variants->{count};
	my $n = $1 - 1;
	my $file = $variants->{file};
	unless ($variants->{fh}) {
		open $variants->{fh}, '<:raw', $file or croak "_popgen_variant: can't read $file: $!";
		$variants->{next} = 0;
	}
	my $fh = $variants->{fh};
	if ($variants->{next} != $n) {
		my $offset = unpack 'd', substr $variants->{offsets}, 8 * $n, 8;
		seek $fh, $offset, 0 or croak "_popgen_variant: can't seek to byte $offset of $file: $!";
	}
	my $line = <$fh>;
	croak "_popgen_variant: $file ends before variant " . ($n + 1) unless defined $line && chomp $line;
	$variants->{next} = $n + 1;
	my %v;
	@v{qw(chrom pos id ref alt)} = split /\t/, $line, -1;
	$v{pos} += 0;
	\%v;
}

# Each line of PLINK 2's tab-separated output $file, for $sub, given to $code
# as a hash ref keyed by its header's columns (the header's "#" dropped), with
# PLINK 2's "NA" and "nan" made undef.
my $Plink2_na = qr/\A(?:NA|-?nan)\z/i;
sub _plink2_rows {
	my ($sub, $file, $code) = @_;
	open my $fh, '<', $file or croak "$sub: can't read $file: $!";
	my $head = <$fh>;
	croak "$sub: PLINK 2 wrote $file with no header" unless defined $head;
	chomp $head;
	$head =~ s/\A#//;
	my @cols = split /\t/, $head;
	while (my $line = <$fh>) {
		chomp $line;
		my %row;
		@row{@cols} = map { $_ =~ $Plink2_na ? undef : $_ } split /\t/, $line, -1;
		$code->(\%row);
	}
	close $fh;
}

# $x as a number, or undef for undef, so that a JSON encoder writes it as one.
sub _number { defined $_[0] ? 0 + $_[0] : undef }

# The temporary directory $dir removed, as a function of this section returns,
# once the handle _popgen_variant keeps in $variants is closed: Windows will
# not remove a file that is open.
sub _popgen_cleanup {
	my ($dir, $variants) = @_;
	if (my $fh = delete $variants->{fh}) {
		close $fh or croak "_popgen_cleanup: can't read $variants->{file}: $!";
	}
	require File::Path;
	File::Path::rmtree($dir);
}

# Dies unless $sub's option $key, $v, is 0 or 1.
sub _flag {
	my ($sub, $key, $v) = @_;
	croak "$sub: \"$key\" must be 0 or 1, not " . _what($v) unless !ref $v && ($v eq '0' || $v eq '1');
}

# The setup every function of this section shares: "vcf" of $sub checked, PLINK
# 2 found, a temporary directory made, and the genotypes read into it by
# _popgen_genotypes, which keeps each variant's columns when $keep is 1 and
# only their count when it is 0. Returns that directory, the plink2 program,
# and what _popgen_genotypes returns.
sub _popgen_setup {
	my ($sub, $args, $what, $keep) = @_;
	my @common = _plink2_resources($sub, $args);
	my @input = _plink2_input($sub, $args->{vcf});
	my $plink2 = _plink2_program($sub);
	# removed as $sub returns, or, after an error, as the program ends, as
	# pgs_score's is
	require File::Temp;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	($dir, $plink2, _popgen_genotypes($sub, $args->{vcf}, \@input, \@common, $plink2, $dir, $what, $keep));
}

sub pca {
	my $sub = 'pca';
	my $args = _args(\@_, $sub, ['vcf'], [qw(memory n threads)]);
	my %r;
	$r{n} = $args->{n} // 10; # how many principal components; 10 is PLINK 2's own default
	croak "$sub: \"n\" must be a whole number, 1 or more, not " . _what($r{n}) unless !ref $r{n} && $r{n} =~ /\A[1-9][0-9]*\z/;
	my ($dir, $plink2, $files, $variants, $samples) = _popgen_setup($sub, $args, 'principal components', 0);
	my $out = File::Spec->catfile($dir, 'pca');
	_plink2($sub, $plink2, $dir, @{ $files }, '--pca', $r{n}, '--out', $out);
	open my $fh, '<', "$out.eigenval" or croak "$sub: can't read $out.eigenval: $!";
	chomp(my @eigenvalues = <$fh>);
	close $fh;
	@eigenvalues = map { 0 + $_ } @eigenvalues;
	my %pcs;
	_plink2_rows($sub, "$out.eigenvec", sub {
		my ($row) = @_;
		$pcs{ $row->{IID} } = [ map { _number($row->{"PC$_"}) } 1 .. @eigenvalues ];
	});
	_popgen_cleanup($dir, $variants);
	{ eigenvalues => \@eigenvalues, samples => \%pcs, variants => 0 + $variants->{count} };
}

sub fst {
	my $sub = 'fst';
	my $args = _args(\@_, $sub, [qw(vcf populations)], [qw(memory method per_variant threads)]);
	my %r;
	$r{method} = $args->{method} // 'hudson'; # 'hudson' = Bhatia et al. (2013), PLINK 2's default; 'wc' = Weir and Cockerham (1984)
	croak "$sub: \"method\" must be \"hudson\" or \"wc\", not " . _what($r{method})
		unless !ref $r{method} && ($r{method} eq 'hudson' || $r{method} eq 'wc');
	$r{per_variant} = $args->{per_variant} // 0; # 1 = each variant's Fst too, for each pair of populations; 0 = each pair's alone
	_flag($sub, 'per_variant', $r{per_variant});
	my $pops = $args->{populations};
	croak "$sub: \"populations\" must be a hash ref of sample => population, not " . _what($pops) unless ref $pops eq 'HASH';
	foreach my $s (sort keys %{ $pops }) {
		my $p = $pops->{$s};
		croak "$sub: \"populations\" gives \"$s\" the population " . _what($p) . ', where a population is a name'
			unless defined $p && !ref $p && length $p;
	}
	my %named = map { $_ => 1 } values %{ $pops };
	croak "$sub: \"populations\" names " . (%named ? 'one population' : 'no population') . ', and Fst is between two or more' if keys %named < 2;
	my ($dir, $plink2, $files, $variants, $samples) = _popgen_setup($sub, $args, 'populations', $r{per_variant});
	# Each population is named in PLINK 2's file by a code, P1, P2, ..., in the
	# order of the names, since PLINK 2 would take a name that is a number as a
	# quantitative value, and one with a space as two fields.
	my @names = sort keys %named;
	my %code = map { $names[$_] => 'P' . ($_ + 1) } 0 .. $#names;
	my %name = reverse %code;
	my %size; # population => its samples in the VCF
	my $pheno = File::Spec->catfile($dir, 'populations.tsv');
	open my $fh, '>', $pheno or croak "$sub: can't write $pheno: $!";
	print {$fh} "#IID\tPOP\n";
	foreach my $s (@{ $samples }) {
		my $p = $pops->{$s};
		$size{$p}++ if defined $p;
		# NONE is PLINK 2's missing category (--missing-catname); it refuses NA there
		print {$fh} "$s\t", defined $p ? $code{$p} : 'NONE', "\n";
	}
	close $fh or croak "$sub: can't write $pheno: $!";
	croak "$sub: " . (%size ? 'only "' . join('', keys %size) . '", one' : 'none') . ' of the ' . @names
		. ' populations of "populations" has a sample in "vcf", and Fst is between two or more' if keys %size < 2;
	my $out = File::Spec->catfile($dir, 'fst');
	_plink2($sub, $plink2, $dir, @{ $files }, '--pheno', $pheno, '--fst', 'POP', "method=$r{method}",
		$r{per_variant} ? 'report-variants' : (), '--out', $out);
	my $column = $r{method} eq 'hudson' ? 'HUDSON_FST' : 'WC_FST';
	my (%fst, %per);
	_plink2_rows($sub, "$out.fst.summary", sub {
		my ($row) = @_;
		my ($x, $y) = @{ $row }{qw(POP1 POP2)};
		my ($p, $q) = @name{$x, $y};
		$fst{$p}{$q} = $fst{$q}{$p} = _number($row->{$column});
		return unless $r{per_variant};
		my @each;
		_plink2_rows($sub, "$out.$x.$y.fst.var", sub {
			my ($v) = @_;
			my $variant = _popgen_variant($variants, $v->{ID});
			$variant->{fst} = _number($v->{$column});
			push @each, $variant;
		});
		$per{$p}{$q} = $per{$q}{$p} = \@each;
	});
	_popgen_cleanup($dir, $variants);
	{ method => $r{method}, populations => \%size, fst => \%fst, variants => $r{per_variant} ? \%per : undef };
}

sub hardy_weinberg {
	my $sub = 'hardy_weinberg';
	my $args = _args(\@_, $sub, ['vcf'], [qw(memory midp threads)]);
	my %r;
	$r{midp} = $args->{midp} // 0; # 1 = the mid-p (Graffelman and Moreno 2013); 0 = the exact test's own p (Wigginton et al. 2005), PLINK 2's default
	_flag($sub, 'midp', $r{midp});
	my ($dir, $plink2, $files, $variants) = _popgen_setup($sub, $args, 'genotype counts', 1);
	my $out = File::Spec->catfile($dir, 'hardy');
	_plink2($sub, $plink2, $dir, @{ $files }, '--hardy', $r{midp} ? 'midp' : (), '--out', $out);
	my @out;
	_plink2_rows($sub, "$out.hardy", sub {
		my ($row) = @_;
		my $v = _popgen_variant($variants, $row->{ID});
		# PLINK 2 counts by A1, which may be either allele
		my $a1_ref = uc $row->{A1} eq uc $v->{ref} ? 1 : 0;
		@{ $v }{qw(hom_ref het hom_alt)} = map { 0 + $_ } @{ $row }{ $a1_ref ? qw(HOM_A1_CT HET_A1_CT TWO_AX_CT) : qw(TWO_AX_CT HET_A1_CT HOM_A1_CT) };
		$v->{observed_het} = _number($row->{'O(HET_A1)'});
		$v->{expected_het} = _number($row->{'E(HET_A1)'});
		$v->{p} = _number($row->{ $r{midp} ? 'MIDP' : 'P' });
		push @out, $v;
	});
	_popgen_cleanup($dir, $variants);
	\@out;
}

sub ld {
	my $sub = 'ld';
	my $args = _args(\@_, $sub, ['vcf'], [qw(memory min_r2 phased threads window window_kb)]);
	my %r;
	$r{window_kb} = $args->{window_kb} // 1000; # the farthest apart, in kb, the two variants of a pair are; 1000 is PLINK 2's default
	croak "$sub: \"window_kb\" must be a number above 0, not " . _what($r{window_kb})
		unless !ref $r{window_kb} && $r{window_kb} =~ $Number && $r{window_kb} > 0;
	$r{window} = $args->{window}; # undef = no limit, PLINK 2's default; n = the two variants of a pair are at most n variants apart (1 = adjacent)
	croak "$sub: \"window\" must be a whole number, 1 or more, not " . _what($r{window})
		if defined $r{window} && (ref $r{window} || $r{window} !~ /\A[1-9][0-9]*\z/);
	$r{min_r2} = $args->{min_r2} // 0.2; # the least r² of a pair reported; 0.2 is PLINK 2's default, and 0 reports every pair
	croak "$sub: \"min_r2\" must be a number from 0 to 1, not " . _what($r{min_r2})
		unless !ref $r{min_r2} && $r{min_r2} =~ $Number && $r{min_r2} >= 0 && $r{min_r2} <= 1;
	$r{phased} = $args->{phased} // 0; # 0 = r² of the genotypes' allele counts (--r2-unphased); 1 = r² of the haplotypes, and D' (--r2-phased)
	_flag($sub, 'phased', $r{phased});
	my ($dir, $plink2, $files, $variants) = _popgen_setup($sub, $args, 'pairs', 1);
	my $out = File::Spec->catfile($dir, 'ld');
	# PLINK 2's --ld-window counts the second variant: 2 is adjacent pairs alone
	_plink2($sub, $plink2, $dir, @{ $files }, $r{phased} ? ('--r2-phased', 'cols=+dprime') : '--r2-unphased',
		'--ld-window-kb', $r{window_kb}, '--ld-window-r2', $r{min_r2}, (defined $r{window} ? ('--ld-window', $r{window} + 1) : ()), '--out', $out);
	my $column = $r{phased} ? 'PHASED_R2' : 'UNPHASED_R2';
	my @pairs;
	_plink2_rows($sub, "$out.vcor", sub {
		my ($row) = @_;
		push @pairs, { a => _popgen_variant($variants, $row->{ID_A}), b => _popgen_variant($variants, $row->{ID_B}),
			r2 => _number($row->{$column}), dprime => $r{phased} ? _number($row->{DPRIME}) : undef };
	});
	_popgen_cleanup($dir, $variants);
	\@pairs;
}

sub ld_prune {
	my $sub = 'ld_prune';
	my $args = _args(\@_, $sub, ['vcf'], [qw(memory r2 step threads window window_kb)]);
	my %r;
	croak "$sub: the window is given either in variants, as \"window\", or in kb, as \"window_kb\", not both"
		if defined $args->{window} && defined $args->{window_kb};
	$r{window_kb} = $args->{window_kb}; # undef = the window is counted in variants, by "window"; n = n kb
	croak "$sub: \"window_kb\" must be a whole number, 1 or more, not " . _what($r{window_kb})
		if defined $r{window_kb} && (ref $r{window_kb} || $r{window_kb} !~ /\A[1-9][0-9]*\z/);
	# 50, 5 and 0.5 are the example the PLINK 1.9 manual gives for --indep-pairwise
	$r{window} = defined $r{window_kb} ? undef : $args->{window} // 50; # the variants in each window; undef with "window_kb"
	croak "$sub: \"window\" must be a whole number, 2 or more, not " . _what($r{window})
		if defined $r{window} && (ref $r{window} || $r{window} !~ /\A[1-9][0-9]*\z/ || $r{window} < 2);
	$r{step} = $args->{step} // (defined $r{window_kb} ? 1 : 5); # the variants the window moves on by; PLINK 2 takes only 1 with a window in kb
	croak "$sub: \"step\" must be a whole number, 1 or more, not " . _what($r{step}) unless !ref $r{step} && $r{step} =~ /\A[1-9][0-9]*\z/;
	croak "$sub: \"step\" must be 1 with \"window_kb\", as PLINK 2 has it, not $r{step}" if defined $r{window_kb} && $r{step} != 1;
	$r{r2} = $args->{r2} // 0.5; # of two variants whose r² is above this, one is pruned
	croak "$sub: \"r2\" must be a number above 0 and below 1, not " . _what($r{r2})
		unless !ref $r{r2} && $r{r2} =~ $Number && $r{r2} > 0 && $r{r2} < 1;
	my ($dir, $plink2, $files, $variants) = _popgen_setup($sub, $args, 'variants', 1);
	my $out = File::Spec->catfile($dir, 'prune');
	_plink2($sub, $plink2, $dir, @{ $files }, '--indep-pairwise', defined $r{window_kb} ? "$r{window_kb}kb" : $r{window}, $r{step}, $r{r2}, '--out', $out);
	my %list;
	foreach my $k (qw(in out)) {
		open my $fh, '<', "$out.prune.$k" or croak "$sub: can't read $out.prune.$k: $!";
		chomp(my @ids = <$fh>);
		close $fh;
		# in the VCF's order, which PLINK 2's lists already are, and need not be
		$list{$k} = [ map { _popgen_variant($variants, "v$_") } sort { $a <=> $b } map { /\Av([0-9]+)\z/ ? $1 : -1 } @ids ];
	}
	_popgen_cleanup($dir, $variants);
	{ keep => $list{in}, remove => $list{out} };
}

# The rows of "phenotypes" of $sub as an array of hash refs: a data frame, or a
# tab-separated file whose first line is its header, which may begin with "#",
# as PLINK 2's own phenotype files' does; the "#" is dropped.
sub _phenotype_rows {
	my ($sub, $phenotypes) = @_;
	return _frame_rows($sub, 'phenotypes', $phenotypes) if ref $phenotypes;
	croak "$sub: \"phenotypes\" file \"$phenotypes\" doesn't exist or isn't readable" unless -f $phenotypes && -r _;
	open my $fh, '<', $phenotypes or croak "$sub: can't read $phenotypes: $!";
	my (@cols, @rows);
	while (my $line = <$fh>) {
		$line =~ s/\r?\n\z//;
		next if $line eq '';
		unless (@cols) {
			$line =~ s/\A#//;
			@cols = split /\t/, $line, -1;
			next;
		}
		my @f = split /\t/, $line, -1;
		croak "$sub: line $. of \"phenotypes\" file $phenotypes has " . @f . ' fields, and its header ' . @cols unless @f == @cols;
		my %row;
		@row{@cols} = @f;
		push @rows, \%row;
	}
	close $fh;
	croak "$sub: \"phenotypes\" file $phenotypes has no rows" unless @rows;
	\@rows;
}

# A value of a phenotype or covariate that is missing: undef, empty, or NA.
sub _missing_value { !defined $_[0] || $_[0] eq '' || $_[0] eq 'NA' ? 1 : 0 }

sub gwas {
	my $sub = 'gwas';
	my $args = _args(\@_, $sub, [qw(vcf phenotypes phenotype)], [qw(covariates memory model threads)]);
	my %r;
	$r{phenotype} = $args->{phenotype};
	croak "$sub: \"phenotype\" must be the name of a column of \"phenotypes\", not " . _what($r{phenotype})
		if ref $r{phenotype} || $r{phenotype} eq '';
	$r{covariates} = $args->{covariates} // []; # the columns of "phenotypes" the test adjusts for; [] = none
	croak "$sub: \"covariates\" must be an array ref of names of columns of \"phenotypes\", not " . _what($r{covariates})
		unless ref $r{covariates} eq 'ARRAY';
	my %seen = ($r{phenotype} => 'phenotype');
	foreach my $c (@{ $r{covariates} }) {
		croak "$sub: \"covariates\" must name columns of \"phenotypes\", and one is " . _what($c) if !defined $c || ref $c || $c eq '';
		croak "$sub: \"covariates\" names \"$c\", which is already " . ($seen{$c} eq 'phenotype' ? 'the phenotype' : 'a covariate') if $seen{$c};
		$seen{$c} = 'covariate';
	}
	$r{model} = $args->{model}; # undef = decided by the phenotype's values; 'linear' = linear regression; 'logistic' = logistic (Firth's where it fails to converge)
	croak "$sub: \"model\" must be \"linear\" or \"logistic\", not " . _what($r{model})
		if defined $r{model} && (ref $r{model} || ($r{model} ne 'linear' && $r{model} ne 'logistic'));
	_plink2_resources($sub, $args);
	_plink2_input($sub, $args->{vcf});
	my $rows = _phenotype_rows($sub, $args->{phenotypes});
	my ($id_col) = grep { exists $rows->[0]{$_} } 'IID', '#IID';
	croak "$sub: \"phenotypes\" has no \"IID\" column, which names each row's sample" unless defined $id_col;
	my @cols = ($r{phenotype}, @{ $r{covariates} });
	my @absent = grep { !exists $rows->[0]{$_} } @cols;
	croak "$sub: \"phenotypes\" has no " . join(', ', map { "\"$_\"" } @absent) . ' column' . (@absent > 1 ? 's' : '') if @absent;
	my %value; # column => sample => its value, missing ones left out
	foreach my $row (@{ $rows }) {
		my $id = $row->{$id_col};
		croak "$sub: \"phenotypes\" has a row whose IID is " . _what($id) if ref $id || _missing_value($id);
		croak "$sub: \"phenotypes\" has two rows for \"$id\"" if exists $value{''}{$id};
		$value{''}{$id} = 1; # '' is no column's name: it holds the samples seen
		foreach my $c (@cols) {
			my $v = $row->{$c};
			croak "$sub: column \"$c\" of \"phenotypes\" has " . _what($v) . " for \"$id\"" if ref $v;
			$value{$c}{$id} = $v unless _missing_value($v);
		}
	}
	my %numeric; # column => 1 when every value of it is a number, else 0, when it is a categorical covariate
	foreach my $c (@cols) {
		my ($word) = grep { $value{$c}{$_} !~ $Number } sort keys %{ $value{$c} };
		$numeric{$c} = defined $word ? 0 : 1;
		croak "$sub: phenotype \"$c\" has \"$value{$c}{$word}\" for \"$word\", which isn't a number" if !$numeric{$c} && $c eq $r{phenotype};
		croak "$sub: column \"$c\" of \"phenotypes\" has \"$value{$c}{$word}\" for \"$word\", and a covariate's values have no whitespace"
			if !$numeric{$c} && $value{$c}{$word} =~ /\s/;
	}
	my %level = map { (0 + $_) => 1 } values %{ $value{ $r{phenotype} } };
	my @levels = sort { $a <=> $b } keys %level;
	croak "$sub: phenotype \"$r{phenotype}\" has " . (@levels ? "only the value $levels[0]" : 'no values') . ', and a test needs two or more' if @levels < 2;
	my $case_control = @levels == 2 && ($levels[0] == 1 && $levels[1] == 2 || $levels[0] == 0 && $levels[1] == 1) ? 1 : 0;
	$r{model} //= $case_control ? 'logistic' : 'linear';
	croak "$sub: \"model\" is logistic, and phenotype \"$r{phenotype}\" has the values " . join(', ', @levels[0 .. ($#levels < 3 ? $#levels : 3)])
		. (@levels > 4 ? ', ...' : '') . ', where a case-control phenotype has two: 1 and 2, or 0 and 1' if $r{model} eq 'logistic' && !$case_control;
	my ($dir, $plink2, $files, $variants, $samples) = _popgen_setup($sub, $args, 'phenotypes', 1);
	my $with = grep { exists $value{ $r{phenotype} }{$_} } @{ $samples };
	croak "$sub: none of the " . @{ $samples } . " samples of \"vcf\" has a value of \"$r{phenotype}\" in \"phenotypes\"; check that its IIDs are the VCF's sample names"
		unless $with;
	# PLINK 2 takes a column whose values are all 0, 1 and 2 for case-control,
	# 0 being missing, whatever is meant, so such a quantitative phenotype or
	# covariate is moved up by 3, which changes no test of a variant: a linear
	# regression's slopes, and their standard errors, do not depend on where its
	# phenotype's or covariates' zeroes are.
	my %shift = map {
		my $c = $_;
		($c => $numeric{$c} && !($c eq $r{phenotype} && $r{model} eq 'logistic') && !(grep { $_ != 0 && $_ != 1 && $_ != 2 } values %{ $value{$c} }) ? 3 : 0);
	} @cols;
	# A categorical covariate's values are written as codes, C1, C2, ..., in the
	# order of the values, since PLINK 2 refuses one that begins with a number.
	my %category = map {
		my $c = $_;
		my @v = sort keys %{ { map { $_ => 1 } values %{ $value{$c} } } };
		($c => { map { $v[$_] => 'C' . ($_ + 1) } 0 .. $#v });
	} grep { !$numeric{$_} } @{ $r{covariates} };
	my $pheno = File::Spec->catfile($dir, 'phenotypes.tsv');
	open my $fh, '>', $pheno or croak "$sub: can't write $pheno: $!";
	# The columns are named Y and X1, X2, ..., since a column's own name could
	# hold a space, or be one PLINK 2 reserves.
	my @names = ('Y', map { "X$_" } 1 .. @{ $r{covariates} });
	print {$fh} join("\t", '#IID', @names), "\n";
	foreach my $s (@{ $samples }) {
		print {$fh} join("\t", $s, map {
			my $c = $_;
			my $v = $value{$c}{$s};
			# NONE is PLINK 2's missing category, which it refuses NA for
			!defined $v ? ($numeric{$c} ? 'NA' : 'NONE')
				: $category{$c} ? $category{$c}{$v}
				: $c eq $r{phenotype} && $r{model} eq 'logistic' ? ($v == $levels[0] ? 1 : 2)
				: $shift{$c} ? $v + $shift{$c}
				: $v;
		} @cols), "\n";
	}
	close $fh or croak "$sub: can't write $pheno: $!";
	my @covar = map { $names[$_] } 1 .. $#names;
	my $out = File::Spec->catfile($dir, 'gwas');
	# omit-ref makes A1, the allele whose copies are counted, the ALT, where
	# PLINK 2 would otherwise count the minor allele's.
	_plink2($sub, $plink2, $dir, @{ $files }, '--pheno', $pheno, '--pheno-name', 'Y', '--no-input-missing-phenotype',
		(@covar ? ('--covar', $pheno, '--covar-name', join(',', @covar)) : ()),
		# so that a covariate of large values, such as a year, does not make the
		# regression's matrix too ill-conditioned for PLINK 2 to solve
		((grep { $numeric{$_} } @{ $r{covariates} }) ? '--covar-variance-standardize' : ()),
		'--glm', 'omit-ref', 'hide-covar', (@covar ? () : 'allow-no-covars'), 'cols=a1freq,firth,test,nobs,beta,se,tz,p,err', '--out', $out);
	my ($result) = grep { -f } map { "$out.Y.glm.$_" } $r{model} eq 'linear' ? 'linear' : qw(logistic.hybrid logistic logistic.firth);
	croak "$sub: PLINK 2 wrote no results of its regression to $out.Y.glm.*" unless defined $result;
	my @out;
	_plink2_rows($sub, $result, sub {
		my ($row) = @_;
		my $v = _popgen_variant($variants, $row->{ID});
		croak "$sub: PLINK 2 counted the copies of $row->{A1} at $v->{chrom}:$v->{pos}, which isn't its ALT, $v->{alt}" unless uc $row->{A1} eq uc $v->{alt};
		$v->{alt_freq} = _number($row->{A1_FREQ});
		$v->{n} = _number($row->{OBS_CT});
		@{ $v }{qw(beta se stat p)} = map { _number($_) } @{ $row }{ 'BETA', 'SE', $r{model} eq 'linear' ? 'T_STAT' : 'Z_STAT', 'P' };
		$v->{firth} = ($row->{'FIRTH?'} // 'N') eq 'Y' ? 1 : 0;
		$v->{error} = defined $row->{ERRCODE} && $row->{ERRCODE} ne '.' ? $row->{ERRCODE} : undef;
		push @out, $v;
	});
	_popgen_cleanup($dir, $variants);
	{ model => $r{model}, samples => $with, variants => \@out };
}

# ---- admixture proportions, in Bioinf.xs (since 2026-11-17)

sub admixture {
	my $sub = 'admixture';
	my $args = _args(\@_, $sub, [qw(vcf k)], [qw(max_iterations min_depth seed starts tolerance)]);
	my %r;
	$r{k} = $args->{k}; # the ancestral populations
	croak "$sub: \"k\" must be a whole number, 2 or more, not " . _what($r{k}) unless !ref $r{k} && $r{k} =~ /\A[1-9][0-9]*\z/ && $r{k} >= 2;
	# On t/data/popgen.vcf at K 3, ADMIXTURE 1.3.0 found the lesser of two
	# maxima from 2 of the 6 seeds tried (t/admixture.t), so a single start
	# finds the greater with a chance of about 2 in 3; ten fail together about
	# once in 60,000 such fits, if the starts' chances are alike.
	$r{starts} = $args->{starts} // 10; # the random starts fitted, of which the one of the highest likelihood is kept
	croak "$sub: \"starts\" must be a whole number, 1 or more, not " . _what($r{starts}) unless !ref $r{starts} && $r{starts} =~ /\A[1-9][0-9]*\z/;
	$r{seed} = $args->{seed} // 1; # start s (counting from 0) is drawn from seed + s
	croak "$sub: \"seed\" must be a whole number, 0 or more, not " . _what($r{seed})
		unless !ref $r{seed} && $r{seed} =~ /\A[0-9]+\z/ && $r{seed} <= ~0 - $r{starts};
	# The fit stops when an iteration raises the log-likelihood by less than
	# this, as ADMIXTURE 1.3.0's -C does, whose default is 1e-4. That is too
	# loose for these EM steps, which creep where the likelihood is flat. On
	# t/data/popgen.vcf at K 3 (2026-11-17), against ADMIXTURE's fit at
	# -C=1e-12: 1e-4 stopped the best of ten starts 1.1e-3 below its maximum,
	# with q 8e-4 from its. The 10 starts of seeds 1 and 3 to 12 that reached
	# the greater maximum came, at worst, within 1.4e-4 of its q at 1e-8, 1.9e-5
	# at 1e-10 and 1.75e-5 at 1e-12, the last being ADMIXTURE's own
	# convergence, for 2,550, 3,030 and 3,172 iterations in all.
	$r{tolerance} = $args->{tolerance} // 1e-10;
	croak "$sub: \"tolerance\" must be a number above 0, not " . _what($r{tolerance})
		unless !ref $r{tolerance} && $r{tolerance} =~ $Number && $r{tolerance} > 0;
	$r{max_iterations} = $args->{max_iterations} // 10_000; # SQUAREM cycles, of three EM steps each, after which a start that has not converged stops
	croak "$sub: \"max_iterations\" must be a whole number, 1 or more, not " . _what($r{max_iterations})
		unless !ref $r{max_iterations} && $r{max_iterations} =~ /\A[1-9][0-9]*\z/;
	$r{min_depth} = $args->{min_depth} // 0; # 0 = every genotype counts, whatever its DP; n = a genotype of DP below n is missing
	croak "$sub: \"min_depth\" must be a whole number, 0 or more, not " . _what($r{min_depth})
		unless !ref $r{min_depth} && $r{min_depth} =~ /\A[0-9]+\z/;
	my $vcf = $args->{vcf};
	my ($next, $close) = _vcf_open($sub, 'vcf', $vcf);
	my ($g, $variants, $names, $called) = _located(sub { _admixture_genotypes($next, $vcf, $r{min_depth}) });
	$close->();
	my $n = @{ $names };
	croak "$sub: \"vcf\" $vcf has no biallelic variant on the autosomes (1 to 22), which are all that $sub reads" unless @{ $variants };
	croak "$sub: \"vcf\" $vcf has $n sample" . ($n == 1 ? '' : 's') . ", and \"k\" is $r{k}; a sample's ancestry is a share of the k populations, which needs more samples than k"
		unless $n > $r{k};
	my ($best, @ll); # the best start's [q, p, log-likelihood, iterations, converged]; each start's log-likelihood
	foreach my $s (0 .. $r{starts} - 1) {
		my @fit = _located(sub { _admixture_fit($g, $n, $r{k}, $r{seed} + $s, $r{max_iterations}, $r{tolerance}) });
		push @ll, $fit[2];
		# the first of equal ones, so that the order of the starts decides a tie
		$best = \@fit if !$best || $fit[2] > $best->[2];
	}
	my ($q, $p, $ll, $iterations, $converged) = @{ $best };
	carp "$sub: the best of the $r{starts} start" . ($r{starts} == 1 ? '' : 's') . " stopped after $iterations iterations without converging"
		. ' (its log-likelihood still rising by ' . _two_digit_exponent("$r{tolerance}") . ' or more); give a larger "max_iterations"' unless $converged;
	my @none = grep { !$called->[$_] } 0 .. $n - 1;
	carp "$sub: " . scalar(@none) . ' sample' . (@none == 1 ? ' has' : 's have') . ' no called genotype, and so an even share of each population: '
		. join(', ', map { "\"$names->[$_]\"" } @none[0 .. ($#none < 4 ? $#none : 4)]) . (@none > 5 ? ', ...' : '') if @none;
	# The populations' order is the fit's own, which differs from start to
	# start, so they are put in an order that does not: by their share of the
	# samples, the largest first.
	my @share = (0) x $r{k};
	foreach my $row (@{ $q }) {
		$share[$_] += $row->[$_] foreach 0 .. $r{k} - 1;
	}
	my @order = sort { $share[$b] <=> $share[$a] || $a <=> $b } 0 .. $r{k} - 1;
	my %samples = map { $names->[$_] => [ @{ $q->[$_] }[@order] ] } 0 .. $n - 1;
	my @variants = map {
		my %v;
		@v{qw(chrom pos id ref alt)} = split /\t/, $variants->[$_];
		$v{pos} += 0;
		$v{freq} = [ @{ $p->[$_] }[@order] ];
		\%v;
	} 0 .. $#{ $variants };
	{ k => 0 + $r{k}, loglik => $ll, iterations => $iterations, converged => $converged, starts => \@ll,
		samples => \%samples, variants => \@variants };
}

# ---- VCF genotypes: sex and parentage

# The bytes sex_check and parent read at a time, from a file or through
# IO::Uncompress, for Bioinf.xs to count. On 2026-10-18 sex_check read
# a whole genome, genome.vcf.gz (155 MB, 3.5 million records), in 4.84 s with
# blocks of 16 KiB, 64 KiB or 256 KiB, and 4.90 s and 4.86 s with 1 MiB and 4
# MiB (best of three, peak RSS 47 MB each), so 64 KiB, as for FASTA. The time
# is gzip's: the same file uncompressed (928 MB) took 0.26 s and 11 MB, and
# zcat alone 3.7 s; as .vcf.bz2 it took 19.4 s, and bzip2 -dc alone 18.5 s.
# IO::Uncompress::Gunzip's readline, which is perl, took 14.3 s just to read
# the lines, and the read loop alone in 1 MiB blocks 5.7 s.
my $Vcf_block = 1 << 16;

# Dies unless the VCF $file, given to $sub as its option $key, is a readable
# file with a VCF's name. Returns how it is compressed: 'gz', 'bz2', or '' for
# not at all. Its messages are prefixed with $sub, whose argument the file is.
sub _vcf_check {
	my ($sub, $key, $file) = @_;
	croak "$sub: \"$key\" must be a file name, not " . _what($file) if ref $file || !defined $file;
	croak "$sub: \"$key\" file \"$file\" doesn't exist or isn't readable" unless -f $file && -r _;
	return 'gz' if $file =~ /\.vcf\.b?gz\z/i;
	return 'bz2' if $file =~ /\.vcf\.bz2\z/i;
	return '' if $file =~ /\.vcf\z/i;
	croak "$sub: \"$key\" file $file must end in .vcf, .vcf.gz, .vcf.bgz or .vcf.bz2";
}

# The VCF $file, given to $sub as its option $key, opened: returns a sub that
# gives the next block of it and then undef, and a sub that closes it. Its
# messages are prefixed with $sub, whose argument the file is.
sub _vcf_open {
	my ($sub, $key, $file) = @_;
	my $packed = _vcf_check($sub, $key, $file);
	my ($fh, $error); # $error: what says why a read failed
	# Transparent => 0, or IO::Uncompress would pass a file that isn't compressed
	# through as it is, and the error would be that it isn't a VCF. For a file too
	# short to hold a header, new() gives undef and leaves the error empty in
	# IO::Uncompress::Gunzip 2.223 (perl 5.44.0), though 2.020 (perl 5.10.1) says
	# "Header Error: Minimum header size is 10 bytes".
	if ($packed eq 'gz') {
		require IO::Uncompress::Gunzip;
		$fh = IO::Uncompress::Gunzip->new($file, MultiStream => 1, Transparent => 0)
			or croak "$sub: can't read $file: " . ($IO::Uncompress::Gunzip::GunzipError || 'it isn\'t gzip-compressed');
		$error = sub { $IO::Uncompress::Gunzip::GunzipError };
	} elsif ($packed eq 'bz2') {
		require IO::Uncompress::Bunzip2;
		$fh = IO::Uncompress::Bunzip2->new($file, MultiStream => 1, Transparent => 0)
			or croak "$sub: can't read $file: " . ($IO::Uncompress::Bunzip2::Bunzip2Error || 'it isn\'t bzip2-compressed');
		$error = sub { $IO::Uncompress::Bunzip2::Bunzip2Error };
	} else {
		open $fh, '<:raw', $file or croak "$sub: can't read $file: $!";
		$error = sub { "$!" };
	}
	my $next = sub {
		my $block;
		my $n = read $fh, $block, $Vcf_block;
		# IO::Uncompress's read gives a negative number on an error, perl's undef
		croak "$sub: can't read $file: " . $error->() if !defined $n || $n < 0;
		$n ? $block : undef;
	};
	my $close = sub { close $fh or croak "$sub: can't read $file: " . $error->() };
	($next, $close);
}

# The header of the VCF $file, given to $sub as its option $key, read as far as
# its first line that does not start with "##": a hash ref whose "contig" is an
# array ref of the ##contig lines' [ID, length, assembly], in the header's
# order, and whose "reference" is the first ##reference line's value, or
# undef. An ID loses its "chr" prefix, in any case, as Bioinf.xs's
# conc_chrom() drops it from CHROM; a length or an assembly that the line
# lacks is undef. Whatever is wrong with the file beyond its ## lines is left
# for Bioinf.xs to find, as it reads it.
sub _vcf_meta {
	my ($sub, $key, $file) = @_;
	my ($next, $close) = _vcf_open($sub, $key, $file);
	my %meta = (contig => [], reference => undef);
	my $carry = ''; # the start of a line that the last block ended inside
	my $done = 0;   # 1 = a line not starting with "##" has been read
	while (!$done && defined(my $block = $next->())) {
		$carry .= $block;
		my $end = rindex $carry, "\n";
		next if $end < 0;
		foreach my $line (split /\n/, substr($carry, 0, $end)) {
			$line =~ s/\r\z//;
			if (substr($line, 0, 2) ne '##') {
				$done = 1;
				last;
			}
			if ($line =~ /\A##contig=<(.*)>\z/) {
				my $attr = $1;
				my ($id) = $attr =~ /(?:\A|,)ID=([^,]+)/;
				next unless defined $id;
				$id =~ s/\Achr(?=.)//i;
				my ($length) = $attr =~ /(?:\A|,)length=([0-9]+)/;
				my ($assembly) = $attr =~ /(?:\A|,)assembly="?([^,"]+)/;
				push @{ $meta{contig} }, [$id, $length, $assembly];
			} elsif ($line =~ /\A##reference=(.+)\z/) {
				$meta{reference} //= $1;
			}
		}
		$carry = substr($carry, $end + 1);
	}
	$close->();
	\%meta;
}

# Dies unless the VCFs $test and $truth, given to $sub, can be on one genome
# build: every contig that both headers give a length for must have the same
# length in each. A chromosome's length differs from one build to the next, and
# so does a site's POS, so that two builds share few sites, and only by chance.
# A header with no lengths cannot be checked, and is not. Contigs are matched by
# name less "chr", as sites are, so hg19 and b37 (chr1 and 1, both 249,250,621
# bases by the headers of an hg19 exome's VCF and of 1000 Genomes' hs37d5 BCF,
# read 2026-10-20) pass.
sub _same_build {
	my ($sub, $test, $truth) = @_;
	my %meta = (test => _vcf_meta($sub, 'test', $test), truth => _vcf_meta($sub, 'truth', $truth));
	my %truth_length; # contig => its length in the truth, for those that have one
	foreach my $c (@{ $meta{truth}{contig} }) {
		$truth_length{ $c->[0] } //= $c->[1] if defined $c->[1];
	}
	my ($shared, @differ) = (0); # @differ: [contig, test length, truth length], in the test's order
	my %seen;
	foreach my $c (@{ $meta{test}{contig} }) {
		my ($id, $length) = @{ $c };
		next if !defined $length || !defined $truth_length{$id} || $seen{$id}++;
		$shared++;
		push @differ, [$id, $length, $truth_length{$id}] if $length != $truth_length{$id};
	}
	return unless @differ;
	# what each header says its build is: the assembly of a ##contig line that
	# differs, or else its ##reference
	my %says;
	foreach my $key (qw(test truth)) {
		my ($asm) = map { $_->[2] } grep { defined $_->[2] && defined $_->[1] && $_->[0] eq $differ[0][0] } @{ $meta{$key}{contig} };
		$says{$key} = $asm // $meta{$key}{reference};
	}
	my $listed = 3; # contigs named in the message; the rest are counted
	my @named = map { "$_->[0] as $_->[1] bases long in the test and $_->[2] in the truth" } @differ[0 .. ($#differ < $listed - 1 ? $#differ : $listed - 1)];
	croak "$sub: \"test\" $test and \"truth\" $truth are on different genome builds: their ##contig lines give " . join(', ', @named)
		. (@differ > $listed ? ', and ' . (@differ - $listed) . ' more' : '') . ' (' . scalar(@differ) . " of the $shared contigs that both give a length for differ)"
		. (defined $says{test} && defined $says{truth} ? "; the test's header says \"$says{test}\" and the truth's \"$says{truth}\"" : '')
		. ', so a POS in one is not the same place in the other. Lift one over to the other\'s build first';
}

# sex_check's report on $vcf: what was counted and the rule, then a table of
# the samples in $order, the VCF's, each with its sex and the counts it was told
# from. Columns are as wide as their widest entry, numbers right-aligned.
sub _sex_report {
	my ($vcf, $r, $tally, $order) = @_;
	my @head = ('sample', 'sex', 'het/hom-ALT', 'X het', 'X hom-ALT', 'X haploid', 'X missing', 'Y called');
	my @rows = map {
		my $s = $tally->{$_};
		[$_, $s->{sex} // 'unknown', defined $s->{het_ratio} ? sprintf('%.3f', $s->{het_ratio}) : '-',
			@{ $s }{qw(x_het x_hom_alt x_haploid x_missing y_called)}]
	} @{ $order };
	my @w = map { length $head[$_] } 0 .. $#head;
	foreach my $row (@rows) {
		foreach my $i (0 .. $#head) {
			$w[$i] = length $row->[$i] if length $row->[$i] > $w[$i];
		}
	}
	my $line = sub { join('  ', map { $_ < 2 ? sprintf('%-*s', $w[$_], $_[$_]) : sprintf('%*s', $w[$_], $_[$_]) } 0 .. $#head) . "\n" };
	my @unknown = grep { !defined $tally->{$_}{sex} } @{ $order };
	"sex_check: $vcf\n"
		. "male when het/hom-ALT, over SNVs on X outside its pseudo-autosomal regions, is below $r->{cutoff}; genotypes of DP below $r->{min_depth} not counted\n"
		. $line->(@head) . join('', map { $line->(@{ $_ }) } @rows)
		. (@unknown ? scalar(@unknown) . ' of ' . scalar(@rows) . " unknown: no het or hom-ALT call on X\n" : '');
}

# peddy 0.4.3's (sex_check() in peddy/peddy.py): male below a het to hom-ALT
# ratio of 0.6 on non-PAR X. sex_check's default "cutoff", and what relatedness
# tells sex by.
my $Sex_cutoff = 0.6;

# The het_ratio and sex of one sample's counts, $s, from Bioinf.xs's
# sex_count(), set in $s: male when the ratio is below $cutoff. peddy divides
# by a hom-ALT count of 0 as if it were 1, and so calls a sample with no calls
# on X male; here it is undef, as is its sex.
sub _sex_of {
	my ($s, $cutoff) = @_;
	my $calls = $s->{x_het} + $s->{x_hom_alt};
	$s->{het_ratio} = $calls ? $s->{x_het} / ($s->{x_hom_alt} || 1) : undef;
	$s->{sex} = !$calls ? undef : $s->{het_ratio} < $cutoff ? 'male' : 'female';
}

sub sex_check {
	my $sub = 'sex_check';
	# sex_check($file) and sex_check($file, %options) take the file first; an
	# odd count whose first is an option's name is left for _args to refuse
	unshift @_, 'vcf' if @_ % 2 && defined $_[0] && !ref $_[0] && $_[0] !~ /\A(?:vcf|cutoff|min_depth|report)\z/;
	croak "$sub: \"$_[0]\" is the file, so the options after it must be name => value pairs, and are an odd number"
		if @_ && defined $_[0] && !ref $_[0] && $_[0] ne 'vcf' && -f $_[0];
	my $args = _args(\@_, $sub, ['vcf'], [qw(cutoff min_depth report)]);
	my %r;
	# peddy 0.4.3's defaults (sex_check() in peddy/peddy.py): male below a het
	# to hom-ALT ratio of 0.6 on non-PAR X, and genotypes of depth 7 or more
	$r{cutoff} = $args->{cutoff} // $Sex_cutoff;
	croak "$sub: \"cutoff\" must be a number above 0, not " . _what($r{cutoff})
		unless !ref $r{cutoff} && $r{cutoff} =~ $Number && $r{cutoff} > 0;
	$r{min_depth} = $args->{min_depth} // 7; # 0 = count every genotype, whatever its DP
	croak "$sub: \"min_depth\" must be a whole number, 0 or more, not " . _what($r{min_depth})
		unless !ref $r{min_depth} && $r{min_depth} =~ /\A[0-9]+\z/;
	$r{report} = $args->{report} // 1; # 1 = print a table of the samples to STDOUT; 0 = only return them
	croak "$sub: \"report\" must be 0 or 1, not " . _what($r{report}) unless !ref $r{report} && ($r{report} eq '0' || $r{report} eq '1');
	my $vcf = $args->{vcf};
	my ($next, $close) = _vcf_open($sub, 'vcf', $vcf);
	my ($tally, $x_sites, $order) = _located(sub { _sex_tally($next, $vcf, $r{min_depth}) });
	$close->();
	_sex_of($_, $r{cutoff}) foreach values %{ $tally };
	if ($r{report}) {
		print STDOUT _sex_report($vcf, \%r, $tally, $order) or croak "$sub: can't print the report: $!";
	}
	carp "$sub: \"vcf\" $vcf has no SNV on X outside its pseudo-autosomal regions, so no sex can be told" unless $x_sites;
	$tally;
}

# KING's bounds on the kinship coefficient, from its manual
# (www.kingrelatedness.com/manual.shtml, read 2026-10-18): above 0.354 the same
# person or identical twins, and then first-, second- and third-degree
# relatives down to 0.177, 0.0884 and 0.0442, below which a pair is unrelated.
# They are 2^-1.5, 2^-2.5, 2^-3.5 and 2^-4.5, the geometric means of the
# kinships of neighbouring degrees (1/2, 1/4, 1/8, 1/16, 1/32), and the
# rounded values are used, as KING prints them.
my @King = ([0.354, 'the same person or identical twins'], [0.177, 'first-degree relatives'],
	[0.0884, 'second-degree relatives'], [0.0442, 'third-degree relatives']);

# The fewest sites parent will decide from. At the IBS0 rate of the unrelated
# pair measured (0.081, in the README), 1,000 sites hold 81 IBS0 sites on
# average, with a binomial standard deviation of 8.6, so that falling below
# the 12 of the default max_ibs0 is 8 standard deviations away. An exome
# gives about 150,000 and a genome 3 million, so only a small panel, or
# files that hardly overlap, comes near it.
my $Parent_sites = 1000;

# Whether two people's own VCFs were probably not sequenced over the same
# regions, which parent and relatedness warn of: of the sites compared, $sites,
# one file has $more that the other lacks and the other $fewer that it lacks,
# $more being the larger. Three things must hold.
#
# $more is over twice $fewer. Two VCFs of one pipeline have about as many each:
# on 2026-10-18 the three pairs of one family's exomes had ratios of 1.13 at
# most, where an exome of another capture kit had 3.0 to 13 against them, and a
# genome against an exome 58, which is why 2.
#
# $more exceeds $fewer by $Region_excess sites, so that it is not chance. Were a
# site in one file alone as likely to be in either, the chance of a ratio over
# 2 with a difference of 50 or more is greatest at 99 against 49, where it is
# 4.8e-5 (the exact binomial tail on both sides, computed 2026-11-10); a
# difference of 30 would allow 1.8e-3.
#
# And by $Region_share of the sites compared, so that it could matter. Each of
# those sites is taken as hom-REF in the file that lacks it, and at worst is an
# opposite homozygote that was never sequenced, which adds that share to the
# IBS0 rate. 0.009 is the smallest margin measured between a parent and
# child's rate and max_ibs0's default: 0.012 less the 0.0030 of the comment in
# parent. Fewer cannot carry such a pair over it.
#
# Up to 2026-11-10 the ratio was the whole test, so that two VCFs of 3,000
# sites that differed by 3 sites against 1 were warned of.
my $Region_excess = 50;
my $Region_share = 0.009;
sub _regions_differ {
	my ($more, $fewer, $sites) = @_;
	$more > 2 * $fewer && $more - $fewer >= $Region_excess && $more - $fewer >= $Region_share * $sites ? 1 : 0;
}

# The KING-robust between-family kinship (Manichaikul et al. 2010,
# Bioinformatics 26:2867) of two samples with $het_a and $het_b het calls at the
# sites compared, $het_het sites where both are het and $ibs0 opposite
# homozygotes, in the form PLINK 2's --make-king-table gives it (t/parent.t's
# header says how the two were found to agree); undef when either has no het
# call.
sub _king {
	my ($het_a, $het_b, $het_het, $ibs0) = @_;
	my $min_het = $het_a < $het_b ? $het_a : $het_b;
	return undef unless $min_het;
	0.5 - ($het_a + $het_b - 2 * $het_het + 4 * $ibs0) / (4 * $min_het);
}

# The relationship that a $kinship and an IBS0 rate say, by KING's ranges, with
# an IBS0 rate below $max_ibs0 telling parent and child from full siblings.
sub _relationship {
	my ($kinship, $ibs0_rate, $max_ibs0) = @_;
	my $band = (grep { $kinship > $King[$_][0] } 0 .. $#King)[0];
	!defined $band ? 'unrelated' : $band == 0 ? 'duplicate'
		: $band == 1 ? ($ibs0_rate < $max_ibs0 ? 'parent-child' : 'full siblings')
		: $band == 2 ? 'second-degree' : 'third-degree';
}

# parent's report, given its sample or file names, the resolved options, and
# its result.
sub _parent_report {
	my ($child, $parent, $vcf, $r, $s) = @_;
	my $kin = sprintf '%.4f', $s->{kinship};
	my $rate = sprintf '%.4f', $s->{ibs0_rate};
	my $band = (grep { $s->{kinship} > $King[$_][0] } 0 .. $#King)[0];
	my $kin_says = !defined $band ? "kinship $kin is below 0.0442, as for unrelated people"
		: $band == 0 ? "kinship $kin is above 0.354, as for $King[0][1]"
		: "kinship $kin is from $King[$band][0] to $King[$band - 1][0], as for $King[$band][1]";
	my $ibs0_says = "the IBS0 rate, $rate, is " . ($s->{ibs0_rate} < $r->{max_ibs0} ? 'below' : 'not below') . " $r->{max_ibs0}";
	my $verdict = $s->{parent} ? "parent and child (1): $ibs0_says, and $kin_says"
		: "not parent and child (0): $kin_says, and $ibs0_says";
	$verdict .= ', so full siblings' if $s->{relationship} eq 'full siblings';
	my @rows = (["sites compared", $s->{sites}, "autosomal biallelic SNVs where either carries the ALT, DP $r->{min_depth} or more"]);
	push @rows, (['  in both VCFs', $s->{in_both}, ''], ["  in the child's alone", $s->{child_only}, 'the parent taken as hom-REF'],
		["  in the parent's alone", $s->{parent_only}, 'the child taken as hom-REF']) unless defined $vcf;
	push @rows, (['IBS0', $s->{ibs0}, 'opposite homozygotes'],
		['  child hom-ALT', $s->{child_alt_parent_ref}, 'and the parent hom-REF'], ['  child hom-REF', $s->{child_ref_parent_alt}, 'and the parent hom-ALT'],
		['IBS1', $s->{ibs1}, 'one allele shared'], ['IBS2', $s->{ibs2}, 'both alleles shared'],
		['het in both', $s->{het_het}, ''], ['het', $s->{child_het}, "the child's, and $s->{parent_het} the parent's"],
		['hom-ALT', $s->{child_hom_alt}, "the child's, and $s->{parent_hom_alt} the parent's"],
		['kinship', $kin, 'KING-robust, between-family']);
	my ($w0, $w1) = (0, 0);
	foreach my $row (@rows) {
		$w0 = length $row->[0] if length $row->[0] > $w0;
		$w1 = length $row->[1] if length $row->[1] > $w1;
	}
	"parent: child " . (defined $vcf ? "$child, parent $parent, in $vcf" : "$child, parent $parent") . "\n"
		. "$verdict\n"
		. join('', map { my $l = sprintf '%-*s  %*s', $w0, $_->[0], $w1, $_->[1]; $l .= "  $_->[2]" if length $_->[2]; "$l\n" } @rows);
}

sub parent {
	my $sub = 'parent';
	my $args = _args(\@_, $sub, [qw(child parent)], [qw(vcf min_depth max_ibs0 report)]);
	my %r;
	# Measured on three exomes of one family on 2026-10-18 (README.md): with
	# every genotype counted the two parent-child pairs had IBS0 rates of 0.254
	# and 0.215, from off-target calls of DP 1 to 3, and with DP 10 or more
	# 0.0030 and 0.0020, against 0.081 for the unrelated pair; DP 7 gave 0.0053
	# and 0.0037, half the margin below max_ibs0, for 8% more sites.
	$r{min_depth} = $args->{min_depth} // 10; # 0 = count every genotype, whatever its DP
	croak "$sub: \"min_depth\" must be a whole number, 0 or more, not " . _what($r{min_depth})
		unless !ref $r{min_depth} && $r{min_depth} =~ /\A[0-9]+\z/;
	# peddy 0.4.3's (ped_check() in peddy/peddy.py: predicted_parents is
	# ibs0 / n < 0.012), where it sits between the measured parent-child rates
	# above and the 0.02 or so expected of full siblings, who share no allele
	# by descent at a quarter of sites and so have a quarter of the unrelated
	# pair's 0.081
	$r{max_ibs0} = $args->{max_ibs0} // 0.012;
	croak "$sub: \"max_ibs0\" must be a number above 0, not " . _what($r{max_ibs0})
		unless !ref $r{max_ibs0} && $r{max_ibs0} =~ $Number && $r{max_ibs0} > 0;
	$r{report} = $args->{report} // 1; # 1 = print the report to STDOUT; 0 = only return
	croak "$sub: \"report\" must be 0 or 1, not " . _what($r{report}) unless !ref $r{report} && ($r{report} eq '0' || $r{report} eq '1');
	my ($child, $parent, $vcf) = @{ $args }{qw(child parent vcf)}; # $vcf: undef = child and parent are each a VCF of its own
	my @t; # sites by the child's ALT count and then the parent's, 0 to 2, flattened; then the informative sites in both files, the child's alone, the parent's alone
	if (defined $vcf) {
		foreach my $key (qw(child parent)) {
			croak "$sub: \"$key\" must be a sample name of \"vcf\", not " . _what($args->{$key}) if ref $args->{$key} || !length $args->{$key};
		}
		croak "$sub: \"child\" and \"parent\" are both \"$child\"" if $child eq $parent;
		my ($next, $close) = _vcf_open($sub, 'vcf', $vcf);
		@t = _located(sub { _parent_one($next, $vcf, $r{min_depth}, $child, $parent) });
		$close->();
	} else {
		croak "$sub: \"child\" and \"parent\" are both \"$child\"" if !ref $child && !ref $parent && $child eq $parent;
		my ($child_next, $child_close) = _vcf_open($sub, 'child', $child);
		my ($parent_next, $parent_close) = _vcf_open($sub, 'parent', $parent);
		@t = _located(sub { _parent_own($child_next, $child, $parent_next, $parent, $r{min_depth}) });
		$child_close->();
		$parent_close->();
	}
	my %s;
	@s{qw(in_both child_only parent_only)} = @t[9 .. 11];
	$s{sites} = $s{in_both} + $s{child_only} + $s{parent_only};
	@s{qw(child_ref_parent_alt child_alt_parent_ref)} = @t[2, 6];
	$s{ibs0} = $t[2] + $t[6];
	$s{ibs1} = $t[1] + $t[3] + $t[5] + $t[7];
	$s{ibs2} = $t[4] + $t[8];
	$s{het_het} = $t[4];
	$s{child_het} = $t[3] + $t[4] + $t[5];
	$s{parent_het} = $t[1] + $t[4] + $t[7];
	$s{child_hom_alt} = $t[6] + $t[7] + $t[8];
	$s{parent_hom_alt} = $t[2] + $t[5] + $t[8];
	my $what = defined $vcf ? "\"$child\" and \"$parent\" of $vcf" : "$child and $parent";
	# Without a hom-REF call, IBS0 cannot be seen, and an unrelated pair would
	# look like parent and child. A VCF merged from VCFs that list only their own
	# sample's variant sites is like that, as bcftools merge writes it without
	# -0: each sample is "./." wherever it had no variant. It is checked before
	# the number of sites, which such a VCF often has too few of as well, since
	# this says what to do about it.
	croak "$sub: neither of $what has a hom-REF call where the other carries the ALT, so no opposite homozygote can be seen;"
		. ' a VCF merged from VCFs that list only their own variants is like that, so give each sample\'s own VCF as "child" and "parent"'
		if $s{sites} && !($t[1] + $t[2] + $t[3] + $t[6]);
	croak "$sub: $what have only $s{sites} autosomal biallelic SNVs of DP $r{min_depth} or more where either carries the ALT,"
		. " and $Parent_sites are needed" . (defined $vcf ? '' : '; if the files share few sites, check that they are of the same genome build')
		if $s{sites} < $Parent_sites;
	$s{kinship} = _king(@s{qw(child_het parent_het het_het ibs0)});
	croak "$sub: " . ($s{child_het} ? 'the parent' : 'the child') . " of $what has no het call at the sites compared, so no kinship can be taken" unless defined $s{kinship};
	$s{ibs0_rate} = $s{ibs0} / $s{sites};
	$s{relationship} = _relationship($s{kinship}, $s{ibs0_rate}, $r{max_ibs0});
	$s{parent} = $s{relationship} eq 'parent-child' ? 1 : 0;
	if ($r{report}) {
		print STDOUT _parent_report($child, $parent, $vcf, \%r, \%s) or croak "$sub: can't print the report: $!";
	}
	# _regions_differ's comment says what is tested, and why
	my ($more, $fewer) = $s{child_only} > $s{parent_only} ? ('child', 'parent') : ('parent', 'child');
	my ($n_more, $n_fewer) = @s{"${more}_only", "${fewer}_only"};
	carp "$sub: the ${more}'s VCF has $n_more sites that the ${fewer}'s lacks, and the ${fewer}'s only $n_fewer that the ${more}'s lacks,"
		. ' so the two were probably not sequenced over the same regions (an exome and a genome, or two capture kits);'
		. ' a site that one lacks is taken as hom-REF in it, so IBS0 and the kinship are not to be trusted'
		if !defined $vcf && _regions_differ($n_more, $n_fewer, $s{sites});
	wantarray ? ($s{parent}, \%s) : $s{parent};
}

# The words for a male and a female relative, in relatedness's categories:
# the parent, the child, the sibling.
my %Kin_word = (male => [qw(father son brother)], female => [qw(mother daughter sister)]);

# relatedness's report, given its files, the resolved options, the samples in
# order, each one's sex counts, and $each_pair, which gives each pair in order
# to a sub. Columns are as wide as their widest entry, numbers right-aligned.
# The pairs' rows are made twice, once for the widths and once for the lines,
# rather than held: 1,000 samples have 499,500.
sub _relatedness_report {
	my ($files, $r, $names, $tally, $each_pair) = @_;
	# the lines of the rows that $rows gives to a sub, under @head, with the
	# columns in %$right right-aligned
	my $table = sub {
		my ($right, $rows, @head) = @_;
		my @w = map { length } @head;
		$rows->(sub {
			foreach my $i (0 .. $#_) {
				$w[$i] = length $_[$i] if length $_[$i] > $w[$i];
			}
		});
		my $text = '';
		my $line = sub {
			(my $l = join '  ', map { $right->{$_} ? sprintf('%*s', $w[$_], $_[$_]) : sprintf('%-*s', $w[$_], $_[$_]) } 0 .. $#_) =~ s/ +\z//;
			$text .= "$l\n";
		};
		$line->(@head);
		$rows->($line);
		$text;
	};
	my $several = @{ $files } > 1;
	my $samples = sub {
		my ($row) = @_;
		foreach my $x (@{ $names }) {
			my $s = $tally->{$x};
			$row->($x, $s->{sex} // 'unknown', defined $s->{het_ratio} ? sprintf('%.3f', $s->{het_ratio}) : '-', $several ? $s->{file} : ());
		}
	};
	my $pairs = sub {
		my ($row) = @_;
		$each_pair->(sub {
			my ($x, $y, $s) = @_;
			$row->($x, $y, $s->{sites}, defined $s->{ibs0_rate} ? sprintf('%.4f', $s->{ibs0_rate}) : '-', defined $s->{kinship} ? sprintf('%.4f', $s->{kinship}) : '-',
				defined $s->{undecided} ? "undecided: $s->{undecided}" : $s->{category} . (defined $s->{parent} ? " ($s->{parent} the parent)" : ''));
		});
	};
	'relatedness: ' . join(', ', @{ $files }) . "\n"
		. "KING-robust kinship over autosomal biallelic SNVs where either carries the ALT, genotypes of DP below $r->{min_depth} not counted;"
		. " first-degree from 0.177 to 0.354, and of those, parent and child when the IBS0 rate is below $r->{max_ibs0};"
		. " male when het/hom-ALT on X outside its pseudo-autosomal regions is below $Sex_cutoff\n"
		. $table->({ 2 => 1 }, $samples, 'sample', 'sex', 'X het/hom-ALT', $several ? 'VCF' : ())
		. $table->({ 2 => 1, 3 => 1, 4 => 1 }, $pairs, 'sample', 'sample', 'sites', 'IBS0 rate', 'kinship', 'relationship');
}

sub relatedness {
	my $sub = 'relatedness';
	# relatedness($file, ...) takes the VCFs first, unnamed, up to the first word:
	# a VCF's name has a dot, as its suffix must, and an option's name, or a
	# misspelling of one, has none
	my @vcf;
	push @vcf, shift @_ while @_ && defined $_[0] && !ref $_[0] && $_[0] !~ /\A\w+\z/;
	my $args = _args(\@_, $sub, [], [qw(vcf min_depth max_ibs0 report)]);
	if (defined $args->{vcf}) {
		croak "$sub: the VCFs are given either first, unnamed, or as \"vcf\", not both" if @vcf;
		@vcf = ref $args->{vcf} eq 'ARRAY' ? @{ $args->{vcf} } : $args->{vcf};
	}
	croak "$sub: needs a VCF of several samples, or several VCFs of one, as relatedness(\$file) or relatedness(\$file, \$file2)" unless @vcf;
	my %r;
	$r{min_depth} = $args->{min_depth} // 10; # 0 = count every genotype, whatever its DP; 10 is parent's, for parent's reasons
	croak "$sub: \"min_depth\" must be a whole number, 0 or more, not " . _what($r{min_depth})
		unless !ref $r{min_depth} && $r{min_depth} =~ /\A[0-9]+\z/;
	$r{max_ibs0} = $args->{max_ibs0} // 0.012; # parent's, and peddy 0.4.3's
	croak "$sub: \"max_ibs0\" must be a number above 0, not " . _what($r{max_ibs0})
		unless !ref $r{max_ibs0} && $r{max_ibs0} =~ $Number && $r{max_ibs0} > 0;
	$r{report} = $args->{report} // 1; # 1 = print the report to STDOUT; 0 = only return
	croak "$sub: \"report\" must be 0 or 1, not " . _what($r{report}) unless !ref $r{report} && ($r{report} eq '0' || $r{report} eq '1');
	# every file checked before any is read, which can take minutes
	my %given;
	foreach my $file (@vcf) {
		_vcf_check($sub, 'vcf', $file);
		croak "$sub: \"$file\" is given twice" if $given{$file}++;
	}
	my ($names, $counts, $tally); # the samples in order; REL_T counts a pair, as Bioinf.xs describes them, packed as UVs; each sample's sex counts
	if (@vcf == 1) {
		my ($next, $close) = _vcf_open($sub, 'vcf', $vcf[0]);
		($names, $counts, $tally) = _located(sub { _relatedness_one($next, $vcf[0], $r{min_depth}) });
		$close->();
	} else {
		# each opened as Bioinf.xs comes to it, and closed at its end, so that only
		# one is open at a time
		my @next = map {
			my $file = $_;
			my ($next, $close);
			sub {
				($next, $close) = _vcf_open($sub, 'vcf', $file) unless $next;
				my $block = $next->();
				$close->() unless defined $block;
				$block;
			};
		} @vcf;
		($names, $counts, $tally) = _located(sub { _relatedness_own(\@next, \@vcf, $r{min_depth}) });
	}
	foreach my $i (0 .. $#{ $names }) {
		my $s = $tally->{ $names->[$i] };
		_sex_of($s, $Sex_cutoff);
		$s->{file} = @vcf == 1 ? $vcf[0] : $vcf[$i];
	}
	my %out = map { $_ => {} } @{ $names };
	# each pair, in the samples' order, given to $code as (first, second, its
	# hash); walked when needed rather than held as a list, which for 1,000
	# samples would be 499,500 arrays, each with a copy of both names
	my $each_pair = sub {
		my ($code) = @_;
		foreach my $i (0 .. $#{ $names } - 1) {
			my $x = $names->[$i];
			$code->($x, $_, $out{$x}{$_}) foreach @{ $names }[$i + 1 .. $#{ $names }];
		}
	};
	my $pair = 11 * length pack 'J', 0; # bytes of a pair's counts in $counts
	my $k = 0; # where the pair's counts start in $counts
	foreach my $i (0 .. $#{ $names } - 1) {
		foreach my $j ($i + 1 .. $#{ $names }) {
			my ($x, $y) = @{ $names }[$i, $j];
			# t[3 * x's ALT count + y's], as parent's, and then the sites in both VCFs,
			# in x's alone and in y's alone
			my @t = (0, unpack "x$k J11", $counts);
			my @in = splice @t, 9;
			$k += $pair;
			# Flat, but for het and only: on 1,000 samples (2026-10-19) the pairs took
			# 560 MB with no field a hash, and 1,110 MB with four, which were these two
			# and each sample's hom-ALT count and share of ibs0.
			my %s;
			$s{sites} = 0;
			$s{sites} += $_ foreach @t;
			@in = ($s{sites}, 0, 0) if @vcf == 1;
			$s{in_both} = $in[0];
			$s{only} = { $x => $in[1], $y => $in[2] };
			$s{ibs0} = $t[2] + $t[6];
			$s{ibs1} = $t[1] + $t[3] + $t[5] + $t[7];
			$s{ibs2} = $t[4] + $t[8];
			$s{het_het} = $t[4];
			$s{het} = { $x => $t[3] + $t[4] + $t[5], $y => $t[1] + $t[4] + $t[7] };
			$s{kinship} = _king($s{het}{$x}, $s{het}{$y}, $s{het_het}, $s{ibs0});
			$s{ibs0_rate} = $s{sites} ? $s{ibs0} / $s{sites} : undef;
			# parent's reasons for dying, in parent's order
			$s{undecided} = $s{sites} && !($t[1] + $t[2] + $t[3] + $t[6])
				? 'neither has a hom-REF call where the other carries the ALT, so no opposite homozygote can be seen, as in a VCF merged from VCFs that list only their own variants; give each sample\'s own VCF instead'
				: $s{sites} < $Parent_sites ? "$s{sites} sites compared, and $Parent_sites are needed"
				: !defined $s{kinship} ? ($s{het}{$x} ? $y : $x) . ' has no het call at the sites compared'
				: undef;
			$s{relationship} = defined $s{undecided} ? undef : _relationship($s{kinship}, $s{ibs0_rate}, $r{max_ibs0});
			$s{parent} = $s{category} = undef; # below, once every pair is known
			$out{$x}{$y} = $out{$y}{$x} = \%s;
		}
	}
	undef $counts;
	# Which of a parent and child is the parent, where a third sample says, since
	# two people's genotypes cannot: x is y's parent when x has another child who
	# is y's full sibling, or when y has another parent who is unrelated to x, the
	# two being y's parents. Two of y's parent-child partners who are
	# second-degree relatives are y's parent and y's child, and say nothing about
	# which. "Third-degree" is not taken as unrelated: in the CEPH 1463 pedigree
	# (peddy's ceph1463.peddy.vcf.gz), the grandfather NA12889 and grandson
	# NA12893 had a kinship of 0.0839, below KING's 0.0884, and would have made
	# NA12893's father NA12877 his son too.
	my %pc; # sample => its parent-child partners
	$each_pair->(sub {
		my ($x, $y, $s) = @_;
		return unless ($s->{relationship} // '') eq 'parent-child';
		push @{ $pc{$x} }, $y;
		push @{ $pc{$y} }, $x;
	});
	my $is_parent = sub { # 1 or 0, and never a list, which would spill into the caller's next variable
		my ($x, $y) = @_;
		(grep { $_ ne $y && ($out{$y}{$_}{relationship} // '') eq 'full siblings' } @{ $pc{$x} })
			|| (grep { $_ ne $x && ($out{$x}{$_}{relationship} // '') eq 'unrelated' } @{ $pc{$y} }) ? 1 : 0;
	};
	$each_pair->(sub {
		my ($x, $y, $s) = @_;
		my ($rel, $sx, $sy) = ($s->{relationship}, $tally->{$x}{sex}, $tally->{$y}{sex});
		return unless defined $rel;
		if ($rel eq 'parent-child') {
			my ($x_is, $y_is) = ($is_parent->($x, $y), $is_parent->($y, $x));
			$s->{parent} = $x_is && !$y_is ? $x : $y_is && !$x_is ? $y : undef; # undef when neither is said, or both
			if (defined $s->{parent}) {
				my ($ps, $cs) = $s->{parent} eq $x ? ($sx, $sy) : ($sy, $sx);
				$s->{category} = ($ps ? $Kin_word{$ps}[0] : 'parent') . '-' . ($cs ? $Kin_word{$cs}[1] : 'child');
			} else { # two men are father and son, whichever is which
				$s->{category} = $sx && $sy && $sx eq $sy ? "$Kin_word{$sx}[0]-$Kin_word{$sx}[1]" : 'parent-child';
			}
		} elsif ($rel eq 'full siblings') {
			$s->{category} = !$sx || !$sy ? 'full siblings' : $sx ne $sy ? 'brother-sister' : $sx eq 'male' ? 'brothers' : 'sisters';
		} else {
			$s->{category} = $rel;
		}
	});
	if ($r{report}) {
		print STDOUT _relatedness_report(\@vcf, \%r, $names, $tally, $each_pair) or croak "$sub: can't print the report: $!";
	}
	my ($undecided, $first) = (0); # the pairs undecided, and the first of them as [first, second, why]
	my @regions; # as parent warns, and for its reasons: the pairs whose VCFs differ in their regions
	$each_pair->(sub {
		my ($x, $y, $s) = @_;
		if (defined $s->{undecided}) {
			$first //= [$x, $y, $s->{undecided}];
			$undecided++;
		}
		my ($more, $fewer) = $s->{only}{$x} > $s->{only}{$y} ? ($x, $y) : ($y, $x);
		push @regions, "$tally->{$more}{file} against $tally->{$fewer}{file} ($s->{only}{$more} to $s->{only}{$fewer})"
			if @vcf > 1 && _regions_differ($s->{only}{$more}, $s->{only}{$fewer}, $s->{sites});
	});
	my $n_pairs = @{ $names } * (@{ $names } - 1) / 2;
	carp "$sub: $undecided of $n_pairs pairs are undecided, and their relationship undef, such as $first->[0] and $first->[1]: $first->[2]" if $undecided;
	carp "$sub: the VCFs of " . scalar(@regions) . ' pair' . (@regions == 1 ? ' were' : 's were') . ' probably not sequenced over the same regions (an exome and a genome, or two capture kits),'
		. ' since one has more than twice as many sites that the other lacks as the other has that it lacks: '
		. join(', ', @regions[0 .. ($#regions < 2 ? $#regions : 2)]) . (@regions > 3 ? ', and ' . (@regions - 3) . ' more' : '')
		. '; a site that one lacks is taken as hom-REF in it, so their IBS0 and kinship are not to be trusted'
		if @regions;
	wantarray ? (\%out, $tally) : \%out;
}

# ---- genotype concordance

# concordance's report, given its files, the resolved options, its result,
# and the test's samples in its file's order. Columns are
# as wide as their widest entry, numbers right-aligned.
sub _concordance_report {
	my ($test, $truth, $r, $out, $test_names) = @_;
	my @pairs = map { $out->{$_} } grep { exists $out->{$_} } @{ $test_names }; # not a slice, which grep would autovivify into $out
	my $renamed = grep { $_->{test_sample} ne $_->{truth_sample} } @pairs; # the truth's sample is shown only when one is named otherwise
	my @head = ('sample', $renamed ? 'truth sample' : (), 'sites', 'in truth', 'concordant', 'discordant', 'gained', 'lost',
		'concordance', 'precision', 'recall', 'specificity');
	my $ratio = sub { defined $_[0] ? sprintf('%.4f', $_[0]) : '-' };
	my @rows = map {
		my ($c, $m) = @{ $_ }{qw(counts metrics)};
		my ($agree, $differ) = (0, 0);
		foreach my $kind (keys %{ $c }) {
			$agree += $c->{$kind} if $kind =~ /\Aconcordant_/;
			$differ += $c->{$kind} if $kind =~ /\Adiscordant_/;
		}
		[$_->{test_sample}, $renamed ? $_->{truth_sample} : (), $_->{sites}, $_->{in_truth}, $agree, $differ, @{ $c }{qw(gained_site lost_site)},
			map { $ratio->($m->{$_}) } qw(genotype_concordance precision_genotype recall_genotype specificity_genotype)]
	} @pairs;
	my @w = map { length } @head;
	foreach my $row (@rows) {
		foreach my $i (0 .. $#head) {
			$w[$i] = length $row->[$i] if length $row->[$i] > $w[$i];
		}
	}
	my $text_cols = $renamed ? 2 : 1;
	my $line = sub { join('  ', map { $_ < $text_cols ? sprintf('%-*s', $w[$_], $_[$_]) : sprintf('%*s', $w[$_], $_[$_]) } 0 .. $#head) . "\n" };
	my @alone = grep { !exists $out->{$_} } @{ $test_names };
	"concordance: test $test against truth $truth\n"
		. 'each test site compared with the truth\'s of the same CHROM, POS, REF and ALT, a site the truth lacks being a no-call there'
		. ($r->{min_depth} ? ", and a genotype of DP below $r->{min_depth} a no-call" : '')
		. "; precision, recall and specificity are of genotypes\n"
		. $line->(@head) . join('', map { $line->(@{ $_ }) } @rows)
		. (@alone ? scalar(@alone) . ' of the test\'s ' . scalar(@{ $test_names }) . ' samples are not in the truth: '
			. join(', ', @alone[0 .. ($#alone < 4 ? $#alone : 4)]) . (@alone > 5 ? ', and ' . (@alone - 5) . ' more' : '') . "\n" : '');
}

sub concordance {
	my $sub = 'concordance';
	my $args = _args(\@_, $sub, [qw(test truth)], [qw(discordances min_depth report)]);
	my %r;
	# x.low_ram_local_concordance.pl, which this is taken from, had no depth filter
	$r{min_depth} = $args->{min_depth} // 0; # 0 = every genotype compared, whatever its DP; otherwise a genotype of DP below it is a no-call
	croak "$sub: \"min_depth\" must be a whole number, 0 or more, not " . _what($r{min_depth})
		unless !ref $r{min_depth} && $r{min_depth} =~ /\A[0-9]+\z/;
	$r{discordances} = $args->{discordances} // 1; # 1 = list each discordant, gained and lost site; 0 = only count them, and "discordances" is undef
	croak "$sub: \"discordances\" must be 0 or 1, not " . _what($r{discordances})
		unless !ref $r{discordances} && ($r{discordances} eq '0' || $r{discordances} eq '1');
	$r{report} = $args->{report} // 1; # 1 = print a table of the samples to STDOUT; 0 = only return them
	croak "$sub: \"report\" must be 0 or 1, not " . _what($r{report}) unless !ref $r{report} && ($r{report} eq '0' || $r{report} eq '1');
	my ($test, $truth) = @{ $args }{qw(test truth)};
	# both checked before either is read, which can take minutes
	_vcf_check($sub, 'test', $test);
	_vcf_check($sub, 'truth', $truth);
	_same_build($sub, $test, $truth); # reads only the headers
	# the truth's samples first, so that the test's reading keeps the calls of
	# only those samples it will compare
	my ($next, $close) = _vcf_open($sub, 'truth', $truth);
	my ($truth_names) = _located(sub { _vcf_samples($next, $truth) });
	$close->();
	my ($test_next, $test_close) = _vcf_open($sub, 'test', $test);
	my ($truth_next, $truth_close) = _vcf_open($sub, 'truth', $truth);
	my ($out, $test_names) = _located(sub { _concordance($test_next, $test, $truth_next, $truth, $truth_names, $r{min_depth}, $r{discordances}) });
	$test_close->();
	$truth_close->();
	if ($r{report}) {
		print STDOUT _concordance_report($test, $truth, \%r, $out, $test_names) or croak "$sub: can't print the report: $!";
	}
	my ($any) = values %{ $out }; # every pair has the same sites
	carp "$sub: \"test\" $test has no records, so nothing was compared" unless $any->{sites};
	carp "$sub: none of the $any->{sites} sites of \"test\" $test is in \"truth\" $truth, so every call of the test is gained or a no-call;"
		. ' check that the two are of the same genome build'
		if $any->{sites} && !$any->{in_truth};
	$out;
}

# ---- trait prediction

# GRCh37's and GRCh38's lengths for four of the chromosomes the HIrisPlex-S
# panel sits on, which _hirisplex_build tells one build from the other by.
# From Ensembl's /info/assembly/homo_sapiens, rest.ensembl.org for GRCh38 and
# grch37.rest.ensembl.org for GRCh37, read 2026-10-20. hg19 and b37 differ
# only in what they call their chromosomes, and hg38 and b38 likewise, so a
# length separates the two pairs but not the two within a pair, which the
# panel's positions do not depend on.
my %Build_length = (
	b37 => { 1 => 249250621, 15 => 102531392, 16 => 90354753, 20 => 63025520 },
	b38 => { 1 => 248956422, 15 => 101991189, 16 => 90338345, 20 => 64444167 },
);

# The HIrisPlex-S marker panel, share/hirisplex_s_panel.tsv, read once into an
# array ref of hash refs in the panel's own order. share/make_hirisplex_panel.pl
# writes that file and its header comment says where every column comes from.
my $Panel; # undef until the file has been read

# The data file $name (a marker panel, or the genetic codes), which this
# distribution installs in its share directory, as a file that can be read;
# dies, naming $sub, when it is nowhere.
sub _share_file {
	my ($sub, $name) = @_;
	# Installed, the panel is in the distribution's share directory, which is
	# what File::ShareDir finds. Two fallbacks follow it: the same layout looked
	# for in @INC, which is where blib puts the file under "make test" and keeps
	# this working on a perl that has not got File::ShareDir, and the share
	# directory beside lib/, which is what lets a working copy be used before
	# the module is installed.
	my $file = eval { require File::ShareDir; File::ShareDir::dist_file('Cn-Bioinf', $name) };
	unless (defined $file && -f $file) {
		my @try = map { File::Spec->catfile($_, 'auto', 'share', 'dist', 'Cn-Bioinf', $name) } grep { !ref } @INC;
		my (undef, $dir) = File::Spec->splitpath($INC{'Cn/Bioinf.pm'} // '');
		push @try, File::Spec->catfile($dir, File::Spec->updir, File::Spec->updir, 'share', $name) if length $dir;
		($file) = grep { -f $_ && -r _ } @try;
	}
	croak "$sub: can't find $name, which this distribution installs in its share directory"
		unless defined $file && -f $file && -r _;
	$file;
}

sub _hirisplex_panel {
	my ($sub) = @_;
	return $Panel if $Panel;
	my $file = _share_file($sub, 'hirisplex_s_panel.tsv');
	open my $fh, '<', $file or croak "$sub: can't read $file: $!";
	my $head = <$fh>;
	croak "$sub: marker panel $file is empty" unless defined $head;
	$head =~ s/\r?\n\z//;
	$head =~ s/\A#//;
	my @cols = split /\t/, $head, -1;
	my @panel;
	while (defined(my $line = <$fh>)) {
		$line =~ s/\r?\n\z//;
		next if $line eq '';
		my %m;
		@m{@cols} = split /\t/, $line, -1;
		push @panel, \%m;
	}
	close $fh or croak "$sub: can't read $file: $!";
	croak "$sub: marker panel $file has no markers" unless @panel;
	foreach my $m (@panel) {
		foreach my $c (qw(rsid gene input_allele count_allele kind)) {
			croak "$sub: marker " . ($m->{rsid} // '?') . " of $file has no $c" unless defined $m->{$c} && length $m->{$c};
		}
		# Every marker of this panel is autosomal, and the reader counts a
		# diploid call only, so a sex chromosome here would be counted wrongly
		# rather than refused.
		foreach my $b (qw(b37 b38)) {
			my ($c, $p) = @{ $m }{"${b}_chrom", "${b}_pos"};
			next unless defined $c && length $c;
			croak "$sub: marker $m->{rsid} of $file is on $b chromosome \"$c\", and the panel is autosomal"
				unless $c =~ /\A(?:[1-9]|1[0-9]|2[0-2])\z/;
			croak "$sub: marker $m->{rsid} of $file has $b position " . _what($p) . ", which isn't a position"
				unless defined $p && $p =~ /\A[1-9][0-9]*\z/;
		}
	}
	$Panel = \@panel;
}

# Which build's coordinates the panel is matched on, read from the ##contig
# lines of the VCF $file, given to $sub as "vcf": "b37" or "b38". A header
# that gives no length for any of the chromosomes above, or lengths that are
# neither build's, cannot be told apart and dies asking for "build".
sub _hirisplex_build {
	my ($sub, $file) = @_;
	my $meta = _vcf_meta($sub, 'vcf', $file);
	my %length; # contig => the first length its header gives
	foreach my $c (@{ $meta->{contig} }) {
		$length{ $c->[0] } //= $c->[1] if defined $c->[1];
	}
	my @named = grep { defined $length{$_} } sort { $a <=> $b } keys %{ $Build_length{b37} };
	croak "$sub: \"vcf\" $file has no ##contig line giving a length for chromosome "
		. join(', ', sort { $a <=> $b } keys %{ $Build_length{b37} }) . ', so its genome build can\'t be told from its header;'
		. ' give "build" as hg19, b37, hg38 or b38' unless @named;
	my @fits = grep { my $b = $_; !grep { $length{$_} != $Build_length{$b}{$_} } @named } sort keys %Build_length;
	croak "$sub: \"vcf\" $file gives chromosome lengths that are neither GRCh37's nor GRCh38's ("
		. join(', ', map { "$_ is $length{$_}" } @named) . '), so its genome build can\'t be told from its header;'
		. ' give "build" as hg19, b37, hg38 or b38' unless @fits == 1;
	$fits[0];
}

# Whether each prediction can be made at all from $d, one genotype for each
# marker of $panel and undef where the sample had no call. The webtool refuses
# some outright, whatever the genotypes say, because the loss in AUC is too
# great; from the HIrisPlex-S user manual (version 2.0, 2018,
# https://hirisplex.erasmusmc.nl/pdf/hirisplex.erasmusmc.nl.pdf, read
# 2026-10-20), page 2: "Inputs missing the HERC2 SNP (rs12913832 = NA) will
# not provide an eye colour prediction result, as the loss in AUC is too
# great. Inputs missing all 11 MC1R SNPs will not provide a hair colour
# prediction result. Inputs missing a combination of HERC2-SLC45A2-IRF4 will
# not produce and eye or hair prediction result." The manual gives no such
# rule for skin, and says only that missing any marker "is not advised", so
# skin is refused here only when nothing at all was called.
sub _hirisplex_possible {
	my ($panel, $d) = @_;
	my %called; # rs number => 1 for each marker the sample has a genotype at
	my ($mc1r, $any) = (0, 0);
	foreach my $k (0 .. $#{ $panel }) {
		next unless defined $d->[$k];
		$called{ $panel->[$k]{rsid} } = 1;
		$mc1r++ if $panel->[$k]{gene} eq 'MC1R';
		$any++;
	}
	# HERC2 rs12913832, SLC45A2 rs16891982 and IRF4 rs12203592: eye needs the
	# first, so it needs one of the three already, and hair needs one of them
	my $three = grep { $called{$_} } qw(rs12913832 rs16891982 rs12203592);
	{
		eye  => $called{rs12913832} ? 1 : 0,
		hair => $mc1r && $three ? 1 : 0,
		skin => $any ? 1 : 0,
	};
}

# The genotypes of $out written to $file as the CSV the HIrisPlex-S webtool
# takes: a sampleid column and one for each marker, headed
# "<rs number>_<input allele>" as the webtool's own template heads it, holding
# the count of that allele or NA. The samples are written in $order, the VCF's.
sub _hirisplex_csv {
	my ($sub, $file, $panel, $out, $order) = @_;
	my @head = map { "$_->{rsid}_$_->{input_allele}" } @{ $panel };
	# The webtool reads the file as plain CSV, so a sample whose name holds a
	# comma, a quote or a newline would move or split its row rather than
	# being quoted into it.
	my @bad = grep { /[",\r\n]/ } @{ $order };
	croak "$sub: can't write $file: sample" . (@bad > 1 ? 's ' : ' ') . join(', ', map { "\"$_\"" } @bad)
		. (@bad > 1 ? ' have' : ' has') . ' a comma, a quote or a newline in the name, which a CSV column can\'t hold' if @bad;
	open my $fh, '>', $file or croak "$sub: can't write $file: $!";
	print {$fh} join(',', 'sampleid', @head), "\n" or croak "$sub: can't write $file: $!";
	foreach my $s (@{ $order }) {
		my $g = $out->{$s}{genotype};
		print {$fh} join(',', $s, map { defined $g->{$_} ? $g->{$_} : 'NA' } @head), "\n" or croak "$sub: can't write $file: $!";
	}
	close $fh or croak "$sub: can't write $file: $!";
}

# hirisplex_genotypes's report on $vcf: what was read and how, then a table of
# the samples in $order, the VCF's, each with how many markers were called and
# which predictions its genotypes allow.
sub _hirisplex_report {
	my ($vcf, $r, $panel, $out, $order, $absent) = @_;
	my @head = ('sample', 'called', 'missing', 'eye', 'hair', 'skin');
	my @rows = map {
		my $s = $out->{$_};
		[$_, $s->{called}, scalar @{ $s->{missing} }, map { $s->{$_} ? 'yes' : 'no' } qw(eye hair skin)]
	} @{ $order };
	my @w = map { length $head[$_] } 0 .. $#head;
	foreach my $row (@rows) {
		foreach my $i (0 .. $#head) {
			$w[$i] = length $row->[$i] if length $row->[$i] > $w[$i];
		}
	}
	my $line = sub { join('  ', map { $_ == 0 ? sprintf('%-*s', $w[$_], $_[$_]) : sprintf('%*s', $w[$_], $_[$_]) } 0 .. $#head) . "\n" };
	"hirisplex_genotypes: $vcf\n"
		. scalar(@{ $panel }) . ' HIrisPlex-S markers, matched by '
		. ($r->{match} eq 'id' ? 'rs number' : "position on $r->{build}")
		. "; genotypes of DP below $r->{min_depth} not counted\n"
		. (@{ $absent } ? scalar(@{ $absent }) . ' marker' . (@{ $absent } > 1 ? 's' : '') . ' not in the file at all: '
			. join(', ', @{ $absent }) . "\n" : '')
		. $line->(@head) . join('', map { $line->(@{ $_ }) } @rows)
		. "\"eye\", \"hair\" and \"skin\" are whether the HIrisPlex-S manual's rules allow that prediction from these markers\n";
}

sub hirisplex_genotypes {
	my $sub = 'hirisplex_genotypes';
	# hirisplex_genotypes($file) and hirisplex_genotypes($file, %options) take
	# the file first, as sex_check does; an odd count whose first is an
	# option's name is left for _args to refuse
	unshift @_, 'vcf' if @_ % 2 && defined $_[0] && !ref $_[0] && $_[0] !~ /\A(?:vcf|build|file|match|min_depth|report)\z/;
	croak "$sub: \"$_[0]\" is the file, so the options after it must be name => value pairs, and are an odd number"
		if @_ && defined $_[0] && !ref $_[0] && $_[0] ne 'vcf' && -f $_[0];
	my $args = _args(\@_, $sub, ['vcf'], [qw(build file match min_depth report)]);
	my %r;
	$r{match} = $args->{match} // 'position'; # 'position' = CHROM and POS against the panel's coordinates; 'id' = the ID column against its rs numbers
	croak "$sub: \"match\" must be \"position\" or \"id\", not " . _what($r{match})
		unless !ref $r{match} && ($r{match} eq 'position' || $r{match} eq 'id');
	$r{min_depth} = $args->{min_depth} // 7; # 0 = count every genotype, whatever its DP; 7 is sex_check's, for sex_check's reasons
	croak "$sub: \"min_depth\" must be a whole number, 0 or more, not " . _what($r{min_depth})
		unless !ref $r{min_depth} && $r{min_depth} =~ /\A[0-9]+\z/;
	$r{report} = $args->{report} // 1; # 1 = print a table of the samples to STDOUT; 0 = only return them
	croak "$sub: \"report\" must be 0 or 1, not " . _what($r{report}) unless !ref $r{report} && ($r{report} eq '0' || $r{report} eq '1');
	$r{file} = $args->{file}; # undef = no CSV is written
	croak "$sub: \"file\" must be a file name, not " . _what($r{file}) if defined $r{file} && ref $r{file};
	croak "$sub: \"build\" must be hg19, b37, hg38 or b38, not " . _what($args->{build})
		if defined $args->{build} && (ref $args->{build} || $args->{build} !~ /\A(?:hg19|b37|hg38|b38)\z/);
	my $vcf = $args->{vcf};
	_vcf_check($sub, 'vcf', $vcf);
	my $panel = _hirisplex_panel($sub);
	# which of the panel's two sets of coordinates the markers are looked for
	# at; undef when matching by rs number, which needs neither
	$r{build} = $r{match} eq 'id' ? undef
		: defined $args->{build} ? ($args->{build} =~ /\A(?:hg19|b37)\z/ ? 'b37' : 'b38')
		: _hirisplex_build($sub, $vcf);

	# What the reader searches for: one entry for each marker, and for matching
	# by rs number a second under the number that marker's has been merged
	# into, since a VCF annotated from either dbSNP release should match.
	my @entries;
	foreach my $k (0 .. $#{ $panel }) {
		my $m = $panel->[$k];
		my $insertion = $m->{kind} eq 'insertion' ? 1 : 0; # 1 = count the ALT longer than REF, 0 = count count_allele
		if ($r{match} eq 'id') {
			my %seen;
			foreach my $id (grep { defined $_ && length $_ && !$seen{$_}++ } $m->{rsid}, $m->{current_rsid}) {
				push @entries, [0, 0, $m->{count_allele}, $insertion, $id, $k];
			}
		} else {
			my ($c, $p) = @{ $m }{"$r{build}_chrom", "$r{build}_pos"};
			# a marker the panel could not place on this build is searched for
			# nowhere, and comes back as one the file did not hold
			next unless defined $c && length $c;
			push @entries, [$c, $p, $m->{count_allele}, $insertion, $m->{rsid}, $k];
		}
	}
	croak "$sub: no marker of the panel has a " . ($r{build} // 'known') . ' position' unless @entries;

	my ($next, $close) = _vcf_open($sub, 'vcf', $vcf);
	my ($dose, $names, $seen) = _located(sub { _hirisplex_dosage($next, $vcf, $r{min_depth}, \@entries, scalar @{ $panel }, $r{match} eq 'id' ? 1 : 0) });
	$close->();

	my @column = map { "$_->{rsid}_$_->{input_allele}" } @{ $panel };
	my @absent = map { $panel->[$_]{rsid} } grep { !$seen->[$_] } 0 .. $#{ $panel };
	my %out;
	foreach my $s (keys %{ $dose }) {
		my $d = $dose->{$s};
		my (%genotype, @missing);
		foreach my $k (0 .. $#{ $panel }) {
			$genotype{ $column[$k] } = $d->[$k];
			push @missing, $panel->[$k]{rsid} unless defined $d->[$k];
		}
		my $can = _hirisplex_possible($panel, $d);
		$out{$s} = {
			genotype => \%genotype,
			missing  => \@missing,
			markers  => scalar @{ $panel },
			called   => scalar(@{ $panel }) - scalar(@missing),
			%{ $can },
		};
	}
	_hirisplex_csv($sub, $r{file}, $panel, \%out, $names) if defined $r{file};
	if ($r{report}) {
		print STDOUT _hirisplex_report($vcf, \%r, $panel, \%out, $names, \@absent) or croak "$sub: can't print the report: $!";
	}
	carp "$sub: \"vcf\" $vcf holds none of the " . scalar(@{ $panel }) . ' HIrisPlex-S markers'
		. ($r{match} eq 'id' ? '; it was matched by rs number, and a VCF whose ID column is "." matches nothing that way'
			: ", matched by position on $r{build}; check that it is the build the file is on")
		if @absent == @{ $panel };
	\%out;
}

# The marker that carries a category's intercept, in place of an rs number, in
# a "model" table. A marker can't be called this, so nothing is ambiguous.
my $Intercept = '(intercept)';

# The rows of "model" read into trait => category => { marker => beta }, with
# the intercept under $Intercept, and the traits and their categories in the
# order the table first names them, which is the order the report prints.
sub _trait_model {
	my ($sub, $model) = @_;
	my ($next, $cols) = _weight_rows($sub, $model, 'model');
	my %have = map { $_ => 1 } @{ $cols };
	my @absent = grep { !$have{$_} } qw(trait category marker beta);
	croak "$sub: \"model\" has no " . join(', ', map { "\"$_\"" } @absent) . ' column' . (@absent > 1 ? 's' : '')
		. '; a model table has trait, category, marker and beta' if @absent;
	my (%beta, @traits, %category);
	while (my ($row, $label) = $next->()) {
		my ($t, $c, $m, $b) = @{ $row }{qw(trait category marker beta)};
		foreach my $f (['trait', $t], ['category', $c], ['marker', $m]) {
			croak "$sub: $label of \"model\" has no $f->[0]" unless defined $f->[1] && length $f->[1];
		}
		croak "$sub: $label of \"model\" has beta " . _what($b) . ", which isn't a number"
			unless defined $b && !ref $b && $b =~ $Number;
		push @traits, $t unless $beta{$t};
		push @{ $category{$t} }, $c unless $beta{$t} && $beta{$t}{$c};
		croak "$sub: $label of \"model\" gives $t category \"$c\" a second beta for $m"
			if exists $beta{$t}{$c}{$m};
		$beta{$t}{$c}{$m} = $b;
	}
	croak "$sub: \"model\" has no rows" unless @traits;
	(\%beta, \@traits, \%category);
}

# exp() of each of @$eta, divided by their sum: the probabilities a multinomial
# logistic regression gives its categories. The largest is taken out first, so
# that a linear predictor big enough to overflow exp() (about 710 on an IEEE
# double, and larger on a long-double or quadmath perl) gives 1 and the rest 0
# rather than inf/inf, which is NaN.
sub _softmax {
	my ($eta) = @_;
	my $max = $eta->[0];
	foreach my $e (@{ $eta }) { $max = $e if $e > $max }
	my @exp = map { exp($_ - $max) } @{ $eta };
	my $sum = 0;
	$sum += $_ foreach @exp;
	[map { $_ / $sum } @exp];
}

# trait_predict's report on $out: a table of each sample's probabilities, one
# block for each trait, the categories in the model's order.
sub _trait_report {
	my ($r, $out, $order, $traits, $category) = @_;
	my $text = "trait_predict: " . scalar(@{ $order }) . ' sample' . (@{ $order } > 1 ? 's' : '')
		. ', ' . scalar(@{ $traits }) . ' trait' . (@{ $traits } > 1 ? 's' : '')
		. "; a marker the sample has no genotype for counts as 0 copies"
		. ($r->{force} ? ', and a prediction the HIrisPlex-S rules refuse is made anyway ("force")' : '') . "\n";
	foreach my $t (@{ $traits }) {
		my @head = ('sample', 'call', @{ $category->{$t} }, 'called');
		my @rows = map {
			my $p = $out->{$_}{$t};
			[$_, $p->{call} // '-', (map { defined $p->{p}{$_} ? sprintf('%.3f', $p->{p}{$_}) : '-' } @{ $category->{$t} }),
				"$p->{called}/$p->{markers}"]
		} @{ $order };
		my @w = map { length $head[$_] } 0 .. $#head;
		foreach my $row (@rows) {
			foreach my $i (0 .. $#head) {
				$w[$i] = length $row->[$i] if length $row->[$i] > $w[$i];
			}
		}
		my $line = sub { join('  ', map { $_ == 0 ? sprintf('%-*s', $w[$_], $_[$_]) : sprintf('%*s', $w[$_], $_[$_]) } 0 .. $#head) . "\n" };
		$text .= "\n$t\n" . $line->(@head) . join('', map { $line->(@{ $_ }) } @rows);
		my @refused = grep { defined $out->{$_}{$t}{refused} } @{ $order };
		$text .= join '', map { "  $_: no $t prediction: $out->{$_}{$t}{refused}\n" } @refused;
	}
	$text;
}

sub trait_predict {
	my $sub = 'trait_predict';
	my $args = _args(\@_, $sub, [qw(genotypes model)], [qw(force report)]);
	my %r;
	$r{force} = $args->{force} // 0; # 0 = a trait the genotypes say can't be predicted isn't; 1 = predict it anyway
	croak "$sub: \"force\" must be 0 or 1, not " . _what($r{force}) unless !ref $r{force} && ($r{force} eq '0' || $r{force} eq '1');
	$r{report} = $args->{report} // 1; # 1 = print a table of the samples to STDOUT; 0 = only return them
	croak "$sub: \"report\" must be 0 or 1, not " . _what($r{report}) unless !ref $r{report} && ($r{report} eq '0' || $r{report} eq '1');
	my $g = $args->{genotypes};
	croak "$sub: \"genotypes\" must be a hash ref of sample => genotypes, as hirisplex_genotypes returns, not " . _what($g)
		unless ref $g eq 'HASH';
	croak "$sub: \"genotypes\" has no samples" unless keys %{ $g };
	my ($beta, $traits, $category) = _trait_model($sub, $args->{model});

	# Which markers each trait's categories use between them: the same for every
	# sample, so it is worked out once rather than once per sample.
	my %uses;
	foreach my $t (@{ $traits }) {
		foreach my $c (@{ $category->{$t} }) {
			$uses{$t}{$_} = 1 foreach grep { $_ ne $Intercept } keys %{ $beta->{$t}{$c} };
		}
	}
	my %used = map { %{ $uses{$_} } } keys %uses; # every trait's markers, whose dosages are checked

	my %out;
	foreach my $s (sort keys %{ $g }) {
		my $rec = $g->{$s};
		croak "$sub: \"genotypes\" sample \"$s\" must be a hash ref, not " . _what($rec) unless ref $rec eq 'HASH';
		# Either what hirisplex_genotypes returns, whose genotypes are under
		# "genotype" and which also says which predictions its markers allow,
		# or a plain hash of marker => dosage.
		my $dose = ref $rec->{genotype} eq 'HASH' ? $rec->{genotype} : $rec;
		# A dosage may be fractional, as imputation gives, but anything else
		# would be multiplied in as 0 copies and counted as called.
		foreach my $m (sort keys %used) {
			my $d = $dose->{$m};
			croak "$sub: \"genotypes\" sample \"$s\" has $m " . _what($d) . ", which isn't a dosage from 0 to 2; a missing genotype is undef"
				unless !defined $d || (!ref $d && $d =~ $Number && $d >= 0 && $d <= 2);
		}
		foreach my $t (@{ $traits }) {
			my (@eta, @missing);
			my $called = 0;
			my $marker = $uses{$t};
			foreach my $m (sort keys %{ $marker }) {
				if (defined $dose->{$m}) { $called++ } else { push @missing, $m }
			}
			foreach my $c (@{ $category->{$t} }) {
				my $eta = $beta->{$t}{$c}{$Intercept} // 0;
				foreach my $m (keys %{ $beta->{$t}{$c} }) {
					next if $m eq $Intercept;
					# A marker with no genotype drops out of the sum, which is
					# the same as counting it 0 copies of the counted allele.
					$eta += $beta->{$t}{$c}{$m} * $dose->{$m} if defined $dose->{$m};
				}
				push @eta, $eta;
			}
			# hirisplex_genotypes sets eye, hair and skin to 0 where the
			# HIrisPlex-S manual refuses the prediction outright; a model whose
			# trait it says nothing about is predicted whatever it holds.
			my $refused = !$r{force} && defined $rec->{$t} && !ref $rec->{$t} && $rec->{$t} eq '0'
				? 'the markers it needs are missing, and the HIrisPlex-S rules refuse it' : undef;
			my $p = $refused ? {} : do {
				my $soft = _softmax(\@eta);
				my %p;
				@p{ @{ $category->{$t} } } = @{ $soft };
				\%p;
			};
			my ($call) = $refused ? () : sort { $p->{$b} <=> $p->{$a} || $a cmp $b } keys %{ $p };
			$out{$s}{$t} = {
				p       => $p,
				call    => $call,
				markers => scalar keys %{ $marker },
				called  => $called,
				missing => \@missing,
				refused => $refused,
			};
		}
	}
	if ($r{report}) {
		print STDOUT _trait_report(\%r, \%out, [sort keys %out], $traits, $category) or croak "$sub: can't print the report: $!";
	}
	\%out;
}

# ---- blood type

# The panel blood_type reads, share/blood_type_panel.tsv, once it has been
# read: a hash ref of
#
#   markers  every marker, a hash ref a row, in the file's order, which is
#            the order Bioinf.xs returns their genotypes in
#   abo      role => the marker's place in "markers", for the three of ABO:
#            "functional" (rs8176719, where the insertion counted is a
#            working A or B gene and its lack is O), "B" and "O2"
#   sites    the places in "markers" of RHD's sites
#   gene     the row of the RHD gene, whose span a deletion has to cover
#
# share/make_blood_type_panel.pl writes the file, and its header comment says
# where every row comes from and what was measured. The counted allele of
# every marker is an ALT on both builds, never the reference's own, which is
# what lets a marker with no record be read as no copies of it.
my $Blood_panel; # undef until the file has been read

sub _blood_panel {
	my ($sub) = @_;
	return $Blood_panel if $Blood_panel;
	my $file = _share_file($sub, 'blood_type_panel.tsv');
	open my $fh, '<', $file or croak "$sub: can't read $file: $!";
	my $head = <$fh>;
	croak "$sub: marker panel $file is empty" unless defined $head;
	$head =~ s/\r?\n\z//;
	$head =~ s/\A#//;
	my @cols = split /\t/, $head, -1;
	my %panel = (markers => [], abo => {}, sites => [], gene => undef);
	while (defined(my $line = <$fh>)) {
		$line =~ s/\r?\n\z//;
		next if $line eq '';
		my %m;
		@m{@cols} = split /\t/, $line, -1;
		foreach my $c (qw(name system role kind)) {
			croak "$sub: row " . ($m{name} // '?') . " of $file has no $c" unless defined $m{$c} && length $m{$c};
		}
		foreach my $b (qw(b37 b38)) {
			# vcf_chrom()'s numbering, which the panel's two chromosomes, 1 and 9, are already in
			croak "$sub: row $m{name} of $file is on $b chromosome " . _what($m{"${b}_chrom"}) . ', which isn\'t an autosome'
				unless defined $m{"${b}_chrom"} && $m{"${b}_chrom"} =~ /\A(?:[1-9]|1[0-9]|2[0-2])\z/;
			foreach my $c ("${b}_pos", $m{kind} eq 'region' ? "${b}_end" : ()) {
				croak "$sub: row $m{name} of $file has $c " . _what($m{$c}) . ', which isn\'t a position'
					unless defined $m{$c} && $m{$c} =~ /\A[1-9][0-9]*\z/;
			}
		}
		if ($m{kind} eq 'region') {
			croak "$sub: $file has more than one gene" if $panel{gene};
			$panel{gene} = \%m;
			next;
		}
		croak "$sub: marker $m{name} of $file counts " . _what($m{count_allele}) . ', which isn\'t one base'
			unless defined $m{count_allele} && $m{count_allele} =~ /\A[ACGT]\z/;
		push @{ $panel{markers} }, \%m;
		if ($m{system} eq 'ABO') {
			$panel{abo}{ $m{role} } = $#{ $panel{markers} };
		} else {
			push @{ $panel{sites} }, $#{ $panel{markers} };
		}
	}
	close $fh or croak "$sub: can't read $file: $!";
	croak "$sub: marker panel $file has no RHD gene" unless $panel{gene};
	croak "$sub: marker panel $file has no site of RHD" unless @{ $panel{sites} };
	foreach my $role (qw(functional B O2)) {
		croak "$sub: marker panel $file has no ABO marker of role \"$role\"" unless defined $panel{abo}{$role};
	}
	$Blood_panel = \%panel;
}

# The ABO genotype and phenotype that $n says, a hash ref of how many copies
# (0 to 2, or undef for no genotype) a sample has of each of the three ABO
# markers' counted alleles, by role: (genotype, phenotype, undef), or (undef,
# undef, the role whose genotype was needed and is missing).
#
# A chromosome without rs8176719's insertion is O whatever else it carries. One
# with it is B when it carries rs8176746's T, O when it carries rs41302905's T
# (the O2 allele, an O with no deletion), and otherwise A. The genotypes are
# not phased, so a B or O2 allele is taken to be on a chromosome that has the
# insertion, as long as there is one to put it on. That is nearly always
# right: of 1000 Genomes phase 3's 5,008 haplotypes (b37 BCF, read
# 2026-11-10), 721 carried the insertion with the B allele, 1,001 the
# insertion without it, 44 the B allele without the insertion and 3,242
# neither, so somebody heterozygous at both is B and O rather than A and an O
# that carries B's base with a probability of 721 * 3242 / (721 * 3242 + 1001
# * 44), which is 0.981.
sub _abo_type {
	my ($n) = @_;
	return (undef, undef, 'functional') unless defined $n->{functional};
	my $working = $n->{functional}; # chromosomes with a working gene, A or B, unless they are O2
	my ($b, $o2) = (0, 0);
	if ($working) {
		foreach my $role (qw(B O2)) {
			return (undef, undef, $role) unless defined $n->{$role};
		}
		$b = $n->{B} < $working ? $n->{B} : $working;
		$o2 = $n->{O2} < $working - $b ? $n->{O2} : $working - $b;
	}
	my %count = (A => $working - $b - $o2, B => $b, O => 2 - $working + $o2);
	my $genotype = join '', map { $_ x $count{$_} } qw(A B O);
	my $phenotype = $count{A} && $count{B} ? 'AB' : $count{A} ? 'A' : $count{B} ? 'B' : 'O';
	($genotype, $phenotype, undef);
}

# blood_type's report on $vcf: what was read and how, a table of the samples in
# $order, the VCF's, then what was taken as homozygous REF because the file has
# no record of it, and why any sample has no type.
sub _blood_report {
	my ($vcf, $r, $panel, $out, $order, $assumed) = @_;
	my $sites = scalar @{ $panel->{sites} };
	my @head = ('sample', 'type', 'ABO', 'ABO genotype', 'RhD', 'RhD genotype', 'RHD sites');
	my @rows = map {
		my $s = $out->{$_};
		[$_, $s->{type} // '-', $s->{abo}{phenotype} // '-', $s->{abo}{genotype} // '-',
			$s->{rhesus}{phenotype} // '-', $s->{rhesus}{genotype} // '-', "$s->{rhesus}{carried}/$sites"]
	} @{ $order };
	my @w = map { length $head[$_] } 0 .. $#head;
	foreach my $row (@rows) {
		foreach my $i (0 .. $#head) {
			$w[$i] = length $row->[$i] if length $row->[$i] > $w[$i];
		}
	}
	my $line = sub { join('  ', map { $_ < $#head ? sprintf('%-*s', $w[$_], $_[$_]) : sprintf('%*s', $w[$_], $_[$_]) } 0 .. $#head) . "\n" };
	my @why; # one line for each system of each sample that has no type
	foreach my $name (@{ $order }) {
		foreach my $system (qw(abo rhesus)) {
			my $why = $out->{$name}{$system}{why};
			push @why, "$name has no " . ($system eq 'abo' ? 'ABO' : 'RhD') . " type: $why\n" if defined $why;
		}
	}
	"blood_type: $vcf\n"
		. "ABO from rs8176719 (O's deletion), rs8176746 (B) and rs41302905 (O2); RhD from $sites sites of RHD, or a record of the gene's deletion;"
		. " matched by position on $r->{build}; genotypes of DP below $r->{min_depth} not counted\n"
		. $line->(@head) . join('', map { $line->(@{ $_ }) } @rows)
		. "\"RHD sites\" is how many of the sites the sample has an ALT allele at; one is enough for RhD positive\n"
		. (@{ $assumed } ? 'not in the file, and taken as homozygous for the reference allele: ' . join(', ', @{ $assumed }) . "\n" : '')
		. join('', @why);
}

sub blood_type {
	my $sub = 'blood_type';
	# blood_type($file) and blood_type($file, %options) take the file first,
	# as sex_check does; an odd count whose first is an option's name is left
	# for _args to refuse
	unshift @_, 'vcf' if @_ % 2 && defined $_[0] && !ref $_[0] && $_[0] !~ /\A(?:vcf|assume_ref|build|min_depth|report)\z/;
	croak "$sub: \"$_[0]\" is the file, so the options after it must be name => value pairs, and are an odd number"
		if @_ && defined $_[0] && !ref $_[0] && $_[0] ne 'vcf' && -f $_[0];
	my $args = _args(\@_, $sub, ['vcf'], [qw(assume_ref build min_depth report)]);
	my %r;
	# 1 = a marker the file has no record of is homozygous for the reference
	# allele, as a VCF that lists only its sample's variants means it;
	# 0 = it has no genotype, as in a file of every site, or of an array's
	$r{assume_ref} = $args->{assume_ref} // 1;
	croak "$sub: \"assume_ref\" must be 0 or 1, not " . _what($r{assume_ref})
		unless !ref $r{assume_ref} && ($r{assume_ref} eq '0' || $r{assume_ref} eq '1');
	$r{min_depth} = $args->{min_depth} // 7; # 0 = count every genotype, whatever its DP; 7 is sex_check's, and what the panel's sites were chosen at
	croak "$sub: \"min_depth\" must be a whole number, 0 or more, not " . _what($r{min_depth})
		unless !ref $r{min_depth} && $r{min_depth} =~ /\A[0-9]+\z/;
	$r{report} = $args->{report} // 1; # 1 = print a table of the samples to STDOUT; 0 = only return them
	croak "$sub: \"report\" must be 0 or 1, not " . _what($r{report}) unless !ref $r{report} && ($r{report} eq '0' || $r{report} eq '1');
	croak "$sub: \"build\" must be hg19, b37, hg38 or b38, not " . _what($args->{build})
		if defined $args->{build} && (ref $args->{build} || $args->{build} !~ /\A(?:hg19|b37|hg38|b38)\z/);
	my $vcf = $args->{vcf};
	_vcf_check($sub, 'vcf', $vcf);
	my $panel = _blood_panel($sub);
	# which of the panel's two sets of coordinates the markers are looked for at
	$r{build} = defined $args->{build} ? ($args->{build} =~ /\A(?:hg19|b37)\z/ ? 'b37' : 'b38') : _hirisplex_build($sub, $vcf);

	my @marker = @{ $panel->{markers} };
	my @entries = map {
		my $m = $marker[$_];
		[$m->{"$r{build}_chrom"}, $m->{"$r{build}_pos"}, $m->{count_allele}, $m->{kind} eq 'insertion' ? 1 : 0, $m->{name}, $_]
	} 0 .. $#marker;
	my $gene = $panel->{gene};
	my ($next, $close) = _vcf_open($sub, 'vcf', $vcf);
	my ($dose, $names, $seen, $deleted, $read, $longer) = _located(sub {
		_blood_type_tally($next, $vcf, $r{min_depth}, \@entries, scalar @marker, @{ $gene }{"$r{build}_chrom", "$r{build}_pos", "$r{build}_end"})
	});
	$close->();

	# Each marker the file has no record of: whether it is read as homozygous
	# REF, and if not, why not. The file must have been able to hold the
	# record: one with nothing on the marker's chromosome was not sequenced or
	# not called there, and one with no allele longer than a base on it holds
	# SNVs only, and cannot hold ABO's insertion.
	my (@as_ref, @unknown); # one per marker: 1 = unlisted and read as REF; why an unlisted marker has no genotype, or undef
	foreach my $k (0 .. $#marker) {
		next if $seen->[$k];
		my $m = $marker[$k];
		my $chrom = $m->{"$r{build}_chrom"};
		my $bit = 1 << $chrom;
		$unknown[$k] = !$r{assume_ref} ? "the file has no record of $m->{name}, and \"assume_ref\" is 0"
			: !($read & $bit) ? "the file has no record on chromosome $chrom"
			: $m->{kind} eq 'insertion' && !($longer & $bit)
				? "the file has no record of $m->{name}, an insertion, and no allele longer than one base on chromosome $chrom, so it holds SNVs only and could not show it"
			: undef;
		$as_ref[$k] = defined $unknown[$k] ? 0 : 1;
	}
	my @abo_role = sort { $panel->{abo}{$a} <=> $panel->{abo}{$b} } keys %{ $panel->{abo} };
	my @sites = @{ $panel->{sites} };
	my $listed = grep { $seen->[$_] } @sites;
	# why a sample with a genotype at none of the sites has no RhD type: the
	# file's reason when it has a record of none of them, and otherwise the
	# sample's calls at those it has
	my ($site_unknown) = $listed ? ("no genotype at any of the $listed RHD sites the file has a record of: the calls are missing, are not diploid, or have a DP below $r{min_depth}")
		: grep { defined } map { $unknown[$_] } @sites;

	my %out;
	foreach my $i (0 .. $#{ $names }) {
		my $name = $names->[$i];
		my $d = $dose->{$name};
		my (%n, %copies, @assumed);
		foreach my $role (@abo_role) {
			my $k = $panel->{abo}{$role};
			$n{$role} = $as_ref[$k] ? 0 : $d->[$k];
			$copies{ $marker[$k]{name} } = $n{$role};
			push @assumed, $marker[$k]{name} if $as_ref[$k];
		}
		my ($genotype, $phenotype, $lacking) = _abo_type(\%n);
		my $abo_why;
		if (defined $lacking) {
			my $k = $panel->{abo}{$lacking};
			$abo_why = $unknown[$k] // "no genotype at $marker[$k]{name}: the call is missing, is not diploid, or has a DP below $r{min_depth}";
		}
		my $carried = grep { $d->[$_] } @sites;
		# The sites this sample has a genotype at: a call the file has, or a
		# site it has no record of that is read as REF. No ALT is RhD negative
		# only where there is one; a site's no-call, or a call below
		# min_depth, is undef, and up to 2026-11-16 was counted as REF.
		my $typed = grep { $as_ref[$_] || defined $d->[$_] } @sites;
		my $lost = $deleted->[$i]; # copies of a deletion covering RHD: 0 to 2, or undef when the file has no record of one that calls this sample
		# 'deletion' = from a record of the gene's deletion; 'sites' = from the
		# RHD sites; undef = no type
		my ($rh_genotype, $rh_phenotype, $basis, $rh_why);
		if (defined $lost) {
			($rh_genotype, $rh_phenotype, $basis) = (('DD', 'Dd', 'dd')[$lost], $lost == 2 ? 'negative' : 'positive', 'deletion');
		} elsif ($carried) {
			# the second copy cannot be told from SNVs; see the README
			($rh_genotype, $rh_phenotype, $basis) = ('D.', 'positive', 'sites');
		} elsif ($typed) {
			($rh_genotype, $rh_phenotype, $basis) = ('dd', 'negative', 'sites');
		} else {
			$rh_why = $site_unknown;
		}
		$out{$name} = {
			type => defined $phenotype && defined $rh_phenotype ? $phenotype . ($rh_phenotype eq 'positive' ? '+' : '-') : undef,
			abo => {
				genotype    => $genotype,
				phenotype   => $phenotype,
				markers     => \%copies,
				assumed_ref => \@assumed,
				why         => $abo_why,
			},
			rhesus => {
				genotype  => $rh_genotype,
				phenotype => $rh_phenotype,
				basis     => $basis,
				sites     => scalar @sites,
				listed    => 0 + $listed,
				carried   => 0 + $carried,
				deleted   => $lost,
				why       => $rh_why,
			},
		};
	}
	if ($r{report}) {
		my @assumed = map { $marker[$_]{name} } grep { $as_ref[$_] } map { $panel->{abo}{$_} } @abo_role;
		my $ref_sites = grep { $as_ref[$_] } @sites;
		push @assumed, "$ref_sites of the " . scalar(@sites) . ' RHD sites' if $ref_sites;
		print STDOUT _blood_report($vcf, \%r, $panel, \%out, $names, \@assumed) or croak "$sub: can't print the report: $!";
	}
	my %chroms = map { $_->{"$r{build}_chrom"} => 1 } @marker;
	carp "$sub: \"vcf\" $vcf has no record on chromosome " . join(' or ', sort { $a <=> $b } keys %chroms)
		. ", matched by position on $r{build}, so no blood type can be told; check that it is the build the file is on"
		unless grep { $read & (1 << $_) } keys %chroms;
	\%out;
}

# ---- PDB structures
#
# pdb_search asks two RCSB APIs, as their documentation at
# https://search.rcsb.org/ and https://data.rcsb.org/ described them on
# 2026-10-21: the search API finds the polymer entities whose sequence
# matches, by MMseqs2, and the data API's GraphQL says what each one's
# structure is.

my $Rcsb_search = 'https://search.rcsb.org/rcsbsearch/v2/query';
my $Rcsb_data   = 'https://data.rcsb.org/graphql';
# The search API's own limit on "rows", which it refuses past with "numeric
# instance is greater than the required maximum (maximum: 10000" (2026-10-21).
my $Rcsb_rows = 10000;
# How many entities each GraphQL request asks about. 500 came back in one
# request in 2.45 s, 1.6 MB of JSON, on 2026-10-21, so 200 leaves headroom
# for entities with more annotations than those had.
my $Rcsb_batch = 200;
my $Rcsb_entities = <<'GRAPHQL';
query ($ids: [String!]!) { polymer_entities(entity_ids: $ids) {
	rcsb_id
	entity_poly { rcsb_entity_polymer_type pdbx_strand_id }
	rcsb_polymer_entity { pdbx_description }
	rcsb_entity_source_organism { scientific_name ncbi_taxonomy_id }
	rcsb_polymer_entity_container_identifiers { reference_sequence_identifiers { database_name database_accession } }
	rcsb_polymer_entity_annotation { type annotation_id name }
	entry {
		struct { title }
		rcsb_entry_info { experimental_method resolution_combined polymer_composition structure_determination_methodology }
		rcsb_accession_info { deposit_date initial_release_date }
		rcsb_ma_qa_metric_global { ma_qa_metric_global { type value } }
		assemblies { rcsb_struct_symmetry { kind oligomeric_state stoichiometry symbol } }
		nonpolymer_entities { nonpolymer_comp { chem_comp { id name } } }
	}
} }
GRAPHQL

# $body POSTed to $url as JSON, for $sub, and the JSON it answers with,
# decoded; undef when it answers 204, which is how the search API says that
# nothing matched. A failure dies with RCSB's own "message" where it sent one.
# The tests replace this sub, so that they run with no network.
sub _rcsb_post {
	my ($sub, $url, $body, $timeout) = @_;
	require HTTP::Tiny;
	require JSON::MaybeXS;
	# verify_SSL is given, since it is the default only from HTTP::Tiny 0.083
	my $http = HTTP::Tiny->new(agent => "Cn-Bioinf/$VERSION ", timeout => $timeout, verify_SSL => 1);
	my ($ssl, $why) = $http->can_ssl;
	unless ($ssl) {
		$why =~ s/\s+\z//;
		croak "$sub: can't reach RCSB, which needs HTTPS: $why";
	}
	my $res = $http->post($url, {
		headers => { 'Content-Type' => 'application/json', Accept => 'application/json' },
		content => JSON::MaybeXS::encode_json($body),
	});
	return undef if $res->{status} == 204;
	my $json = eval { JSON::MaybeXS::decode_json($res->{content}) };
	unless ($res->{success}) {
		# 599 is HTTP::Tiny's own status, for a request that got no answer at
		# all, and its content says why
		my $msg = $res->{status} == 599 ? $res->{content}
			: ref $json eq 'HASH' && defined $json->{message} ? $json->{message} : $res->{reason};
		$msg =~ s/\s+\z//;
		croak "$sub: $url answered $res->{status}: $msg";
	}
	croak "$sub: $url answered with something that isn't JSON: " . substr($res->{content}, 0, 200) unless ref $json;
	$json;
}

# The alignment of one search hit, from the "match_context" RCSB gave it,
# under the names get_best_alignment_hit gives a BLAST hsp. RCSB's
# sequence_identity is truncated to 3 places, so the identity is counted from
# the aligned sequences instead, which is how BLAST counts it.
sub _pdb_alignment {
	my ($m) = @_;
	my ($q, $h) = map { $_ // '' } @{ $m }{qw(query_aligned_seq subject_aligned_seq)};
	my ($identity, $gaps) = (0, 0);
	foreach my $i (0 .. length($q) - 1) {
		my ($x, $y) = (substr($q, $i, 1), substr($h, $i, 1));
		if ($x eq '-' || $y eq '-') { $gaps++ } elsif ($x eq $y) { $identity++ }
	}
	return {
		evalue      => $m->{evalue},
		bit_score   => $m->{bitscore},
		align_len   => $m->{alignment_length},
		identity    => $identity,
		# undef where RCSB gives no length to divide by, rather than dying of it
		pident      => ($m->{alignment_length} // 0) > 0 ? 100 * $identity / $m->{alignment_length} : undef,
		mismatches  => $m->{mismatches},
		gaps        => $gaps,
		gap_opens   => $m->{gaps_opened},
		query_from  => $m->{query_beg},
		query_to    => $m->{query_end},
		query_len   => $m->{query_length},
		query_cover => defined $m->{query_beg} && defined $m->{query_end} && ($m->{query_length} // 0) > 0
			? 100 * ($m->{query_end} - $m->{query_beg} + 1) / $m->{query_length} : undef,
		hit_from    => $m->{subject_beg},
		hit_to      => $m->{subject_end},
		hit_len     => $m->{subject_length},
		qseq        => $q,
		hseq        => $h,
	};
}

# What the data API said of one polymer entity, $e, which is undef when it
# said nothing, as the fields pdb_search returns: every key is there either
# way, undef or an empty array when RCSB has no value.
sub _pdb_structure {
	my ($e) = @_;
	$e //= {};
	my $entry = $e->{entry} // {};
	my $info = $entry->{rcsb_entry_info} // {};
	my $dates = $entry->{rcsb_accession_info} // {};
	# The global symmetry of the first assembly, which is the one the
	# depositors gave first, and the one RCSB's own page shows.
	my ($sym) = grep { ($_->{kind} // '') eq 'Global Symmetry' }
		map { @{ $_->{rcsb_struct_symmetry} // [] } } grep { ref $_ eq 'HASH' } @{ $entry->{assemblies} // [] }[0];
	$sym //= {};
	my ($plddt) = map { $_->{value} } grep { ($_->{type} // '') eq 'pLDDT' }
		map { @{ $_->{ma_qa_metric_global} // [] } } @{ $entry->{rcsb_ma_qa_metric_global} // [] };
	my @annotation = @{ $e->{rcsb_polymer_entity_annotation} // [] };
	my (%seen, @ligands);
	foreach my $c (map { $_->{nonpolymer_comp}{chem_comp} // () } @{ $entry->{nonpolymer_entities} // [] }) {
		push @ligands, { id => $c->{id}, name => $c->{name} } unless $seen{ $c->{id} }++;
	}
	my $chains = ($e->{entity_poly} // {})->{pdbx_strand_id};
	return {
		title               => ($entry->{struct} // {})->{title},
		description         => ($e->{rcsb_polymer_entity} // {})->{pdbx_description},
		method              => $info->{experimental_method},
		methodology         => $info->{structure_determination_methodology},
		resolution          => ($info->{resolution_combined} // [])->[0],
		plddt               => $plddt,
		polymer_type        => ($e->{entity_poly} // {})->{rcsb_entity_polymer_type},
		polymer_composition => $info->{polymer_composition},
		oligomeric_state    => $sym->{oligomeric_state},
		stoichiometry       => $sym->{stoichiometry} ? join('', @{ $sym->{stoichiometry} }) : undef,
		symmetry            => $sym->{symbol},
		chains              => [defined $chains ? split(/,/, $chains) : ()],
		organisms           => [map { +{ name => $_->{scientific_name}, taxonomy_id => $_->{ncbi_taxonomy_id} } } @{ $e->{rcsb_entity_source_organism} // [] }],
		uniprot             => [map { $_->{database_accession} } grep { ($_->{database_name} // '') eq 'UniProt' }
			@{ ($e->{rcsb_polymer_entity_container_identifiers} // {})->{reference_sequence_identifiers} // [] }],
		pfam                => [map { +{ id => $_->{annotation_id}, name => $_->{name} } } grep { ($_->{type} // '') eq 'Pfam' } @annotation],
		interpro            => [map { +{ id => $_->{annotation_id}, name => $_->{name} } } grep { ($_->{type} // '') eq 'InterPro' } @annotation],
		ligands             => \@ligands,
		deposited           => defined $dates->{deposit_date} ? substr($dates->{deposit_date}, 0, 10) : undef,
		released            => defined $dates->{initial_release_date} ? substr($dates->{initial_release_date}, 0, 10) : undef,
	};
}

# How a hit's structure was determined, as the report shows it: RCSB's
# experimental method, which a computed model has none of. Its values, and
# those of the methodology, are the enums of rcsb_entry_info in
# https://data.rcsb.org/rest/v1/schema/entry (checked 2026-10-21).
sub _pdb_method {
	my ($h) = @_;
	return $h->{method} if defined $h->{method};
	($h->{methodology} // '') eq 'computational' ? 'model' : '-';
}

# $text, a number as perl wrote it, with an exponent of two digits where two
# are enough, as C99's printf writes one. The C runtime under Strawberry Perl
# 5.24.4 writes three, so pdb_search's report read "1.6e-089" there (CPAN
# Testers report 620bc624-ddea-11f1-b231-87fe50e89311, 2026-11-11) and
# "1.6e-89" everywhere else, and admixture's warning gave its default tolerance
# as "1e-010" there in 0.03-TRIAL (report 363318e0-e362-11f1-808f-855b4a25bcf6,
# 2026-11-18). An exponent that needs three digits keeps them.
sub _two_digit_exponent {
	my ($text) = @_;
	$text =~ s/([eE][-+])0(\d\d)\z/$1$2/;
	$text;
}

# pdb_search's report on @$hits, $total of which RCSB found: one line a hit,
# best first.
sub _pdb_report {
	my ($r, $hits, $total) = @_;
	my $text = "pdb_search: " . ($total == 0 ? 'no hits' : scalar(@{ $hits }) . " of $total hit" . ($total > 1 ? 's' : ''))
		. " in RCSB's " . ($r->{computed} ? 'PDB and computed models' : 'PDB')
		. " for a $r->{len}-residue $r->{type} sequence, at an E-value below " . _two_digit_exponent("$r->{evalue}")
		. ($r->{identity} > 0 ? " and $r->{identity}% identity or more" : '') . "\n";
	return $text unless @{ $hits };
	my @head = ('id', 'method', 'resolution', 'identity', 'cover', 'evalue', 'bits', 'oligomer', 'description');
	my @rows = map {
		[$_->{id}, _pdb_method($_),
			defined $_->{resolution} ? sprintf('%.2f A', $_->{resolution}) : defined $_->{plddt} ? "pLDDT $_->{plddt}" : '-',
			defined $_->{pident} ? sprintf('%.1f%%', $_->{pident}) : '-', defined $_->{query_cover} ? sprintf('%.0f%%', $_->{query_cover}) : '-',
			_two_digit_exponent(sprintf('%.2g', $_->{evalue})), $_->{bit_score},
			$_->{oligomeric_state} // '-', $_->{description} // '-']
	} @{ $hits };
	my @w = map { length $head[$_] } 0 .. $#head;
	foreach my $row (@rows) {
		foreach my $i (0 .. $#head) {
			$w[$i] = length $row->[$i] if length $row->[$i] > $w[$i];
		}
	}
	# left-aligned text, right-aligned numbers; the last column is not padded
	my %left = map { $_ => 1 } 0, 1, 7, 8;
	my $line = sub { join('  ', map { $_ == $#head ? $_[$_] : $left{$_} ? sprintf('%-*s', $w[$_], $_[$_]) : sprintf('%*s', $w[$_], $_[$_]) } 0 .. $#head) . "\n" };
	$text . $line->(@head) . join('', map { $line->(@{ $_ }) } @rows);
}

sub pdb_search {
	my $sub = 'pdb_search';
	my $args = _args(\@_, $sub, [qw(seq)], [qw(computed evalue identity max_hits report timeout type)]);
	my %r;
	# The cutoffs are made numbers with 0 +, since JSON::XS writes a string as
	# a string, and RCSB refuses a string where its schema wants a number.
	$r{evalue} = $args->{evalue} // 0.1; # hits at this E-value or above are left out; BLAST's default of 10 would let in hits expected 10 times by chance
	croak "$sub: \"evalue\" must be a number above 0, not " . _what($r{evalue})
		unless !ref $r{evalue} && $r{evalue} =~ $Number && $r{evalue} > 0;
	$r{evalue} = 0 + $r{evalue};
	$r{identity} = $args->{identity} // 0; # percent; hits with less identity than this are left out
	croak "$sub: \"identity\" must be a percentage, from 0 to 100, not " . _what($r{identity})
		unless !ref $r{identity} && $r{identity} =~ $Number && $r{identity} >= 0 && $r{identity} <= 100;
	$r{identity} = 0 + $r{identity};
	$r{max_hits} = $args->{max_hits} // 100; # the most hits returned, best first
	croak "$sub: \"max_hits\" must be a whole number from 1 to $Rcsb_rows, RCSB's limit, not " . _what($r{max_hits})
		unless !ref $r{max_hits} && $r{max_hits} =~ /\A[0-9]+\z/ && $r{max_hits} >= 1 && $r{max_hits} <= $Rcsb_rows;
	$r{max_hits} = 0 + $r{max_hits};
	$r{computed} = $args->{computed} // 0; # 0 = experimental structures only; 1 = also computed models (AlphaFold DB, ModelArchive)
	croak "$sub: \"computed\" must be 0 or 1, not " . _what($r{computed}) unless !ref $r{computed} && ($r{computed} eq '0' || $r{computed} eq '1');
	$r{type} = $args->{type} // 'protein'; # protein, dna or rna: which of RCSB's sequence databases to search
	croak "$sub: \"type\" must be protein, dna or rna, not " . _what($r{type}) unless !ref $r{type} && $r{type} =~ /\A(?:protein|dna|rna)\z/;
	$r{report} = $args->{report} // 1; # 1 = print a table of the hits to STDOUT; 0 = only return them
	croak "$sub: \"report\" must be 0 or 1, not " . _what($r{report}) unless !ref $r{report} && ($r{report} eq '0' || $r{report} eq '1');
	$r{timeout} = $args->{timeout} // 60; # seconds for each request, HTTP::Tiny's own default
	croak "$sub: \"timeout\" must be a number of seconds above 0, not " . _what($r{timeout})
		unless !ref $r{timeout} && $r{timeout} =~ $Number && $r{timeout} > 0;

	my $seq = $args->{seq};
	croak "$sub: \"seq\" must be a sequence, as a string, not " . _what($seq) if ref $seq;
	# A sequence copied out of a FASTA file keeps its line breaks, and one
	# translated from DNA can end in a stop; RCSB refuses both, and lower case.
	$seq =~ s/\s+//g;
	$seq = uc $seq;
	$seq =~ s/\*\z//;
	croak "$sub: \"seq\" has no residues" unless length $seq;
	croak "$sub: \"seq\" has \"$1\" at residue " . ($-[0] + 1) . ', which isn\'t a residue letter' if $seq =~ /([^A-Z])/;
	$r{len} = length $seq;

	my $found = _rcsb_post($sub, $Rcsb_search, {
		query => { type => 'terminal', service => 'sequence', parameters => {
			evalue_cutoff => $r{evalue}, identity_cutoff => $r{identity} / 100, sequence_type => $r{type}, value => $seq,
		} },
		request_options => {
			results_verbosity    => 'verbose', # which gives each hit's alignment
			results_content_type => [$r{computed} ? ('experimental', 'computational') : 'experimental'],
			scoring_strategy     => 'sequence',
			paginate             => { start => 0, rows => $r{max_hits} },
		},
		return_type => 'polymer_entity',
	}, $r{timeout});
	if ($found) {
		my $not = "$sub: $Rcsb_search answered with JSON that isn't a search result: ";
		croak $not . 'it is not an object' unless ref $found eq 'HASH';
		croak $not . 'it has no result_set array' unless ref $found->{result_set} eq 'ARRAY';
		croak $not . 'it has no total_count' unless defined $found->{total_count} && !ref $found->{total_count};
		ref $_ eq 'HASH' && defined $_->{identifier} or croak $not . 'a hit in its result_set has no identifier' foreach @{ $found->{result_set} };
	}
	my $total = $found ? $found->{total_count} : 0;
	my @hits;
	foreach my $res (@{ $found ? $found->{result_set} : [] }) {
		my $best; # undef until a match is seen
		foreach my $m (map { @{ $_->{match_context} // [] } } map { @{ $_->{nodes} // [] } } @{ $res->{services} // [] }) {
			# none of the 1382 hits for human haemoglobin alpha had more than
			# one match on 2026-10-21, but the format allows it
			$best = $m if !defined $best || $m->{bitscore} > $best->{bitscore};
		}
		croak "$sub: RCSB gave no alignment for $res->{identifier}" unless defined $best;
		# An identifier is entry_entity: 1BZ1_1, or AF_AFP69905F1_1 for a computed model
		my ($entry, $entity) = $res->{identifier} =~ /\A(.+)_([^_]+)\z/
			or croak "$sub: RCSB returned \"$res->{identifier}\", which isn't an entry_entity identifier";
		push @hits, { id => $res->{identifier}, entry => $entry, entity => $entity,
			url => "https://www.rcsb.org/structure/$entry", %{ _pdb_alignment($best) } };
	}

	my %entity;
	for (my $i = 0; $i < @hits; $i += $Rcsb_batch) {
		my @ids = map { $_->{id} } @hits[$i .. ($i + $Rcsb_batch > @hits ? $#hits : $i + $Rcsb_batch - 1)];
		my $data = _rcsb_post($sub, $Rcsb_data, { query => $Rcsb_entities, variables => { ids => \@ids } }, $r{timeout});
		my $list = ref $data eq 'HASH' && ref $data->{data} eq 'HASH' ? $data->{data}{polymer_entities} : undef;
		unless (ref $list eq 'ARRAY') {
			my @why = map { $_->{message} // () } @{ ref $data eq 'HASH' && ref $data->{errors} eq 'ARRAY' ? $data->{errors} : [] };
			croak "$sub: $Rcsb_data said nothing of $ids[0]" . (@ids > 1 ? ' and the rest' : '') . (@why ? ': ' . join('; ', @why) : '');
		}
		$entity{ $_->{rcsb_id} } = $_ foreach grep { ref $_ eq 'HASH' } @{ $list };
	}
	foreach my $h (@hits) {
		# the search index can be ahead of the data API for a new release
		carp "$sub: $Rcsb_data had nothing on $h->{id}, so its structure fields are empty" unless $entity{ $h->{id} };
		%{ $h } = (%{ $h }, %{ _pdb_structure($entity{ $h->{id} }) });
	}
	# Best first, as get_best_alignment_hit sorts on "evalue": RCSB rounds a
	# strong E-value to 0, so the bit score breaks ties, and then RCSB's order.
	my @order = sort { $hits[$a]{evalue} <=> $hits[$b]{evalue} || $hits[$b]{bit_score} <=> $hits[$a]{bit_score} || $a <=> $b } 0 .. $#hits;
	@hits = @hits[@order];
	if ($r{report}) {
		my $text = _pdb_report(\%r, \@hits, $total);
		# RCSB's text is characters, and can hold some above 255 (a Greek
		# letter in a title), which print would warn of as a "Wide character",
		# fatally in a caller under FATAL warnings, unless STDOUT encodes.
		utf8::encode($text) unless grep { /\A(?:utf8|encoding)/ } PerlIO::get_layers(*STDOUT);
		print STDOUT $text or croak "$sub: can't print the report: $!";
	}
	wantarray ? (\@hits, $total) : \@hits;
}

# ---- alignment plots and tables

# Dies unless $n, given to $sub as $what, is a 1-based residue number. Without
# this, 0 and the negative numbers index @col from its end in plot_msa and
# view_alignment, and silently mean the last residues.
sub _residue_number {
	my ($sub, $what, $n) = @_;
	croak "$sub: $what must be a residue number, 1 or more, not " . (defined $n ? "\"$n\"" : 'undef')
		unless defined $n && $n =~ /\A[1-9][0-9]*\z/;
}

# "fasta" -- a FASTA file name or a hash ref of name => sequence -- written to a
# temporary FASTA file with its gaps stripped, so that an input that is already
# aligned is aligned afresh. clustalo's --dealign does the same, but prints a
# "FORCED DEBUG" warning about them first; blastp would take a gap for a residue.
# Returns that file and the sequence names in input order (sorted for a hash).
# With $numbered, each sequence is written under its number in that order, "s1",
# "s2" and so on, rather than its name, for clustalo: it cuts a name at its
# first space in the guide tree and writes "(),:" in one unquoted, which drew 4
# sequences as 5 tips up to 2026-10-17. _unnumber_fasta and _unnumber_newick put
# the names back. Dies naming $sub, whose "fasta" it is, for a sequence that is
# not a string or that has no residues once its gaps are gone, which clustalo
# and blastp would otherwise be given.
sub _ungapped_fasta {
	my ($sub, $fasta, $numbered) = @_;
	my ($seqs, @names);
	if (ref $fasta eq 'HASH') {
		$seqs = $fasta;
		@names = sort keys %{ $seqs };
	} elsif (ref $fasta eq '') {
		my $order;
		($seqs, $order) = _fasta_ordered($fasta);
		@names = @{ $order };
	} else {
		croak "$sub: \"fasta\" must be a FASTA file name or a hash ref of name => sequence, not " . _what($fasta);
	}
	my @written = $numbered ? map { "s$_" } 1 .. @names : @names;
	my %ungapped;
	foreach my $i (0 .. $#names) {
		my $s = $seqs->{ $names[$i] };
		croak "$sub: \"fasta\" sequence \"$names[$i]\" must be a string of residues, not " . _what($s) unless defined $s && !ref $s;
		$s =~ tr/-.//d;
		croak "$sub: \"fasta\" sequence \"$names[$i]\" has no residues" if $s eq '';
		$ungapped{ $written[$i] } = $s;
	}
	(_fasta_file('_ungapped_fasta', \%ungapped, _tmp('.fa'), \@written, 80), \@names);
}

# The name that clustalo's "s<n>" in $file stands for, from @$names, the list
# _ungapped_fasta numbered.
sub _unnumber {
	my ($id, $names, $file) = @_;
	croak "_unnumber: clustalo wrote \"$id\" in $file, which isn't one of the s1 to s" . scalar(@{ $names }) . ' it was given'
		unless $id =~ /\As([1-9][0-9]*)\z/ && $1 <= @{ $names };
	$names->[$1 - 1];
}

# The alignment clustalo wrote to $file under _ungapped_fasta's numbers,
# rewritten in place under the names in @$names, as UTF-8, in clustalo's order
# and 60-column lines. Returns the aligned sequences as a hash ref keyed by
# those names as perl was given them, which a name's UTF-8 may not equal.
sub _unnumber_fasta {
	my ($file, $names) = @_;
	my ($numbered, $ids) = _fasta_ordered($file);
	my (%aln, %utf8);
	foreach my $id (@{ $ids }) {
		my $name = _unnumber($id, $names, $file);
		$aln{$name} = $utf8{ _utf8($name) } = $numbered->{$id};
	}
	_fasta_file('_unnumber_fasta', \%utf8, $file, [map { _utf8(_unnumber($_, $names, $file)) } @{ $ids }], 60);
	\%aln;
}

# The guide tree clustalo wrote to $file under _ungapped_fasta's numbers,
# rewritten in place under the names in @$names, as UTF-8. A name holding
# whitespace or any of "()[]':;," is quoted as newick quotes one: in single
# quotes, each of its own doubled.
sub _unnumber_newick {
	my ($file, $names) = @_;
	open my $fh, '<:raw', $file or croak "_unnumber_newick: can't read $file: $!";
	my $tree = do { local $/; <$fh> };
	close $fh or croak "_unnumber_newick: can't read $file: $!";
	$tree =~ s{(?<=[(,\s])(s[0-9]+)(?=\s*[:,);])}{
		my $name = _utf8(_unnumber($1, $names, $file));
		$name =~ /[\s()\[\]':;,]/ ? "'" . join("''", split /'/, $name, -1) . "'" : $name;
	}ge;
	open $fh, '>:raw', $file or croak "_unnumber_newick: can't write $file: $!";
	print {$fh} $tree;
	close $fh or croak "_unnumber_newick: can't write $file: $!";
}

# Aligns "fasta" with clustalo for $sub. The alignment goes to "msa_file" and
# the guide tree to "tree_file" when those are given, and to temporary files
# otherwise; the tree is not asked for at all unless it is kept or $want_tree.
# Returns the hash ref of files to report (the alignment always, the tree only
# when it was named), the tree's file, the sequence names in input order
# (sorted for a hash), an array ref of the clustalo command as it was run, with
# the ungapped FASTA it read as its "--in", and the aligned sequences as a hash
# ref keyed by those names; or nothing, after a warning, for fewer than 2
# sequences. clustalo is given the sequences numbered, and the alignment and
# tree it writes get their names back.
sub _align {
	my ($args, $sub, $want_tree) = @_;
	my ($in, $names) = _ungapped_fasta($sub, $args->{fasta}, 1);
	if (@{ $names } < 2) {
		carp "$sub: clustalo needs at least 2 sequences, and there " . (@{ $names } ? 'is only 1' : 'are none');
		return;
	}
	my %r = ('msa_file' => $args->{'msa_file'} // _tmp('.aln.fa'));
	my $tree = $args->{'tree_file'} // ($want_tree ? _tmp('.newick') : undef);
	$r{'tree_file'} = $tree if defined $args->{'tree_file'};
	my @cmd = (_alien($sub)->clustalo, '--in', $in, '--out', $r{'msa_file'}, '--outfmt=fa', '--force',
		'--threads', $args->{threads} // 1, (defined $tree ? "--guidetree-out=$tree" : ()), @{ $args->{'clustal_args'} // [] });
	_run(@cmd);
	my $aln = _unnumber_fasta($r{'msa_file'}, $names);
	_unnumber_newick($tree, $names) if defined $tree;
	(\%r, $tree, $names, \@cmd, $aln);
}

sub plot_msa {
	my $sub = 'plot_msa';
	my $args = _args(\@_, $sub, [qw(fasta filename)], [qw(active_site_aa clustal_args execute fh labels msa_file order query threads title
		tooltips tree_file xlabel ylabel)]);
	_refs($sub, $args, 'ARRAY', qw(clustal_args order));
	_refs($sub, $args, 'HASH', 'labels');
	_file_names($sub, $args, qw(filename msa_file tree_file));
	_threads($sub, $args);
	my $drawing = _drawing($sub, $args);
	my $tooltips = $args->{'tooltips'} // 0; # 1 = a tooltip naming each residue, in an SVG; 0 = none
	croak "$sub: \"tooltips\" must be 0 or 1, not " . _what($tooltips) unless !ref $tooltips && ($tooltips eq '0' || $tooltips eq '1');
	croak "$sub: \"tooltips\" needs an SVG \"filename\", the only format that carries them, not \"$args->{filename}\""
		if $tooltips && $args->{filename} !~ /\.svg\z/i;
	my $sites = $args->{'active_site_aa'};
	if (defined $sites) {
		croak "$sub: \"active_site_aa\" must be a hash ref of label => residue number" unless ref $sites eq 'HASH';
		croak "$sub: needs \"query\" to place \"active_site_aa\"" unless defined $args->{query};
		_residue_number($sub, "active site $_", $sites->{$_}) foreach sort keys %{ $sites };
	}
	my ($r, undef, $names, $cmd, $aln) = _align($args, $sub, 0) or return {};
	my @order = @{ $args->{order} // $names };
	my @unknown = grep { !defined $aln->{$_} } @order;
	croak "$sub: \"order\" names sequences that aren't in the alignment: @unknown" if @unknown;
	my $labels = $args->{labels} // {};
	# Each name as msa_plot.py is to show it, in UTF-8, which is what it reads.
	# Up to 2026-10-17 the name was written as perl held it, Latin-1 or UTF-8,
	# and Python died on the Latin-1.
	my %shown_as = map { $_ => _utf8($labels->{$_} // $_) } @order;
	# Two sequences shown under one label would be one row of the image, fed
	# two deflines.
	my %by_label;
	push @{ $by_label{ $shown_as{$_} } }, $_ foreach @order;
	foreach my $label (sort keys %by_label) {
		croak "$sub: " . join(', ', map { "\"$_\"" } @{ $by_label{$label} }) . " would all be drawn as \"$label\""
			if @{ $by_label{$label} } > 1;
	}
	my @segments;
	if (defined $sites) {
		my $q = $aln->{ $args->{query} } // croak "$sub: the query \"$args->{query}\" isn't in the alignment";
		# 1-based residue number => 0-based alignment column
		my (@col, %sites);
		while ($q =~ /[^-]/g) {
			push @col, pos($q) - 1;
		}
		foreach my $label (sort keys %{ $sites }) {
			my $n = $sites->{$label};
			$sites{$label} = $col[$n - 1] // croak "$sub: active site $label ($n) is past the end of \"$args->{query}\", which has " . scalar(@col) . ' residues';
		}
		@segments = ('--s', _json_text({ map { _chars($_) => 0 + $sites{$_} } keys %sites }));
	}
	my %shown = map { $shown_as{$_} => $aln->{$_} } @order;
	my $fa = _fasta_file($sub, \%shown, _tmp('.fa'), [@shown_as{@order}], 0);
	$r->{'python_file'} = _draw($sub, $drawing, '--f', $fa, '--o', $args->{filename}, '--c', _creator($sub), '--quiet',
		'--p', _json_text([map { _chars($_) } _align_provenance($args, $sub, $cmd, $names, $r->{'msa_file'}), _kept($args, qw(msa_file tree_file))]),
		(defined $args->{title} ? ('--t', $args->{title}) : ()),
		(defined $args->{xlabel} ? ('--x', $args->{xlabel}) : ()),
		(defined $args->{ylabel} ? ('--y', $args->{ylabel}) : ()), @segments,
		# the tooltips name each sequence as perl was given it, not by its label, which may be mathtext
		($tooltips ? ('--tips', _json_text([map { _chars($_) } @order])) : ()));
	_wrote($args->{filename}, 43, $drawing->{execute} ? 'wrote' : 'will write'); # yellow
	$r->{filename} = $args->{filename};
	$r;
}

# "path (SHA-256 hex)" of an existing file, for the provenance of an image.
sub _file_id {
	my ($file) = @_;
	require Digest::SHA;
	require File::Spec;
	File::Spec->rel2abs($file) . ' (SHA-256 ' . Digest::SHA->new(256)->addfile($file, 'b')->hexdigest . ')';
}

# "fasta" as an image's Creator names it: a file by its path and digest, a hash
# ref by its size, since its contents were never on disk until
# _ungapped_fasta wrote them.
sub _fasta_id {
	my ($fasta, $n) = @_;
	ref $fasta ? "a hash ref of $n sequences" : 'the FASTA file ' . _file_id($fasta) . " of $n sequences";
}

# The files named in @keys of $args that were written and kept beside an
# image, as a clause of its Creator, or nothing when none was.
sub _kept {
	my ($args, @keys) = @_;
	require File::Spec;
	my @kept = map { defined $args->{$_} && !ref $args->{$_} ? "$_ " . File::Spec->rel2abs($args->{$_}) : () } @keys;
	@kept ? 'kept with it: ' . join(', ', @kept) : ();
}

# A command as it could be pasted into a POSIX shell, for an image's Creator:
# an argument that holds anything but the characters listed, or nothing at all,
# goes between apostrophes, and an apostrophe inside it is written '\''.
sub _cmd_text {
	join ' ', map {
		(my $s = $_) =~ s/'/'\\''/g;
		$s eq '' || $s =~ /[^\w\/.,:=+-]/ ? "'$s'" : $s;
	} @_;
}

# How _align made an alignment, as one clause of an image's Creator: what
# Clustal Omega read, which version ran, what it wrote and the command. $cmd,
# $names and $msa are what _align returned.
sub _align_provenance {
	my ($args, $sub, $cmd, $names, $msa) = @_;
	my $alien = _alien($sub);
	# $cmd->[2] is clustalo's "--in", the ungapped copy _ungapped_fasta wrote
	'from ' . _fasta_id($args->{fasta}, scalar @{ $names }) . ', written with its gaps stripped and the sequences numbered s1 to s'
		. scalar(@{ $names }) . ' to ' . _file_id($cmd->[2]) . ', which Clustal Omega ' . $alien->versions->{clustalo}
		. " from Alien::Bioinf $Alien::Bioinf::VERSION aligned into " . _file_id($msa) . ' (with the names put back), run as: '
		. _cmd_text(@{ $cmd });
}

sub plot_phylo {
	my $sub = 'plot_phylo';
	my $args = _args(\@_, $sub, [], [qw(clustal_args execute fasta fh labels msa_file output_file threads title tree_file)]);
	_refs($sub, $args, 'ARRAY', 'clustal_args');
	_refs($sub, $args, 'HASH', 'labels');
	_file_names($sub, $args, qw(msa_file output_file tree_file));
	_threads($sub, $args);
	my $drawing = _drawing($sub, $args);
	$args->{output_file} //= 'phylo.svg';
	my ($r, $tree, $names, $cmd);
	if (defined $args->{fasta}) {
		($r, $tree, $names, $cmd) = _align($args, $sub, 1) or return {};
	} else {
		# no alignment to make, so "tree_file" is the tree to draw, not where to keep one
		$tree = $args->{'tree_file'} // croak "$sub: needs \"fasta\" to align, or \"tree_file\" to draw";
		my @moot = grep { defined $args->{$_} } qw(clustal_args msa_file threads);
		croak "$sub: was given " . join(', ', map { "\"$_\"" } @moot) . ' but no "fasta" to align' if @moot;
		croak "$sub: \"$tree\" doesn't exist or isn't a readable file" unless -f $tree && -r _;
		$r = { 'tree_file' => $tree };
	}
	my $labels = $args->{labels} // {};
	my @prov = defined $cmd
		? (_align_provenance($args, $sub, $cmd, $names, $r->{'msa_file'}), 'drawing the guide tree it wrote, ' . _file_id($tree),
			_kept($args, qw(msa_file tree_file)))
		: ('from the newick file ' . _file_id($tree));
	# the tips are named in UTF-8 by _unnumber_newick, which msa_plot.py decodes
	$r->{'python_file'} = _draw($sub, $drawing, '--tree', $tree, '--o', $args->{'output_file'}, '--c', _creator($sub), '--quiet',
		'--p', _json_text([map { _chars($_) } @prov]),
		(defined $args->{title} ? ('--t', $args->{title}) : ()),
		(%{ $labels } ? ('--l', _json_text({ map { _chars($_) => _chars($labels->{$_}) } keys %{ $labels } })) : ()));
	$r->{'output_file'} = $args->{'output_file'};
	_wrote($args->{output_file}, 43, $drawing->{execute} ? 'wrote' : 'will write'); # yellow
	$r;
}

sub msa_quality_table {
	my $sub = 'msa_quality_table';
	my $args = _args(\@_, $sub, ['filename'], [qw(alignment_json cb_label cb_max cb_min cblogscale default_undefined fasta
		logscale_add metric msa_file normalize order show_numbers title unaligned_fa)]);
	_refs($sub, $args, 'ARRAY', 'order');
	_file_names($sub, $args, qw(filename msa_file));
	# Each is added to, divided by or compared with a score. Up to 2026-11-10
	# one that was not a number only warned "isn't numeric", and was drawn as 0.
	foreach my $k (qw(cb_max cb_min default_undefined logscale_add normalize)) {
		croak "$sub: \"$k\" must be a number, not " . _what($args->{$k})
			if defined $args->{$k} && (ref $args->{$k} || $args->{$k} !~ $Number);
	}
	my %metric = map { $_ => 1 } qw(num bit_score score evalue identity positive align_len);
	my $metric = $args->{metric} // 'score';
	croak "$sub: \"$metric\" isn't one of the metrics: " . join(', ', sort keys %metric) unless $metric{$metric};
	# "unaligned_fa" is the old name for "fasta"
	croak "$sub: was given both \"fasta\" and \"unaligned_fa\", which are the same thing" if defined $args->{fasta} && defined $args->{'unaligned_fa'};
	my $fasta = $args->{fasta} // $args->{'unaligned_fa'};
	# All-against-all blastp of the sequences: given as the parsed report, read
	# from "alignment_json", or -- when that file does not exist yet, or none is
	# named -- made by running blastp on "fasta", and kept in "alignment_json"
	# for next time if that is named.
	my $aj = $args->{'alignment_json'};
	croak "$sub: \"alignment_json\" must be a file name or a hash ref, not " . _what($aj) if ref $aj && ref $aj ne 'HASH';
	my ($blast, $prov);
	if (ref $aj eq 'HASH') {
		$blast = $aj;
		$prov = 'from a BLAST report given as a hash ref';
	} elsif (defined $aj && -f $aj) {
		$blast = _json_file($sub, $aj);
		$prov = 'from the BLAST report ' . _file_id($aj);
	} else {
		croak "$sub: needs \"fasta\" to align, or an existing \"alignment_json\"" . (defined $aj ? " ($aj doesn't exist yet)" : '')
			unless defined $fasta;
		my ($in, $names) = _ungapped_fasta($sub, $fasta);
		$aj //= _tmp('.json');
		my $alien = _alien($sub);
		my @cmd = ($alien->blast('blastp'), '-query', $in, '-subject', $in, '-out', $aj, '-outfmt', 15);
		_run(@cmd);
		$blast = _json_file($sub, $aj);
		$prov = 'from ' . _fasta_id($fasta, scalar @{ $names }) . ', written with its gaps stripped to ' . _file_id($in)
			. ', which blastp ' . $alien->versions->{blast} . " from Alien::Bioinf $Alien::Bioinf::VERSION compared all against all into "
			. _file_id($aj) . ', run as: ' . _cmd_text(@cmd);
		$prov = join '; ', $prov, _kept($args, 'alignment_json');
	}
	croak "$sub: \"alignment_json\" isn't a BLAST report in JSON (-outfmt 15): it has no \"BlastOutput2\" array"
		unless ref $blast eq 'HASH' && ref $blast->{BlastOutput2} eq 'ARRAY';
	# The report's shape is checked as it is read. Up to 2026-11-10 a report
	# that was not an object, or "hits" that was not an array, died with perl's
	# "Can't use string as a HASH ref" or "Not an ARRAY reference", naming no
	# function. A report with no bl2seq, as a search of a database has, holds no
	# pair, and is left for the message below.
	my (%data, $max);
	my %known; # every query the report names, whether or not it has a hit
	foreach my $i (0 .. $#{ $blast->{BlastOutput2} }) {
		my $query = $blast->{BlastOutput2}[$i];
		my $where = 'report ' . ($i + 1) . ' of "alignment_json"';
		my $results = ref $query eq 'HASH' && ref $query->{report} eq 'HASH' ? $query->{report}{results} : undef;
		croak "$sub: $where has no report.results" unless ref $results eq 'HASH';
		my $lists = $results->{bl2seq} // [];
		croak "$sub: $where has a \"bl2seq\" that isn't an array, but " . _what($lists) unless ref $lists eq 'ARRAY';
		foreach my $hit_list (@{ $lists }) {
			croak "$sub: $where has a comparison that isn't one, which is an object with a \"query_title\" and a \"hits\" array"
				unless ref $hit_list eq 'HASH' && defined $hit_list->{query_title} && !ref $hit_list->{query_title}
					&& ref($hit_list->{hits} // []) eq 'ARRAY';
			$known{ $hit_list->{query_title} } = 1;
			foreach my $hit (@{ $hit_list->{hits} // [] }) {
				croak "$sub: $where has a hit of \"$hit_list->{query_title}\" that isn't one, which is an object whose \"description\" and \"hsps\" are arrays of objects"
					unless ref $hit eq 'HASH' && ref($hit->{description} // []) eq 'ARRAY' && ref($hit->{hsps} // []) eq 'ARRAY'
						&& !grep { ref $_ ne 'HASH' } @{ $hit->{description} // [] }, @{ $hit->{hsps} // [] };
				my ($first, $hsp) = (($hit->{description} // [])->[0], ($hit->{hsps} // [])->[0]);
				next unless defined $first && defined $first->{title} && defined $hsp;
				my $value = $hsp->{$metric} // next;
				$data{ $hit_list->{query_title} }{ $first->{title} } = $value;
				$max = $value if !defined $max || $value > $max;
			}
		}
	}
	croak "$sub: no \"$metric\" values in the BLAST report" unless defined $max;
	# Up to 2026-11-10 a name in "order" that the report lacks, a misspelt one
	# say, was drawn as a row and a column of grey cells, as a sequence that
	# has no hit is.
	my @unknown = grep { !$known{$_} } @{ $args->{order} // [] };
	croak "$sub: \"order\" names sequences that aren't in the BLAST report: @unknown" if @unknown;
	my @order = @{ $args->{order} // [sort { lc $a cmp lc $b } keys %data] };
	my (@row_labels, @names);
	foreach my $key (@order) {
		my ($genus, $species) = $key =~ /^([^.]+)\.(.+)/ or croak "$sub: can't get a genus and species from \"$key\"";
		my ($sp, @strain) = split /\./, $species; # C.neoformans.B.3501A
		push @names, [$genus, $sp, "@strain"];
		push @row_labels, '$\it{' . ucfirst(_first_letter($genus)) . ". $sp}\$" . (@strain ? " @strain" : '');
	}
	my @col_labels = @{ _abbreviated_labels(\@names) };
	my $add = $args->{'logscale_add'} // 0;
	my $norm = ($args->{normalize} // 0) > 0;
	# Normalized, every value is divided by the largest, with "logscale_add"
	# added to both so that the largest is still 1. That needs a largest above
	# 0, which "evalue" does not have when BLAST has rounded every e-value to 0.
	croak "$sub: can't normalize \"$metric\", since its largest value" . ($add ? ' plus "logscale_add"' : '') . ' is ' . ($max + $add) . ', not above 0'
		if $norm && $max + $add <= 0;
	my $log = $args->{cblogscale};
	my (@cells, $lo, $hi, $lo_positive);
	foreach my $i (0 .. $#order) {
		foreach my $j (0 .. $#order) {
			# a pair with no hit stays out of the table, rather than claiming a
			# score of 0, and is drawn grey
			my $value = $data{ $order[$i] }{ $order[$j] } // $args->{default_undefined};
			if (defined $value) {
				$value += $add;
				$value /= $max + $add if $norm;
				$lo = $value if !defined $lo || $value < $lo;
				$hi = $value if !defined $hi || $value > $hi;
				$lo_positive = $value if $value > 0 && (!defined $lo_positive || $value < $lo_positive);
			}
			$cells[$i][$j] = $value;
		}
	}
	croak "$sub: no pair of the sequences in \"order\" has a \"$metric\" value, or a \"default_undefined\", to draw" unless defined $hi;
	# A normalized scale runs from 0 to 1, but a log scale can't start at 0 or
	# below, so it starts at the smallest value above 0 instead, as it does
	# when not normalized.
	@{ $args }{qw(cb_min cb_max)} = ($log ? undef : 0, 1) if $norm;
	$lo = $args->{cb_min} // ($log ? $lo_positive : $lo);
	$hi = $args->{cb_max} // $hi;
	croak "$sub: \"cblogscale\" needs a value above 0 to start the scale at, or a \"cb_min\" above 0" if $log && (!defined $lo || $lo <= 0);
	require JSON::MaybeXS;
	my $table = _tmp('.json');
	open my $fh, '>:raw', $table or croak "$sub: can't write $table: $!";
	# The strings go through _chars, since encode_json reads a byte string as
	# Latin-1: up to 2026-10-17 a UTF-8 title "caf\xc3\xa9" was drawn as
	# "caf\xc3\x83\xc2\xa9".
	print {$fh} JSON::MaybeXS::encode_json({
		cells => \@cells, cols => [map { _chars($_) } @col_labels], rows => [map { _chars($_) } @row_labels], vmin => $lo + 0, vmax => $hi + 0,
		log => $log ? JSON::MaybeXS::true() : JSON::MaybeXS::false(),
		numbers => $args->{'show_numbers'} ? JSON::MaybeXS::true() : JSON::MaybeXS::false(),
		title => _chars($args->{title} // ''), cblabel => (defined $args->{cb_label} ? _chars($args->{cb_label}) : undef),
	});
	close $fh or croak "$sub: can't write $table: $!";
	_python($sub, '--table', $table, '--o', $args->{filename}, '--c', _creator($sub), '--p', _json_text([map { _chars($_) } "showing each pair's \"$metric\"", $prov]));
	$args->{filename};
}

# $text with every character that LaTeX treats specially written so that it
# prints as itself. "\^" would be a circumflex accent, not a caret, and "\~" a
# tilde accent, so those two (and the backslash) are spelled as text commands.
sub _latex_text {
	my ($text) = @_;
	# |, < and > are commands, as the others are, because under the default
	# OT1 fonts they print as an em dash and an inverted ! and ?
	my %special = ('\\' => '\\textbackslash{}', '^' => '\\textasciicircum{}', '~' => '\\textasciitilde{}',
		'|' => '\\textbar{}', '<' => '\\textless{}', '>' => '\\textgreater{}');
	$text =~ s/([\\^~#\$%&_{}|<>])/$special{$1} \/\/ "\\$1"/ge;
	$text;
}

# xcolor's 19 base colors as [r, g, b], each 0 to 1, for the terminal and the
# SVG, which have no xcolor to look a name up in. Taken from xcolor.sty v3.01
# (2023/11/15, TeX Live's tex/latex/xcolor), its three \definecolorset lines
# for the base colors (lines 1435 to 1456): red to violet are given in rgb
# first, cyan to olive in cmyk and black to white in gray, and the rgb of each
# is the one written in its rgb place.
my %Xcolor = (
	red      => [1, 0, 0],     green     => [0, 1, 0],       blue  => [0, 0, 1],
	brown    => [.75, .5, .25], lime     => [.75, 1, 0],     orange => [1, .5, 0],
	pink     => [1, .75, .75], purple    => [.75, 0, .25],   teal  => [0, .5, .5],
	violet   => [.5, 0, .5],   cyan      => [0, 1, 1],       magenta => [1, 0, 1],
	yellow   => [1, 1, 0],     olive     => [.5, .5, 0],     black => [0, 0, 0],
	darkgray => [.25, .25, .25], gray    => [.5, .5, .5],    lightgray => [.75, .75, .75],
	white    => [1, 1, 1],
);

# The color view_alignment's "color" gives every residue: plot_msa's, as
# share/msa_plot.py's AA and NT tables hold them, which are CIAlign's
# color-blind-safe "CBS" palette (getAAColours('CBS') and getNtColours('CBS');
# Tumescheit, Firth & Brown, PeerJ 2022, MIT license), so that the text, the
# SVG and plot_msa's image color a residue alike. The gap and "*", which
# msa_plot.py draws white, are left out here, and so stay uncolored.
# t/checks.t reads msa_plot.py's tables and checks that these are the same.
my %Residue_color = (
	aa => {
		D => '#a22c49', E => '#a22c49', C => '#c9c433', M => '#c9c433', K => '#0038a2', R => '#0038a2',
		S => '#e57700', T => '#e57700', F => '#589aab', Y => '#589aab', N => '#50d3cb', Q => '#50d3cb',
		G => '#eae2ea', L => '#56ae6c', V => '#56ae6c', I => '#56ae6c', A => '#888988', W => '#89236a',
		H => '#e669ca', P => '#ffc4a9', X => '#000000', B => '#936e23', Z => '#936e23', J => '#936e23',
		U => '#936e23', O => '#936e23',
	},
	nt => {
		A => '#56ae6c', G => '#c9c433', T => '#a22c49', C => '#0038a2', N => '#6979d3', U => '#a22c49',
		map { $_ => '#6979d3' } split //, 'RYSWKMBDHVX',
	},
);

# %Residue_color itself, for t/checks.t to compare with msa_plot.py's tables.
sub _residue_colors { \%Residue_color }

# The palette of %Residue_color for these sequences: 'nt' when every character
# of every one, upper-cased, is a nucleotide code or a gap, as msa_plot.py
# decides it after CIAlign's seqType(), and 'aa' otherwise. A "." counts as a
# gap here, which msa_plot.py has no use for, since it reads only "-".
sub _palette_for {
	my ($seqs) = @_;
	my $nt = $Residue_color{nt};
	foreach my $s (values %{ $seqs }) {
		foreach my $c (split //, uc $s) {
			return 'aa' unless $c eq '-' || $c eq '.' || defined $nt->{$c};
		}
	}
	'nt';
}

# The text color, as 0 to 255 r, g, b, that reads best on the background $r,
# $g, $b: white or black, whichever has the higher contrast ratio against it
# by WCAG 2.2's definitions of relative luminance and contrast ratio (W3C
# Recommendation, 2023-10-05, "Glossary"): each channel taken from sRGB to
# linear, L = 0.2126 R + 0.7152 G + 0.0722 B, and the ratio of the lighter L
# + 0.05 to the darker. The two ratios are equal at L = 0.1791; of
# %Residue_color, #936e23 (L = 0.1748, white) and #6979d3 (L = 0.2138, black)
# are the nearest it (measured 2026-11-16), far enough that no NV width can
# tip them.
sub _text_on {
	my @lin = map { my $s = $_ / 255; $s <= 0.04045 ? $s / 12.92 : (($s + 0.055) / 1.055) ** 2.4 } @_;
	my $l = 0.2126 * $lin[0] + 0.7152 * $lin[1] + 0.0722 * $lin[2];
	1.05 / ($l + 0.05) > ($l + 0.05) / 0.05 ? (255, 255, 255) : (0, 0, 0);
}

# A color of "color_residues", an xcolor base name or [r, g, b], as the 0 to
# 255 integers of the terminal's and the SVG's rgb.
sub _rgb255 {
	my ($c) = @_;
	map { int(255 * $_ + 0.5) } @{ ref $c ? $c : $Xcolor{$c} };
}

# $name as the terminal and the SVG show it: a tab, carriage return or newline
# as \t, \r or \n, as Stats::LikeR's view writes them, and any other control
# character as \x{..}, so that one name stays on one line and the SVG stays
# XML, which allows none of them.
sub _shown_name {
	my ($name) = @_;
	my %esc = ("\t" => '\\t', "\r" => '\\r', "\n" => '\\n');
	$name =~ s/([\x00-\x1f\x7f])/$esc{$1} \/\/ sprintf('\\x{%02x}', ord $1)/ge;
	$name;
}

# $text as the text of an XML element: &, < and > written as entities. Quotes
# need none outside an attribute, and are left as they are, as matplotlib
# leaves them in the Creator, so that the provenance reads the same in both.
sub _xml {
	my ($text) = @_;
	my %ent = ('&' => '&amp;', '<' => '&lt;', '>' => '&gt;');
	$text =~ s/([&<>])/$ent{$1}/g;
	$text;
}

# The alignment of view_alignment as LaTeX tables, the original output of
# bioinf.pm's clustal_view_residues: each block's rows of name, residues and
# residues so far, a table of "split" blocks each.
sub _alignment_tex {
	my ($sub, $r, $blocks, $creator) = @_;
	my @table;
	foreach my $block (@{ $blocks }) {
		foreach my $row (@{ $block->{rows} }) {
			my $name = _latex_text($row->{name});
			if ($row->{track}) {
				push @table, ["\\textit{$name} track", '\texttt{' . join('', @{ $row->{chars} }) . '}', $row->{count}];
				next;
			}
			# a residue is written so that LaTeX prints it, as a name is
			my @seq = map { _latex_text($_) } @{ $row->{chars} };
			foreach my $i (0 .. $#seq) {
				if (my $bg = $row->{bg}[$i]) {
					# a box of its color, the \strut making every box in the row
					# one height, under the residue in white or black; the {} ends
					# the command's name, which would otherwise run on into "M"
					my $x = $seq[$i];
					$x = "\\textcolor{white}{$x}" if (_text_on(@{ $bg }))[0];
					$x = "\\textbf{$x}" if $row->{strong}[$i];
					$seq[$i] = '\colorbox[RGB]{' . join(',', @{ $bg }) . "}{\\strut{}$x}";
					next;
				}
				my $c = $row->{colors}[$i] // next;
				$seq[$i] = ref $c ? '{\color[rgb]{' . join(',', @{ $c }) . "}$seq[$i]}" : "\\textcolor{$c}{$seq[$i]}";
			}
			push @table, ["\\textit{$name}", '\texttt{' . join('', @seq) . '}', $row->{count}];
		}
		push @table, ['\hline'];
	}
	my $per_table = $r->{split} * (1 + @{ $blocks->[0]{rows} }); # a block's rows, and its \hline
	my $file = $r->{'output_file'};
	open my $tex, '>', $file or croak "$sub: can't write $file: $!";
	# a newline in a path would end the comment, and make the rest LaTeX
	(my $comment = $creator) =~ tr/\r\n/  /;
	print {$tex} "% $comment\n" or croak "$sub: can't write $file: $!";
	my $n_tables = int((@table + $per_table - 1) / $per_table);
	foreach my $t (0 .. $n_tables - 1) {
		my $end = ($t + 1) * $per_table - 1;
		$end = $#table if $end > $#table;
		# with "color", no margin round a residue's box, so that the boxes meet;
		# the table's group keeps the setting from the rest of the document
		print {$tex} "\\begin{table}[htp]$r->{'table_text_size'}\n", ($r->{color} ? "\\setlength{\\fboxsep}{0pt}\n" : ''),
			($r->{title} ne '' ? '\textbf{' . _latex_text($r->{title}) . '}' . ($t > 0 ? ' (continued)' : '') . "\\par\n" : ''),
			"\\begin{tabular}{|c|l|c|} \\hline\n",
			'\textbf{Track} & \textbf{Sequence} & \textbf{Length}\\\\ \hline', "\n";
		print {$tex} join(' & ', @{ $_ }), ($_->[-1] eq '\hline' ? "\n" : "\n\\\\\n") foreach @table[$t * $per_table .. $end];
		print {$tex} "\\end{tabular}\n\\caption{$r->{caption}", ($t > 0 && $r->{caption} ne '' ? ' (continued)' : ''), "}\n";
		print {$tex} "\\label{tab:$r->{label}", ($n_tables > 1 ? $t : ''), "}\n" if defined $r->{label};
		print {$tex} "\\end{table} \\FloatBarrier\n";
	}
	close $tex or croak "$sub: can't write $file: $!";
}

# The width of the name column and of the residue count column, in
# characters, which the terminal and the SVG lay their rows out by.
sub _alignment_widths {
	my ($blocks) = @_;
	my ($name_w, $count_w) = (0, 0);
	foreach my $row (map { @{ $_->{rows} } } @{ $blocks }) {
		my $w = length _chars($row->{label});
		$name_w = $w if $w > $name_w;
		$count_w = length $row->{count} if !$row->{track} && length $row->{count} > $count_w;
	}
	($name_w, $count_w);
}

# The header of a block, as the terminal shows it: its first alignment column
# over its first residue, and its last over its last when there is room for
# both with a space between.
sub _block_header {
	my ($block) = @_;
	my ($first, $last) = ($block->{start} + 1, $block->{start} + $block->{width});
	my $room = $block->{width} - length($first) - length($last);
	$first . ($room >= 1 ? ' ' x $room . $last : '');
}

# The alignment of view_alignment as text: a banner, then each block's header
# and rows of name, residues and residues so far, the banner again last, as
# Stats::LikeR's view ends with it. With $color, a residue with a background
# (view_alignment's "color") is on it, as a 24-bit ANSI background
# (48;2;r;g;b), in the text color _text_on picks (38;2;r;g;b), and also bold
# (1) and underlined (4) when it is one of "color_residues"; any other colored
# residue is in its color, as a foreground; and each is followed by a reset
# (0). Characters, not bytes.
sub _alignment_text {
	my ($blocks, $banner, $color) = @_;
	my ($name_w, $count_w) = _alignment_widths($blocks);
	my $seq_w = $blocks->[0]{width}; # the first block is the widest
	my @lines = ($banner);
	foreach my $b (0 .. $#{ $blocks }) {
		my $block = $blocks->[$b];
		push @lines, '' if $b > 0;
		push @lines, ' ' x ($name_w + 2) . _block_header($block);
		foreach my $row (@{ $block->{rows} }) {
			my $seq = '';
			foreach my $i (0 .. $#{ $row->{chars} }) {
				my $c = _chars($row->{chars}[$i]);
				my $bg = $row->{bg}[$i];
				if ($color && defined $bg) {
					$seq .= "\e[" . ($row->{strong}[$i] ? '1;4;' : '') . '38;2;' . join(';', _text_on(@{ $bg })) . ';48;2;' . join(';', @{ $bg }) . "m$c\e[0m";
				} elsif ($color && defined $row->{colors}[$i]) {
					$seq .= "\e[38;2;" . join(';', _rgb255($row->{colors}[$i])) . "m$c\e[0m";
				} else {
					$seq .= $c;
				}
			}
			my $name = _chars($row->{label});
			my $line = $name . ' ' x ($name_w - length($name) + 2) . $seq;
			$line .= ' ' x ($seq_w - @{ $row->{chars} } + 2 + $count_w - length $row->{count}) . $row->{count} unless $row->{track};
			push @lines, $line;
		}
	}
	join('', map { "$_\n" } @lines, $banner);
}

# The alignment of view_alignment as an SVG, laid out as _alignment_text lays
# it out, with its provenance $creator in the <metadata> that Matplotlib::Simple
# 0.33's svg_creator_metadata writes it in, after matplotlib 3.11.2's
# backend_svg._write_metadata: <dc:creator><cc:Agent><dc:title>, the one place
# a figure from any of its engines keeps it, and the only metadata written.
# Each residue is a <tspan> of its own, centered on its column by its own x,
# so that the columns of every row, and the backgrounds under them, line up
# whatever font the viewer has. Up to 2026-11-16 a row was one <text> whose
# textLength was fixed instead, which librsvg 2.58 (Eye of GNOME's renderer)
# ignores: it drew DejaVu Sans Mono's own 7.224 px advance, so the letters ran
# further right of their backgrounds at every column; and it reads only the
# first of a list of x on one <text>, so that is no way out either. A
# colored residue has a tooltip, an empty <rect> over it with a <title>, as
# msa_plot.py puts one on each cell. With "color", each run of residues of one
# background is one <rect> under the row, and a residue whose text is to be
# white, or which is one of "color_residues" (bold and underlined, as in the
# terminal), is a <tspan>. A $title other than '' is a bold line above the
# first block, and the image is widened to hold it if need be.
sub _alignment_svg {
	my ($sub, $file, $blocks, $creator, $title) = @_;
	# 12 px text, and 7.2 px a character: 0.6 em is the advance of DejaVu Sans
	# Mono, Liberation Mono and Courier New alike, so the names and the counts,
	# which are not stretched, end where the layout puts them in any of them.
	# 16 px a line leaves 4 px between the descenders of one row and the
	# capitals of the next; 8 px is the margin all round.
	my ($fs, $cw, $lh, $pad) = (12, 7.2, 16, 8);
	# The title is 14 px bold, 8.4 px a character by the same 0.6 em, on a
	# baseline 15 px into a band of 20 px, which leaves its descenders 1 px
	# clear of the band and the band 4 px clear of the first header's capitals.
	my ($title_fs, $title_cw, $title_h, $title_base) = (14, 8.4, 20, 15);
	$title //= '';
	my $top = $pad + ($title eq '' ? 0 : $title_h); # where the first block's line starts
	my ($name_w, $count_w) = _alignment_widths($blocks);
	# Every length is written with %.10g, so that 8 + 9 * 7.2 is written 72.8
	# and not 72.80000000000001, and a column past the millionth is still
	# placed to the hundredth of a pixel.
	my $x0 = sprintf '%.10g', $pad + ($name_w + 2) * $cw; # where the residues start
	my $x_count = $x0 + ($blocks->[0]{width} + 2 + $count_w) * $cw; # where the counts end
	my $lines = 0;
	$lines += 1 + @{ $_->{rows} } foreach @{ $blocks }; # a header and the rows of each block
	$lines += @{ $blocks } - 1; # a blank line between blocks
	my $right = $x_count; # where the widest thing drawn ends
	my $title_end = $pad + length(_chars($title)) * $title_cw;
	$right = $title_end if $title_end > $right;
	my ($width, $height) = map { sprintf '%.10g', $_ } $right + $pad, $top + $pad + $lines * $lh;
	my ($before, $after) = (
		"\n <metadata>\n"
		 . '  <rdf:RDF xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:cc="http://creativecommons.org/ns#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">' . "\n"
		 . "   <cc:Work>\n    <dc:creator>\n     <cc:Agent>\n      <dc:title>",
		"</dc:title>\n     </cc:Agent>\n    </dc:creator>\n   </cc:Work>\n  </rdf:RDF>\n </metadata>"
	);
	my $svg = qq{<?xml version="1.0" encoding="utf-8" standalone="no"?>\n}
		. qq{<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height" version="1.1">}
		. $before . _xml(_chars($creator)) . $after . "\n"
		. qq{ <rect width="100%" height="100%" fill="#ffffff"/>\n}
		. qq{ <g font-family="DejaVu Sans Mono, Liberation Mono, Courier New, monospace" font-size="$fs" fill="#000000">\n};
	$svg .= sprintf(qq{  <text x="$pad" y="%d" font-size="$title_fs" font-weight="bold">%s</text>\n}, $pad + $title_base, _xml(_chars($title)))
		if $title ne '';
	my $line = 0;
	foreach my $b (0 .. $#{ $blocks }) {
		my $block = $blocks->[$b];
		$line++ if $b > 0;
		my $y = $top + ++$line * $lh - 4; # the baseline, 4 px above the line's foot
		my ($first, $last) = ($block->{start} + 1, $block->{start} + $block->{width});
		$svg .= qq{  <text x="$x0" y="$y" fill="#666666">$first</text>\n};
		$svg .= sprintf(qq{  <text x="%.10g" y="$y" fill="#666666" text-anchor="end">$last</text>\n}, $x0 + $block->{width} * $cw)
			if $block->{width} - length($first) - length($last) >= 1;
		foreach my $row (@{ $block->{rows} }) {
			$y = $top + ++$line * $lh - 4;
			$svg .= qq{  <text x="$pad" y="$y"} . ($row->{track} ? ' fill="#666666"' : '') . '>' . _xml(_chars($row->{label})) . "</text>\n";
			# the backgrounds, drawn before the text so as to be under it
			my $n = @{ $row->{chars} };
			for (my $i = 0; $i < $n; ) {
				my $bg = $row->{bg}[$i];
				unless (defined $bg) {
					$i++;
					next;
				}
				my $key = join ',', @{ $bg };
				my $end = $i + 1; # one past the last of the run
				$end++ while $end < $n && defined $row->{bg}[$end] && join(',', @{ $row->{bg}[$end] }) eq $key;
				$svg .= sprintf(qq{  <rect x="%.10g" y="%.10g" width="%.10g" height="$lh" fill="rgb($key)"/>\n}, $x0 + $i * $cw, $y + 4 - $lh, ($end - $i) * $cw);
				$i = $end;
			}
			my (@tips, $seq);
			foreach my $i (0 .. $#{ $row->{chars} }) {
				my $c = _xml(_chars($row->{chars}[$i]));
				my $color = $row->{colors}[$i];
				my $attr = '';
				if (my $bg = $row->{bg}[$i]) {
					my @fg = _text_on(@{ $bg });
					$attr = ($fg[0] ? ' fill="rgb(255,255,255)"' : '') . ($row->{strong}[$i] ? ' font-weight="bold" text-decoration="underline"' : '');
				} elsif (defined $color) {
					$attr = ' fill="rgb(' . join(',', _rgb255($color)) . ')"';
				}
				# centered on its own column, whatever the font's advance
				$seq .= sprintf qq{<tspan x="%.10g"$attr>%s</tspan>}, $x0 + ($i + 0.5) * $cw, $c;
				next unless defined $color;
				push @tips, sprintf(qq{  <rect x="%.10g" y="%.10g" width="$cw" height="$lh" fill="none" pointer-events="all"><title>%s</title></rect>\n},
					$x0 + $i * $cw, $y + 4 - $lh, _xml(_chars($row->{tips}[$i]))) if defined $row->{tips}[$i];
			}
			# $seq is an argument, not part of the format, which a residue "%" would break
			$svg .= sprintf(qq{  <text y="$y" text-anchor="middle" xml:space="preserve"%s>%s</text>\n},
				$row->{track} ? ' fill="#666666"' : '', $seq);
			$svg .= join '', @tips;
			$svg .= sprintf(qq{  <text x="%.10g" y="$y" text-anchor="end">$row->{count}</text>\n}, $x_count) unless $row->{track};
		}
	}
	$svg .= " </g>\n</svg>\n";
	utf8::encode($svg);
	open my $fh, '>:raw', $file or croak "$sub: can't write $file: $!";
	print {$fh} $svg or croak "$sub: can't write $file: $!";
	close $fh or croak "$sub: can't write $file: $!";
}

sub view_alignment {
	my $sub = 'view_alignment';
	# The alignment comes first, as the data does in Stats::LikeR's view: a hash
	# ref of name => sequence, or a FASTA file name; or else it is "msa_file",
	# among the name => value pairs. It is the odd one out, so an odd number of
	# arguments means it was given first.
	my @list = @_;
	my $data = @list % 2 ? shift @list : undef;
	# msa_file: a FASTA file, aligned (such as plot_msa's) or not;
	# output_file: a .svg or a .tex to write; color_residues: {protein =>
	# {1-based residue number => color}}, the color an xcolor base name or an
	# [r, g, b] ref; color: 1 = every residue on its color from plot_msa's
	# palette, 0 = only those of color_residues; order: proteins top to bottom;
	# row_width: columns per block (100); track: a protein whose colored residue
	# numbers get a row of their own; threads and clustal_args: for clustalo, if
	# the sequences have to be aligned; to: the filehandle to print to;
	# return_only: 1 = print nothing; title: a line above the alignment in
	# "output_file", .svg or .tex; caption, label, split (blocks per table, 4)
	# and table_text_size: for a .tex only.
	my $args = _args(\@list, $sub, [], [qw(caption clustal_args color color_residues label msa_file order output_file return_only
		row_width split table_text_size threads title to track)]);
	_refs($sub, $args, 'ARRAY', qw(clustal_args order));
	_file_names($sub, $args, qw(msa_file output_file));
	_threads($sub, $args);
	if (defined $data) {
		croak "$sub: was given the alignment both first and as \"msa_file\"" if defined $args->{'msa_file'};
		croak "$sub: the alignment must be a hash ref of name => sequence or a FASTA file name, not " . _what($data)
			unless ref $data eq 'HASH' || (!ref $data && $data ne '');
	} else {
		$data = $args->{'msa_file'} // croak "$sub: needs an alignment, first or as \"msa_file\"";
	}
	my %r;
	$r{'row_width'} = $args->{'row_width'} // 100;
	$r{split} = $args->{split} // 4;
	# 0 would never end the loop over blocks, and divide by 0 in the tables
	foreach my $k ('row_width', 'split') {
		croak "$sub: \"$k\" must be a whole number, 1 or more, not " . _what($args->{$k}) if defined $args->{$k} && (ref $args->{$k} || $args->{$k} !~ /\A[1-9][0-9]*\z/);
	}
	$r{color} = $args->{color} // 0; # 1 = every residue on its palette color; 0 = only "color_residues" colored
	croak "$sub: \"color\" must be 0 or 1, not " . _what($r{color}) unless !ref $r{color} && ($r{color} eq '0' || $r{color} eq '1');
	$r{'return_only'} = $args->{'return_only'} // 0; # 1 = return the text and print nothing; 0 = print it too
	croak "$sub: \"return_only\" must be 0 or 1, not " . _what($r{'return_only'})
		unless !ref $r{'return_only'} && ($r{'return_only'} eq '0' || $r{'return_only'} eq '1');
	require Symbol;
	require Scalar::Util;
	# the selected handle, which is STDOUT unless the program changed it
	$r{to} = Scalar::Util::openhandle($args->{to} // Symbol::qualify_to_ref(select()))
		// croak "$sub: \"to\" must be an open filehandle, not " . _what($args->{to});
	$r{'output_file'} = $args->{'output_file'};
	$r{format} = !defined $r{'output_file'} ? '' : $r{'output_file'} =~ /\.svg\z/i ? 'svg' : $r{'output_file'} =~ /\.tex\z/i ? 'tex'
		: croak "$sub: \"output_file\" must end in .svg or .tex, which say what to write, not \"$r{'output_file'}\""; # '' = no file
	my @tex_only = grep { defined $args->{$_} } qw(caption label split table_text_size);
	croak "$sub: " . join(', ', map { "\"$_\"" } @tex_only) . ' only shape a LaTeX "output_file" (.tex)' if @tex_only && $r{format} ne 'tex';
	$r{title} = $args->{title} // ''; # '' = no title line
	croak "$sub: \"title\" is drawn only in an \"output_file\" (.svg or .tex), and none was given" if defined $args->{title} && $r{format} eq '';
	croak "$sub: \"title\" must be a string, not " . _what($r{title}) if ref $r{title};
	# a newline would end the SVG's line of text, and a blank line the LaTeX's \textbf
	croak "$sub: \"title\" holds a control character, " . sprintf('\\x{%02x}', ord $1) if $r{title} =~ /([\x00-\x1f\x7f])/;
	$r{caption} = $args->{caption} // '';
	$r{label} = $args->{label};
	$r{'table_text_size'} = $args->{'table_text_size'} // '\footnotesize';
	my $color = $args->{'color_residues'} // {};
	croak "$sub: \"color_residues\" must be a hash ref" unless ref $color eq 'HASH';
	foreach my $protein (sort keys %{ $color }) {
		croak "$sub: \"color_residues\" must map $protein to a hash ref of residue number => color, not " . _what($color->{$protein})
			unless ref $color->{$protein} eq 'HASH';
		# checked before they are sorted as numbers, which would warn of one that is not
		_residue_number($sub, "a residue of $protein in \"color_residues\"", $_) foreach sort keys %{ $color->{$protein} };
		foreach my $n (sort { $a <=> $b } keys %{ $color->{$protein} }) {
			my $c = $color->{$protein}{$n};
			# xcolor's own names beyond its base 19 (dvipsnames and the rest)
			# have no rgb here, for the terminal or the SVG
			croak "$sub: the color of $protein residue $n must be one of xcolor's base colors (" . join(', ', sort keys %Xcolor)
				. ') or [r, g, b], each 0 to 1, not ' . _what($c)
				unless ref $c ? ref $c eq 'ARRAY' && @{ $c } == 3 && !grep { !defined $_ || ref $_ || !/\A(?:[0-9]+\.?[0-9]*|\.[0-9]+)\z/ || $_ > 1 } @{ $c }
					: defined $Xcolor{$c};
		}
	}
	my ($fasta, $seqs);
	if (ref $data) {
		($fasta, $seqs) = ($data, $data);
	} else {
		croak "$sub: the FASTA file $data doesn't exist" unless -e $data;
		($fasta, $seqs) = ($data, fasta2hash($data));
	}
	croak "$sub: has no sequences to show in " . (ref $data ? 'the hash ref' : $data) unless %{ $seqs };
	foreach my $name (sort keys %{ $seqs }) {
		my $s = $seqs->{$name};
		croak "$sub: sequence \"$name\" must be a string of residues, not " . _what($s) unless defined $s && !ref $s;
		# one would break a row in two, or make the SVG XML no longer
		croak "$sub: sequence \"$name\" holds a control character, " . sprintf('\\x{%02x}', ord $1) if $s =~ /([\x00-\x1f\x7f])/;
	}
	my %len = map { length $_ => 1 } values %{ $seqs };
	my ($cmd, $names);
	if (keys %len > 1) {
		# Sequences of different lengths can't be an alignment, so align them,
		# into a temporary file: the input is never written.
		my %clustal = map { $_ => $args->{$_} } grep { defined $args->{$_} } qw(clustal_args threads);
		(undef, undef, $names, $cmd, $seqs) = _align({ %clustal, fasta => $fasta }, $sub, 0);
		%len = map { length $_ => 1 } values %{ $seqs };
	}
	my ($aln_len) = keys %len;
	croak "$sub: has no residues to show in " . (ref $data ? 'the hash ref' : $data) unless $aln_len;
	my $track = $args->{track};
	croak "$sub: tracker \"$track\" isn't in the alignment" if defined $track && !defined $seqs->{$track};
	my @undef = grep { !defined $seqs->{$_} } sort keys %{ $color };
	croak "$sub: \"color_residues\" names proteins that aren't in the alignment: @undef" if @undef;
	my @proteins = @{ $args->{order} // [sort { lc $a cmp lc $b } keys %{ $seqs }] };
	my @bad = grep { !defined $seqs->{$_} } @proteins;
	croak "$sub: \"order\" names proteins that aren't in the alignment: @bad" if @bad;
	my $width = $r{'row_width'};
	# Alignment column => color, and for the tracked protein column => its
	# residue number. A colored column is colored in every protein.
	my (%col_color, %col_number);
	foreach my $protein (sort keys %{ $color }) {
		my @col;
		while ($seqs->{$protein} =~ /[A-Za-z]/g) {
			push @col, pos($seqs->{$protein}) - 1;
		}
		foreach my $n (sort { $a <=> $b } keys %{ $color->{$protein} }) {
			my $col = $col[$n - 1] // croak "$sub: $protein has no residue $n";
			$col_color{$col} = $color->{$protein}{$n};
			$col_number{$col} = $n if defined $track && $protein eq $track;
		}
	}
	# Each block of "row_width" columns: its first column (0-based), its width,
	# and its rows, each of which has its name, the label it is shown under,
	# whether it is the track row (1) or a sequence (0), its characters, each
	# one's color of "color_residues" or undef, each one's tooltip or undef, each
	# one's background as 0 to 255 r, g, b or undef (with "color" only), each
	# one's emphasis (1 = one of "color_residues" on a background, which is
	# shown bold and underlined; undef = none), and the residues so far. With
	# "color", one of "color_residues" has its own color as its background.
	my $palette = $r{color} ? _palette_for($seqs) : undef; # 'aa' or 'nt'; undef = no "color"
	my %bg = $r{color} ? map { $_ => [map { hex } $Residue_color{$palette}{$_} =~ /([0-9a-f]{2})/gi] } keys %{ $Residue_color{$palette} } : ();
	my (@blocks, %count);
	for (my $start = 0; $start < $aln_len; $start += $width) {
		my $w = $aln_len - $start < $width ? $aln_len - $start : $width;
		my @rows;
		foreach my $protein (@proteins) {
			my @seq = split //, substr($seqs->{$protein}, $start, $w);
			my (@colors, @tips, @bg, @strong);
			foreach my $i (0 .. $#seq) {
				my $before = $count{$protein} // 0;
				$count{$protein} = $before + 1 if $seq[$i] =~ /[A-Za-z]/;
				$bg[$i] = $bg{ uc $seq[$i] } if $r{color};
				my $c = $col_color{ $start + $i } // next;
				$colors[$i] = $c;
				($bg[$i], $strong[$i]) = ([_rgb255($c)], 1) if $r{color};
				$tips[$i] = _shown_name($protein) . ': ' . ($seq[$i] =~ /[A-Za-z]/ ? "$seq[$i]$count{$protein}" : 'a gap')
					. ', alignment column ' . ($start + $i + 1);
			}
			$count{$protein} //= 0;
			push @rows, { name => $protein, label => _shown_name($protein), track => 0, chars => \@seq, colors => \@colors,
				tips => \@tips, bg => \@bg, strong => \@strong, count => $count{$protein} };
			next unless defined $track && $protein eq $track;
			# Each residue number written from its own column rightwards, one
			# digit per column so the row stays aligned, and moved right past
			# the end of the previous number rather than overwriting it. One
			# that would then run past the end of the block is moved left to end
			# there, and is left out only if that would overwrite the number
			# before it.
			my @row = ('-') x $w;
			my $free = 0; # first column not yet taken by a number
			foreach my $col (sort { $a <=> $b } grep { $_ >= $start && $_ < $start + $w } keys %col_number) {
				my $at = $col - $start < $free ? $free : $col - $start;
				my @digits = split //, $col_number{$col};
				$at = $w - @digits if $at + @digits > $w;
				next if $at < $free;
				@row[$at .. $at + $#digits] = @digits;
				$free = $at + @digits + 1;
			}
			push @rows, { name => $protein, label => _shown_name($protein) . ' track', track => 1, chars => \@row, colors => [], tips => [],
				bg => [], strong => [], count => $count{$protein} };
		}
		push @blocks, { start => $start, width => $w, rows => \@rows };
	}
	my $n_seqs = keys %{ $seqs };
	my $banner = "# alignment: $n_seqs sequence" . ($n_seqs == 1 ? '' : 's') . " x $aln_len column" . ($aln_len == 1 ? '' : 's')
		. (defined $cmd ? ', aligned by Clustal Omega' : '') . (@proteins == $n_seqs ? '' : '  (showing ' . scalar(@proteins) . ')');
	if ($r{format} ne '') {
		my $from = defined $cmd ? _align_provenance({ fasta => $fasta }, $sub, $cmd, $names, $cmd->[4])
			: 'from ' . _fasta_id($fasta, $n_seqs);
		my $creator = _creator($sub, 1) . ', written as ' . ($r{format} eq 'svg' ? 'SVG' : 'LaTeX') . ' by ' . __FILE__ . " itself; $from"
			. '; showing ' . scalar(@proteins) . " of $n_seqs sequences in blocks of $width columns"
			. (defined $track ? ', tracking ' . _shown_name($track) : '') . ', coloring ' . scalar(keys %col_color) . ' column'
			. (keys %col_color == 1 ? '' : 's')
			. ($r{color} ? ', every residue on its color from CIAlign\'s CBS ' . ($palette eq 'nt' ? 'nucleotide' : 'amino acid') . ' palette, as plot_msa colors it' : '');
		if ($r{format} eq 'svg') {
			_alignment_svg($sub, $r{'output_file'}, \@blocks, $creator, $r{title});
		} else {
			_alignment_tex($sub, \%r, \@blocks, $creator);
		}
	}
	my $text = _alignment_text(\@blocks, $banner, 0);
	utf8::encode($text);
	return $text if $r{'return_only'};
	my $shown = $text;
	if (-t $r{to}) {
		$shown = _alignment_text(\@blocks, $banner, 1);
		utf8::encode($shown);
	}
	print { $r{to} } $shown or croak "$sub: can't print to \"to\": $!";
	_wrote($r{'output_file'}, 46) if $r{format} ne ''; # cyan
	$text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cn::Bioinf - FASTA I/O in XS, BLAST hit ranking, and alignment plots and tables

=head1 VERSION

version 0.031

=head1 SYNOPSIS

 use Cn::Bioinf ':all';

 my $seqs = fasta2hash('proteome.fa.gz');        # { defline => sequence }
 my $one  = fasta2hash('proteome.fa', 'P12345'); # just that sequence
 hash2fasta_file($seqs, 'copy.fa');
 my $part = fasta_region('genome.fa', 'chr1:1000-2000');   # as samtools faidx

 # sequences as strings
 my $rc      = reverse_complement('ATGAAACTG');             # CAGTTTCAT
 my $protein = translate('ATGAAACTGTAA', to_stop => 1);     # MKL
 my $orfs    = find_orfs($one, table => 11, min_length => 100);
 my $hits    = motif_search($one, 'GRATYC', strand => 'both');
 my $gc      = gc_content($one);
 my $kmers   = kmer_count($one, 4);
 my $stats   = assembly_stats($seqs);                       # N50 and the rest
 my $pi      = isoelectric_point($protein);

 my $hits = get_best_alignment_hit('blast.json', 'bit_score');

 # the PDB structures that match a sequence, how well, and what kind they are
 my $pdb = pdb_search(seq => $one);
 print "$pdb->[0]{id} $pdb->[0]{pident}% $pdb->[0]{method} $pdb->[0]{resolution}\n";

 # one clustalo run: plot_msa keeps the guide tree, and plot_phylo draws it
 plot_msa(
     fasta       => 'orthologs.fa',     # or { name => sequence }
     filename    => 'msa.svg',          # .png, .pdf, ... too
     'tree_file' => 'orthologs.newick',
     title       => 'EF-3',
 );
 plot_phylo('tree_file' => 'orthologs.newick', 'output_file' => 'tree.svg', title => 'EF-3');

 # the alignment in the terminal, as Stats::LikeR's view shows a table, and as an SVG
 view_alignment('orthologs.fa', output_file => 'aln.svg', track => 'S.cerevisiae',
     color_residues => { 'S.cerevisiae' => { 3 => 'red', 8 => 'blue' } });

 # a polygenic score for each sample of a VCF, from a PGS Catalog scoring file
 my $scores = pgs_score(vcf => 'genome.vcf.gz', weights => 'PGS000138.txt.gz');

 # population genetics of a cohort's VCF, by PLINK 2
 my $pruned = ld_prune(vcf => 'cohort.vcf.gz');                 # { keep => [...], remove => [...] }
 my $pcs    = pca(vcf => 'cohort.vcf.gz', n => 4);              # { samples => { sample => [PC1 .. PC4] }, ... }
 my $fst    = fst(vcf => 'cohort.vcf.gz', populations => \%population_of);
 print $fst->{fst}{CEU}{YRI};
 my $hwe    = hardy_weinberg(vcf => 'cohort.vcf.gz');           # [ { chrom, pos, het, p, ... }, ... ]
 my $ld     = ld(vcf => 'cohort.vcf.gz', window_kb => 250);      # [ { a => {...}, b => {...}, r2 }, ... ]
 my $gwas   = gwas(vcf => 'cohort.vcf.gz', phenotypes => 'pheno.tsv', phenotype => 'height',
                   covariates => [qw(age sex)]);                # [ { beta, se, p, ... }, ... ]
 my $anc    = admixture(vcf => 'cohort.vcf.gz', k => 3);        # { samples => { sample => [3 fractions] }, ... }

 # each sample's sex, from its heterozygosity on X
 my $sex = sex_check(vcf => 'cohort.vcf.bz2'); # { sample => { sex => 'female', ... } }

 # whether two people are parent and child: 1 or 0
 my $is = parent(child => 'child.vcf.gz', parent => 'father.vcf.gz');

 # how every two people are related: father-son, brother-sister, ...
 my $kin = relatedness('mom.vcf.gz', 'dad.vcf.gz', 'kid.vcf.gz');
 print $kin->{'kid'}{'dad'}{category}; # by the sample names in the VCFs

 # how well a test VCF's calls agree with a truth VCF's, sample by sample
 my $conc = concordance(truth => 'NA12878.truth.vcf.gz', test => 'NA12878.run42.vcf.gz');
 print $conc->{'NA12878'}{metrics}{genotype_concordance};

 # each sample's ABO and RhD blood type, and the genotype behind each
 my $blood = blood_type(vcf => 'exome.vcf.gz');
 print "$blood->{'NA12878'}{type} ($blood->{'NA12878'}{abo}{genotype})\n"; # A+ (AO)

 # the 41 HIrisPlex-S markers, as the webtool's CSV wants them
 my $g = hirisplex_genotypes(vcf => 'genome.vcf.gz', file => 'hirisplexs.csv');

 # ... and a prediction from a multinomial logistic model you supply
 my $p = trait_predict(genotypes => $g, model => 'my_model.tsv');
 print $p->{'NA12878'}{eye}{call};

=head1 DESCRIPTION

FASTA I/O in XS, with C<samtools>'s index for fetching a part of a file; the
everyday operations on a sequence (its reverse complement, its translation
under any of NCBI's genetic codes, its open reading frames, GC content, k-mers,
motifs, molecular weight and isoelectric point, and an assembly's N50); BLAST
hit ranking, a search of the PDB's structures for a
sequence, and multiple-sequence-alignment plots and LaTeX tables; polygenic scores from a VCF and a PGS Catalog scoring file; a cohort's principal components, Fst between populations, Hardy-Weinberg tests, linkage disequilibrium and its pruning, and association tests (GWAS), by PLINK 2; admixture proportions; and, from VCFs, each sample's sex, whether two people are parent and child, how every two people are related, how well one VCF's calls agree with another's, each sample's ABO and RhD blood type, and the genotypes of the HIrisPlex-S eye, hair and skin colour panel, with a trait predictor for any multinomial logistic model you supply.

Nothing is exported by default; ask for functions by name or with C<:all>.
Every function dies (via C<Carp::croak>) on bad arguments, with a message that
starts with the name of the function that raised it, as in
C<fasta2hash: couldn't find "four" in x.fa>. C<pdb_search>, C<pgs_score>, C<pca>, C<fst>, C<hardy_weinberg>, C<ld>, C<ld_prune>, C<gwas>, C<admixture>, C<sex_check>,
C<parent>, C<relatedness>, C<concordance>, C<blood_type>, C<hirisplex_genotypes>, C<trait_predict>, C<plot_msa>, C<plot_phylo> and C<msa_quality_table>
take C<< name =E<gt> value >> pairs, not a hash ref; C<view_alignment> takes the
alignment first, as a hash ref or a file name, and C<< name =E<gt> value >> pairs after
it.

=head2 Alien::Bioinf

Clustal Omega, BLAST+, PLINK 2 and the Python that draws the plots come from
C<Alien::Bioinf>, which installs them module-locally and never uses C<PATH>. It
is recommended rather than required, because it can only be installed where
NCBI builds BLAST+ (Linux and macOS on x86_64 and aarch64, and Windows on
x86_64) and it needs the network; PLINK 2 has no build for Linux on aarch64,
so there it installs the rest. C<fasta2hash>, C<hash2fasta_file>,
C<get_best_alignment_hit>, C<sex_check>, C<parent>, C<relatedness>, C<concordance>,
C<hirisplex_genotypes> and C<trait_predict> work without it; C<pgs_score>, C<plot_msa>,
C<plot_phylo>, C<msa_quality_table>, and C<view_alignment> given
sequences that are not aligned, die saying that they need it. A CPAN client does not install a recommended module
unless asked, so install it first:

 cpanm Alien::Bioinf
 cpanm Cn::Bioinf

or, from a clone of L<the repository|https://github.com/hhg7/Bioinf-Basic>,
where it is C<alien/Alien-Bioinf>:

 cpanm ./alien/Alien-Bioinf
 cpanm .

That downloads nothing it can reuse: archives are cached (C<ALIEN_BIOINF_CACHE>,
default C<~/.cache/alien-bioinf>), a clustalo or BLAST+ already on the machine at
the newest version is copied instead (C<ALIEN_BIOINF_CLUSTALO>,
C<ALIEN_BIOINF_BLAST>, or C<PATH>), and pip reuses the wheels in its own cache.
The Python packages go into a venv of their own, which nothing installed into
the base Python can break. To check for and apply updates:

 perl -MAlien::Bioinf -MData::Dumper -e 'print Dumper(Alien::Bioinf->check_updates)'
 perl -MAlien::Bioinf -e 'print "$_\n" for Alien::Bioinf->update'

=head2 Provenance in the images

Every PNG, SVG, PDF, PS or EPS image these functions draw carries its whole
provenance on one line, as its C<Creator> metadata and nothing else, just as
Matplotlib::Simple writes it. The line names the calling script (its full
path), the function, this file and its
version, the Alien::Bioinf version, the user who ran it, the computer it ran
on (hostname and operating system), the perl version and path, and what drew
it: C<msa_plot.py>, the Python version and path, the matplotlib version, and
for a tree the Biopython and NumPy versions too. The line has no date; an SVG
has the C<< E<lt>dc:dateE<gt> >> matplotlib writes beside it, taken from
C<SOURCE_DATE_EPOCH> where that is set. After a C<;> come the image's title
(or "untitled") and what it was made from and how, with the full path and
SHA-256 of each file:

=over

=item * C<plot_msa>: the FASTA file and how many sequences it holds (or the number
of sequences in a hash ref), the ungapped copy of it that Clustal Omega
read, with the sequences named C<s1>, C<s2> and so on, the alignment Clustal
Omega wrote, with the names put back, the Clustal Omega version, the exact
command, and the C<msa_file> and C<tree_file> kept, if any.

=item * C<plot_phylo>: the same when it aligns, with the guide tree it drew;
otherwise the newick file it drew. Then how many negative branch lengths
were drawn as 0, if any; the tips, with the label each was shown as; and the
whole newick tree that was drawn.

=item * C<msa_quality_table>: the metric shown, and either the BLAST report it read
or the FASTA file, its ungapped copy, the report blastp wrote, the blastp
version, the exact command, and the C<alignment_json> kept, if any.

=back

For example:

 /home/me/work/run.pl called using "plot_phylo" in /.../Cn/Bioinf.pm
 version 0.01 with Alien::Bioinf 0.01 by user me on host myhost (linux)
 with Perl 5.44.0 (/usr/bin/perl), drawn by /.../msa_plot.py with
 Python 3.14.2 (/.../venv/bin/python),
 matplotlib 3.11.2, Biopython 1.87, NumPy 2.4.6; titled "DEG20010421";
 from the newick file /home/me/work/t.newick (SHA-256 f0e8...); 4 tips:
 S.cerevisiae, ...; the tree as drawn, in newick: (S.cerevisiae:0.389085,...);

An SVG holds it in C<< E<lt>dc:creatorE<gt> >>; C<exiftool> or C<identify -verbose> shows it
in a PNG or PDF.

=head1 FUNCTIONS

=head2 fasta2hash($file, $key)

Reads a FASTA file (gzip-compressed if its name ends in C<.gz>, in any case,
which needs a C<gzip> program on C<PATH>). Returns a hash ref of defline (without the C<< E<gt> >>) =>
sequence, or, with C<$key>, just the sequence of that defline, reading no
further than the record after it. A defline that appears twice is warned about
and its sequences concatenated. With C<$key>, reading stops at the defline
after that record, so only a repeat that follows it directly is seen; a second
record of that name further on is not read, and the first's sequence comes
back alone, with no warning. Read the whole file where that matters. Line
endings may be C<\n> or C<\r\n>; a file whose lines end in C<\r> alone (classic
Mac OS) dies, since without a C<\n> it is all one line. Whitespace (space, tab, C<\r>, C<\f>
and C<\x0b>) is dropped from sequences and from the end of deflines, as
Biopython drops it, so a defline of C<x> and a space is found as C<x>. Deflines and sequences are bytes,
just as they are in the file. A C<.gz> that gzip cannot read to its end, such as
a truncated one, dies rather than returning the part that was read.

 my $h = fasta2hash('DEG20010421.fa');

=head2 hash2fasta_file($hash, $filename, $order, $width)

Writes C<$hash> as FASTA: the keys in C<@$order> (default: sorted), sequences
wrapped at C<$width> columns (default 80; 0 for one line each). Returns
C<$filename>, and prints C<wrote $filename> to STDOUT, with the name in black
on cyan when STDOUT is a terminal. Keys and sequences are written as bytes, as C<print> to a C<:raw>
handle writes them, so a string that perl holds as UTF-8 is written as the
characters in it. A character above 255 has no single byte and dies; encode
such a string first, as with C<Encode::encode('UTF-8', $name)>. A key that is
empty or holds a line feed dies, as does a sequence that is a reference
(unless it is an object that overloads its own text), since C<fasta2hash> could
not read any of them back as what was given.

=head2 fasta_index($file)

Writes the index of a FASTA file that C<samtools faidx> writes, C<$file.fai>,
and returns its name; it prints C<wrote> and that name to STDOUT, as
C<hash2fasta_file> does. The index has a line for each sequence: its name (the
first word of its defline), its length, the byte where it starts, and how many
bases and how many bytes each of its lines holds. Other programs that read a
C<.fai> can use it, and C<fasta_region> does.

 my $fai = fasta_index('genome.fa');   # genome.fa.fai

A file can be indexed when, within each sequence, every line but the last is
the same length, which is C<samtools>'s rule; a file that breaks it dies, naming
the line. Of two sequences with one name, the first is indexed, with a warning.
A compressed file dies, since a place in it cannot be sought.

=head2 fasta_region($file, @regions)

The parts of a FASTA file that C<@regions> name, as a hash ref of region =>
sequence, without reading the rest of the file: the job of C<samtools faidx>.

 my $part = fasta_region('genome.fa', 'chr1:1,000-2,000', 'chrM');
 print $part->{'chr1:1,000-2,000'};

A region is a sequence's name, for all of it, or C<name:start-end>,
C<name:start> (to the end) or C<name:-end> (from the start), counting from 1 with
both ends included; commas in the numbers are ignored. A name that has a colon
in it, such as C<HLA-A*01:01:01:01>, is taken whole when a sequence has that
name. A region that runs past the end of its sequence is cut short there, and
one that starts past it is empty, as C<samtools faidx> gives them; a name that
is not in the file, a start of 0 and an end before the start die.

It uses C<$file.fai> when that is there, whether C<fasta_index> or C<samtools>
wrote it, and warns when the index is older than the FASTA. Without one it
reads through the file to make the index, which it does not write: for a large
file that will be asked more than once, call C<fasta_index> first. The file must
not be compressed.

=head2 complement($seq, type => 'DNA')

C<$seq> with each nucleotide replaced by the one it pairs with: C<A> and C<T>,
C<C> and C<G>, and each IUPAC ambiguity letter with the letter for the bases its
own pair with (C<R> and C<Y>, C<K> and C<M>, C<B> and C<V>, C<D> and C<H>; C<S>, C<W> and
C<N> are their own). Case is kept, and anything that is not a nucleotide letter,
a gap included, is left as it is.

 complement('ATGAAACTG');                 # TACTTTGAC
 complement('AUGAAACUG', type => 'RNA');  # UACUUUGAC

C<type> is C<DNA> (the default) or C<RNA>, in any case, and says what is written,
C<T> or C<U>; either is read in both. These are Biopython's C<complement> and
C<complement_rna>.

=head2 reverse_complement($seq, type => 'DNA')

C<complement> of C<$seq>, reversed: the other strand, read from its own 5' end.

 reverse_complement('ATGAAACTG');   # CAGTTTCAT

=head2 transcribe($seq), back_transcribe($seq)

C<transcribe> writes C<U> for every C<T> of C<$seq>, and C<back_transcribe> C<T> for
every C<U>, in either case; nothing else changes.

 transcribe('ATGAAACTG');        # AUGAAACUG
 back_transcribe('AUGAAACUG');   # ATGAAACTG

=head2 translate($seq, %args)

The protein that the DNA or RNA C<$seq> codes for, one letter for each three of
its own, from its first letter.

 translate('GTGGCCATTGTAATGGGCCGCTGAAAGGGTGCCCGATAG');                # VAIVMGR*KGAR*
 translate('GTGGCCATTGTAATGGGCCGCTGAAAGGGTGCCCGATAG', to_stop => 1);  # VAIVMGR
 translate($cds, table => 'Vertebrate Mitochondrial', cds => 1);

=over

=item * C<table>: the genetic code, as NCBI's number for it (1, the standard code, by
default) or one of its names in any case, such as C<Standard>, C<SGC0>,
C<Bacterial> or C<Vertebrate Mitochondrial>. The codes are those of
L<NCBI's table|https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi>,
version 4.6: 1 to 6, 9 to 16 and 21 to 33.

=item * C<to_stop>: 1 ends the protein before the first stop codon; 0 (the default)
writes each stop and carries on.

=item * C<stop_symbol>: the character written for a stop, C<*> by default.

=item * C<cds>: 1 says C<$seq> is a whole coding sequence, and checks it: it must start
with one of the code's start codons, be a multiple of three long, end with a
stop codon and have no other. The start codon is then written as C<M>,
whatever it codes for inside a protein, and the stop is left out.

=item * C<gap>: a character, such as C<->, three of which make a codon that is written
as that character. Without it a gap dies, as any other letter that is not a
nucleotide's does, naming the codon.

=back

A codon with an ambiguous letter is given what the codons it stands for agree
on: their amino acid when they share one (C<ATGAARCTG> is C<MKL>), C<*> when all
are stops, C<B> for aspartate or asparagine, C<Z> for glutamate or glutamine, C<J>
for leucine or isoleucine, and C<X> otherwise, a codon that may or may not be a
stop included. Case is ignored, and C<T> and C<U> may be mixed.

One or two letters left after the last whole codon are not translated, with a
warning; cut the sequence to a multiple of three to avoid it. Codes 27, 28 and
31 read some codons as an amino acid or as a stop, by context: those are
translated as the amino acid, with a warning, and C<to_stop> dies with them.

These rules are Biopython's, whose C<Seq.translate> this gives the same answers
as, with one exception: an C<X> in a codon dies here, since it is not an IUPAC
nucleotide letter, where Biopython reads it as C<N> in some codons.

=head2 translate_six_frames($seq, %args)

C<$seq> translated in all six reading frames, as a hash ref: C<1>, C<2> and C<3>
are the frames that start at its first, second and third letter, and C<-1>, C<-2>
and C<-3> those that start at the first, second and third letter of its reverse
complement. Each protein is written from its own N-terminus.

 my $f = translate_six_frames('AUGCUAACAUAAA');
 # { 1 => 'MLT*', 2 => 'C*HK', 3 => 'ANI', -1 => 'FMLA', -2 => 'LC*H', -3 => 'YVS' }

C<table> and C<stop_symbol> are as for C<translate>. Letters left after a frame's
last whole codon are dropped without a warning, since five of the six frames
always have some. The minus frames are numbered as scikit-bio and BLAST number
them, which is EMBOSS C<transeq>'s C<-alternative>.

=head2 find_orfs($seq, %args)

The open reading frames of C<$seq> on both strands, as an array ref of hash
refs in order of where they start:

 my $orfs = find_orfs($plasmid, table => 11, min_length => 100, start => 'code');
 printf "%d-%d %s %s...\n", @{ $_ }{qw(start end strand)}, substr $_->{protein}, 0, 10 for @{ $orfs };

=over

=item * C<table>: the genetic code, as for C<translate>.

=item * C<start>: where a frame opens. C<any> (the default) is at the codon after a
stop, or at the sequence's first, so that every stretch between stops is a
frame. C<ATG> is at the first C<ATG> after that, and C<code> at the first of the
genetic code's own start codons, which for code 11 include C<GTG> and C<TTG>;
with either, the protein starts with C<M>, whatever the codon codes for
elsewhere, and a stretch with no start codon is no frame.

=item * C<min_length>: the fewest amino acids a frame may have, 10 by default.

=item * C<strand>: C<both> (the default), C<+> or C<->.

=back

Each frame has C<start> and C<end>, its first and last base in C<$seq>, counted
from 1, with C<start> the smaller on either strand and the stop codon left out;
C<strand>, 1 or -1; C<frame>, as C<translate_six_frames> numbers them; C<length>,
in amino acids; and C<protein>. A frame that reaches the end of the sequence
without a stop is returned as far as it goes.

This is what EMBOSS's C<getorf> finds: C<< start =E<gt> 'any' >> is its C<-find 0>,
C<< start =E<gt> 'ATG' >> its C<-find 1> with its default table, and C<< start =E<gt> 'code' >>
its C<-find 1> with C<-table>; its C<-minsize> is in nucleotides, three times
C<min_length>.

=head2 gc_content($seq, ambiguous => 'remove')

The share of C<$seq> that is G or C, from 0 to 1, in either case; 0 for an
empty sequence. C<S>, which is G or C, counts as one.

 gc_content('ACTGN');                           # 0.5
 gc_content('ACTGN', ambiguous => 'ignore');    # 0.4

C<ambiguous> says what the other ambiguity letters count for: C<remove> (the
default) leaves them out, so that the share is of the letters A, C, G, T, U, S
and W; C<ignore> counts them in the length but not as G or C; and C<weighted>
counts each as the share of its bases that are G or C, half for C<N> and
two-thirds for C<B>. This is Biopython's C<gc_fraction>.

=head2 kmer_count($seq, $k, %args)

How many times each run of C<$k> letters occurs in C<$seq>, as a hash ref of
k-mer => count. The letters are taken as they are: fold the case first if C<a>
and C<A> should count together.

 kmer_count('GATTACA', 3);                 # { GAT => 1, ATT => 1, TTA => 1, TAC => 1, ACA => 1 }
 kmer_count('GATTACA', 3, overlap => 0);   # { GAT => 1, TAC => 1 }

=over

=item * C<overlap>: 1 (the default) counts the k-mer at every letter; 0 counts one
every C<$k> letters, from the first, so that none overlaps another.

=item * C<relative>: 1 gives each k-mer's share of all that were counted, which sum to
1, in place of its count.

=back

A C<$k> longer than the sequence gives an empty hash. This is scikit-bio's
C<kmer_frequencies>.

=head2 assembly_stats($seqs)

The statistics of a set of sequences, such as the contigs of an assembly, that
C<assembly-stats> prints. C<$seqs> is a hash ref of name => sequence, as
C<fasta2hash> returns, or an array ref of sequences.

 my $s = assembly_stats(fasta2hash('contigs.fa'));
 print "N50 $s->{n50} in $s->{l50} of $s->{number} contigs\n";

It returns a hash ref of C<number>, how many sequences there are;
C<total_length>, C<mean_length>, C<longest> and C<shortest>; C<n_count>, how many
letters are C<N> or C<n>, and C<gaps>, how many runs of them there are; C<n50> and
C<l50>; and C<nx> and C<lx>, hash refs of those two for every tenth from 10 to 100.
N50 is the length of the sequence at which the lengths, added from the longest
down, first reach half of their total, and L50 is how many sequences that took;
C<< $s-E<gt>{nx}{90} >> and C<< $s-E<gt>{lx}{90} >> are the same for 90%. With no sequences
every number is 0, and with no sequence of any length every Nx and Lx is.

=head2 molecular_weight($seq, %args)

The weight of a molecule of DNA, RNA or protein, in daltons.

 molecular_weight('AGC');                      # 949.6095
 molecular_weight('AGC', type => 'RNA');       # 997.6077
 molecular_weight('AGC', type => 'protein');   # 249.2874

=over

=item * C<type>: C<DNA> (the default), C<RNA> or C<protein>, in any case.

=item * C<double_stranded>: 1 adds the weight of the strand that pairs with C<$seq>.

=item * C<circular>: 1 for a molecule with no ends, which has one more bond.

=item * C<monoisotopic>: 1 uses the weight of each element's commonest isotope, which
is what a mass spectrometer resolves, rather than its average weight.

=back

A nucleic acid is weighed with a 5' phosphate. Only the plain letters have a
weight -- C<ACGT>, C<ACGU>, or the 20 amino acids with C<O> (pyrrolysine) and C<U>
(selenocysteine) -- so any other letter dies, as does an empty sequence;
whitespace is dropped and case ignored. The weights are Biopython's, and this
is its C<molecular_weight>.

=head2 isoelectric_point($protein), protein_charge($protein, $pH)

C<isoelectric_point> is the pH at which a protein has no net charge, and
C<protein_charge> its charge at a pH you give.

 isoelectric_point('INGAR');    # 9.75
 protein_charge('INGAR', 7);    # 0.76

The charge is that of the two ends of the chain and of every K, R, H, D, E, C
and Y, each by the Henderson-Hasselbalch equation, with the pK values of
Bjellqvist et al. (I<Electrophoresis> 14:1023, 1993, and 15:529, 1994), which
depend on the residue at each end; these are the values ExPASy's Compute pI/Mw
uses, and the method is that of Biopython's C<IsoelectricPoint>. The isoelectric
point is found by bisection and is good to four decimal places. Other letters
carry no charge, case is ignored, and an empty sequence dies.

=head2 subseq($seq, $start, $end)

The part of C<$seq> from C<$start> to C<$end>, counting from 1 with both
included; C<$end> is the sequence's end when it is not given.

 subseq('TTGGTGGCGTCAACT', 2, 5);   # TGGT

A start of 0, a start after the end and an end past the sequence die, as they
do in BioPerl's C<subseq>. For a part of a sequence in a file, see
C<fasta_region>.

=head2 motif_search($seq, $motif, %args)

Where C<$motif> occurs in C<$seq>, as an array ref of hits in order of where
they start, each a hash ref of C<start> and C<end> (counted from 1, both
included), C<strand> (1 or -1) and C<match>, the letters that matched. Hits that
overlap are all found.

 my $hits = motif_search($seq, 'GRATYC', strand => 'both');   # EcoRI and BamHI sites
 my $glyc = motif_search($protein, qr/N[^P][ST][^P]/, type => 'protein');

C<$motif> is a string of IUPAC letters or a C<qr//> pattern. In a string of
nucleotide letters, each ambiguity letter matches any of its bases (C<R> is C<A>
or C<G>, C<N> any of the four), C<T> and C<U> match each other, and case is
ignored; in a protein's, C<B> is C<D> or C<N>, C<Z> is C<E> or C<Q>, C<J> is C<I> or
C<L>, and C<X> is anything. A pattern is used as it is written.

=over

=item * C<type>: C<DNA> (the default), C<RNA> or C<protein>.

=item * C<strand>: C<+> (the default), C<-> or C<both>. The minus strand is searched as
its own sequence, the reverse complement of C<$seq>, so a hit there has the
motif as its C<match>, while its C<start> and C<end> are still positions in
C<$seq>. A motif that is its own reverse complement is found on both strands
at each site.

=back

=head2 get_best_alignment_hit($json_file, $sort_criterion)

For a BLAST C<-outfmt 15> JSON report, a hash ref of query title => array ref
of that query's hits, best first. Each hit is its best hsp plus C<accession>,
C<hit_len>, C<id> and C<title>, and C<descriptions>, an array ref of every
description BLAST gave the hit. A hit against a non-redundant database such as
nr has one for each accession of the same sequence; C<accession>, C<id> and
C<title> are those of the first, which is the one BLAST lists first. C<$sort_criterion> is an hsp field (default
C<evalue>): C<align_len>, C<bit_score>, C<evalue>, C<gaps>, C<identity>,
C<positive> or C<score>. Ties are broken on the bit score, then on BLAST's
order. A report with two queries of one title dies, since only one of them
could be returned.

=head2 pdb_search(%args)

Searches the structures of the L<RCSB PDB|https://www.rcsb.org/> for a
sequence, and returns the matching ones, best first, each with how well it
aligns and what kind of structure it is:

 use Cn::Bioinf qw(pdb_search);

 my $hits = pdb_search(seq => 'MVLSPADKTNVKAAWGKVGAHAGEYGAEALERMF...');
 my $best = $hits->[0];
 print "$best->{id}: $best->{pident}% identical over $best->{query_cover}% of the query, ",
     "$best->{method} at $best->{resolution} A, $best->{oligomeric_state}\n";
 # 1BZ1_1: 100% identical over 100% of the query, X-ray at 1.59 A, Hetero 4-mer

 my ($hits, $total) = pdb_search(seq => $seq, max_hits => 10); # and how many RCSB found

It needs the network, and HTTPS, which HTTP::Tiny gets from C<IO::Socket::SSL>
and C<Net::SSLeay>; without them it dies saying which is missing. It asks two
of RCSB's APIs: the L<search API|https://search.rcsb.org/> finds the polymer
entities (one distinct chain of a structure) whose sequence matches, and the
L<data API|https://data.rcsb.org/> says what each one's structure is.

RCSB aligns with MMseqs2, not BLAST, so the numbers are MMseqs2's: its E-value
and bit score are on BLAST's scale but are not what C<blastp> would give for the
same pair. They are returned under the names C<get_best_alignment_hit> gives a
BLAST hsp.

=head3 Arguments

=over

=item * C<seq> (required): the sequence, as a string. Whitespace is removed, lower
case is made upper case, and a final C<*> (a stop) is dropped, so a sequence
pasted from a FASTA file can be given as it is; any other character that is
not a letter dies. RCSB itself refuses a sequence shorter than 10 residues.

=item * C<type>: C<protein> (the default), C<dna> or C<rna>.

=item * C<evalue>: hits with this E-value or above are left out. The default is 0.1,
not BLAST's 10, which in a search of the whole PDB lets in hits expected 10
times over by chance.

=item * C<identity>: hits with less identity than this percentage are left out
(default 0).

=item * C<max_hits>: the most hits returned (default 100). RCSB allows up to 10000.

=item * C<computed>: 0 (the default) searches experimental structures only; 1 also
searches the computed structure models RCSB holds, from AlphaFold DB and
ModelArchive.

=item * C<report>: 1 (the default) prints a table of the hits to STDOUT; 0 returns
them only.

=item * C<timeout>: seconds to wait for each request to RCSB (default 60).

=back

=head3 What it returns

An array ref of hits, best first: by E-value, then bit score, then RCSB's own
order, as C<get_best_alignment_hit> sorts by C<evalue>. Many hits tie: every
structure of the query's own protein aligns the same way. In list context, the
number of hits RCSB found is returned as well, which can be more than
C<max_hits>. Nothing matching is an empty array ref, not an error.

Each hit is a hash ref with every one of these keys, C<undef> or an empty array
ref where RCSB has no value:

What it is:

=over

=item * C<id>: the polymer entity, as C<1BZ1_1>: entry C<1BZ1>, entity C<1>.

=item * C<entry>, C<entity>: the two halves of C<id>. A computed model's entry is like
C<AF_AFP69905F1>.

=item * C<url>: the entry's page at RCSB.

=back

How well it aligns:

=over

=item * C<evalue>, C<bit_score>: MMseqs2's.

=item * C<align_len>: the length of the alignment, gaps included.

=item * C<identity>: the number of aligned columns where the two agree, and C<pident>,
that as a percentage of C<align_len>. These are counted from the aligned
sequences, since RCSB gives the identity only truncated to 3 places.
C<pident> is C<undef> if RCSB gives an C<align_len> of 0 or none.

=item * C<mismatches>, C<gaps> (gap columns), C<gap_opens>.

=item * C<query_from>, C<query_to>, C<query_len> and C<query_cover>, the percentage of
the query in the alignment, which is C<undef> if RCSB gives no C<query_len>
or one of 0.

=item * C<hit_from>, C<hit_to>, C<hit_len>: the same for the hit's sequence.

=item * C<qseq>, C<hseq>: the aligned query and hit, with C<-> for gaps.

=back

What kind of structure it is:

=over

=item * C<title>: the entry's title, and C<description>, the entity's name.

=item * C<method>: how the structure was determined: C<X-ray>, C<EM>, C<NMR>,
C<Neutron>, C<Integrative>, C<Multiple methods> or C<Other>; C<undef> for a
computed model.

=item * C<methodology>: C<experimental>, C<computational> or C<integrative>.

=item * C<resolution>: in Å, for X-ray and EM structures.

=item * C<plddt>: a computed model's mean pLDDT, 0 to 100.

=item * C<polymer_type>: C<Protein>, C<DNA>, C<RNA>, C<NA-hybrid> or C<Other>.

=item * C<polymer_composition>: the entry as a whole, such as C<homomeric protein>,
C<heteromeric protein> or C<protein/NA>.

=item * C<oligomeric_state>, C<stoichiometry> and C<symmetry>: the global symmetry of
the first biological assembly, such as C<Hetero 4-mer>, C<A2B2> and C<C2>.

=item * C<chains>: an array ref of the chains that are this entity.

=item * C<organisms>: an array ref of C<{ name, taxonomy_id }>.

=item * C<uniprot>: an array ref of UniProt accessions.

=item * C<pfam>, C<interpro>: array refs of C<{ id, name }>.

=item * C<ligands>: an array ref of C<{ id, name }>, one for each kind of small
molecule in the entry, such as C<HEM>.

=item * C<deposited>, C<released>: dates, as C<YYYY-MM-DD>.

=back

A hit that the data API has no record of (one so new that RCSB's search index
has it first) is warned of, and is returned with its alignment and no structure.

=head2 pgs_score(%args)

Computes a polygenic score for every sample of a VCF from a scoring file of
the L<PGS Catalog|https://www.pgscatalog.org/downloads/>: for each variant,
the number of copies of the effect allele in the sample's genotype times
C<effect_weight>, summed over the variants. L<PLINK 2|https://www.cog-genomics.org/plink/2.0/>,
which C<Alien::Bioinf> installs, reads the genotypes and does the arithmetic
(C<--score> with C<no-mean-imputation>), so the genotypes are never held in perl:

 use Cn::Bioinf 'pgs_score';

 my $scores = pgs_score(vcf => 'genome.vcf.gz', weights => 'PGS000138.txt.gz');
 # { sample => { score => 1.6742, average => 6.97e-05, variants => 12015,
 #               alleles => 24030, missing => 10259, mismatched => 0 } }

Both arguments may also be data frames, as Stats::LikeR's C<read_table>
returns them, which this module takes without loading Stats::LikeR. Every row
of an array of arrays has as many fields as its header, and every column of a
hash of arrays as many values as the others, or the frame dies. A VCF
given as a frame is written to a temporary VCF for PLINK 2. Files cost less
memory, since a frame is all in perl: on 2026-10-17, PGS000907's 1,773,528
variants were scored from files against a 3.5-million-record genome in 25 s,
with perl peaking at 0.8 GB.

=over

=item * C<vcf> (required): a C<.vcf>, C<.vcf.gz>, C<.vcf.bgz> or C<.bcf> file, a PLINK 2
fileset given by its C<.pgen> (with its C<.pvar> and C<.psam> beside it), or a
data frame in any of C<read_table>'s four shapes whose genotypes are columns
named C<< E<lt>sampleE<gt>.GT >>, as C<read_table> gives a VCF by default; one read with
C<< explode =E<gt> 0 >> has none, and dies. A frame needs C<CHROM>, C<POS>, C<REF> and
C<ALT>, and C<ID> too with C<< match =E<gt> 'id' >>.

=item * C<weights> (required): a scoring file (C<.txt> or C<.txt.gz>), read a line at a
time, or a data frame of one. It needs C<effect_allele> and C<effect_weight>,
and either C<chr_name> and C<chr_position> or, with C<< match =E<gt> 'id' >>, C<rsID>.
C<other_allele> is used when present. A harmonized file of the PGS Catalog
(C<..._hmPOS_GRCh38.txt.gz>) is read by C<hm_chr> and C<hm_pos> (or C<hm_rsID>)
instead, which are on the build its name gives. A variant marked TRUE in
C<is_haplotype>, C<is_diplotype>, C<is_interaction>, C<is_dominant> or
C<is_recessive>, or given a C<dosage_0_weight>, C<dosage_1_weight> or
C<dosage_2_weight>, dies, since only additive weights are scored.

=item * C<match>: C<position> (the default) finds each variant by chromosome and
position; C<id> finds it by rsID, in a VCF whose C<ID> column holds them. An
C<ID> of C<rs1;rs2> is found by either.

=item * C<build>: C<hg19> (or C<b37>) or C<hg38> (or C<b38>). PLINK 2 reads X only once
told where its pseudo-autosomal regions are, so a score with variants on X
or Y dies without it. Every sample is taken to be of unknown sex, which PLINK
2 counts a haploid call on X of as homozygous: 2 copies, 2 alleles.

=item * C<memory>, C<threads>: the MiB of memory (640 or more) and the CPUs PLINK 2
may use. By default it reserves half the machine's memory and uses every
CPU.

=back

Returns a hash ref keyed by sample, a hash of hashes that C<write_table> can
write, with these fields for each sample. A sample is named by its IID, so a
PLINK 2 fileset in which two samples share an IID, in different families, dies
rather than adding their scores together.

=over

=item * C<score>: the sum of the weights times the dosages, PLINK 2's C<SCORE1_SUM>.
PLINK 2 writes it to six significant figures, so it is good to about one
part in a million.

=item * C<average>: C<score> divided by C<alleles>, PLINK 2's C<SCORE1_AVG>, or undef
when C<alleles> is 0.

=item * C<variants>: the variants of C<weights> that were scored for this sample.

=item * C<alleles>: the alleles counted in their genotypes, PLINK 2's C<ALLELE_CT>:
2 for each diploid call.

=item * C<missing>: the variants that were not scored, because the VCF has no
record of them whose alleles agree, or because the sample's genotype is
missing (C<./.>, or partly missing, such as C<./1>). C<variants> and C<missing>
add up to the number of rows of C<weights>.

=item * C<mismatched>: of C<missing>, those at a position (or ID) the VCF has, whose
alleles disagree with the record's there.

=back

PLINK 2 by default fills a missing genotype in with the effect allele's
frequency in the samples; C<pgs_score> leaves it out.

How a variant is matched, which perl decides, a C<.pvar> line at a time,
before PLINK 2 scores:

=over

=item * Chromosomes are compared without UCSC's C<chr> prefix and in any case, and
PLINK's C<23>, C<24> and C<26> and UCSC's C<M> are taken as C<X>, C<Y> and C<MT>,
so C<chr1> in a VCF finds C<1> in a scoring file.

=item * A variant agrees with a record when its effect allele and its other allele
(if it has one) are both among the record's C<REF> and C<ALT> alleles, in any
case. A multi-allelic record counts the copies of whichever C<ALT> is the
effect allele, so a C<1/2> genotype of C<G> to C<A,T> holds one C<T>. Where two
records agree, as a multi-allelic site split in two can, the first in
C<CHROM:POS:REF:ALT> order is used.

=item * A record whose C<ALT> is C<.>, which a VCF of every site writes where the
sample matches the reference, agrees with a variant either of whose alleles
is its C<REF>; a C<0/0> there is two copies of the effect allele if it is the
C<REF>, and none otherwise.

=item * Alleles are not complemented, since a VCF and the PGS Catalog's files are
both on the forward strand. A variant written on the other strand
disagrees, and A/T and C/G variants, which read the same on either strand,
are matched as they are written.

=item * Only C<GT> is read: a dosage (C<DS>) or a genotype likelihood is not used.

=back

The positions in the scoring file have to be on the same genome build as the
VCF's, since a variant's position in GRCh37 (hg19) and in GRCh38 (hg38) differ;
rsIDs do not, so C<< match =E<gt> 'id' >> needs no build. Many scoring files say
C<genome_build=NR> (not reported), so C<pgs_score> cannot compare the builds.
The alleles say what it cannot: it warns when none of the variants was found
with alleles that agree, and when the alleles disagree at more than half of
the variants found. On 2026-10-17, PGS000138, whose header says
C<genome_build=NR>, was scored against a GRCh37 genome: 12,015 of its 22,274
variants were found, and the alleles agreed at every one, so its positions
are on GRCh37. With every position moved on one base, the alleles agreed at 9
of the 58 found.

A VCF that lists only the variants a sample carries (as most single-sample
VCFs from a sequencing service do: every genotype holds an C<ALT>) has no
record where the sample matches the reference, so those variants are
C<missing>, not scored as zero copies. PLINK 2 refuses such a file; C<pgs_score>
warns that its score is not comparable and scores it anyway. That genome above
was scored at 12,015 of PGS000138's 22,274 variants, and an exome at 701. A
score is comparable only with another scored on the same variants, so check
C<variants> before comparing samples; a VCF called jointly over many samples,
or one of every site, has far fewer missing. The reference blocks of a gVCF,
which cover a range of positions with one record, are not expanded.

PLINK 2 converts the whole of a VCF or BCF before it keeps the score's
positions, which for the 12 GB, 81-million-record BCF of 1000 Genomes took 294
s and 6.2 GB on 2026-10-17. Cut the positions out first with C<bcftools view
-R> (16 s), or convert such a reference once with C<plink2 --make-pgen> and
give C<pgs_score> the C<.pgen>: from a C<.pgen> of those positions, all 2,504
people were scored in under a second.

The PGS Catalog's search pages export a table of scores with a link to each
one's scoring file (C<depression.pgs_scores_data.csv>, for one). That table
has no weights, so C<pgs_score> cannot use it, but it can say which files to
download and score:

 use Stats::LikeR 'read_table';
 my $catalog = read_table('depression.pgs_scores_data.csv');
 foreach my $pgs (@{ $catalog }) {
     my ($file) = $pgs->{'Scoring File (FTP Link)'} =~ m{([^/]+)\z};
     next unless -f $file;
     my $s = pgs_score(vcf => 'genome.vcf.gz', weights => $file);
     printf "%s\t%s\t%g\t%d variants\n", $pgs->{'Polygenic Score ID & Name'}, $_, @{ $s->{$_} }{qw(score variants)}
         foreach sort keys %{ $s };
 }

=head2 Population genetics: pca, fst, hardy_weinberg, ld, ld_prune and gwas

Six functions of a cohort's genotypes, each of which hands them to
L<PLINK 2|https://www.cog-genomics.org/plink/2.0/>, which C<Alien::Bioinf>
installs, and returns what it computes as perl data. The genotypes are never
held in perl. What they share:

=over

=item * C<vcf> (required) is given as to C<pgs_score>: a C<.vcf>, C<.vcf.gz>,
C<.vcf.bgz> or C<.bcf> file, a PLINK 2 fileset given by its C<.pgen>, or a data
frame, as Stats::LikeR's C<read_table> returns one, whose genotypes are
columns named C<< E<lt>sampleE<gt>.GT >>.

=item * Only the biallelic variants on the autosomes (1 to 22) are read. A
multi-allelic record is left out, and so are X, Y and the mitochondrion,
which PLINK 2 reads only once told each sample's sex. A VCF with no
biallelic variant on the autosomes dies.

=item * Only C<GT> is read, and a genotype that is partly missing (C<./1>) is
missing.

=item * C<memory> and C<threads> are the MiB of memory (640 or more) and the CPUs
PLINK 2 may use, as for C<pgs_score>.

=item * A variant is returned as a hash of C<chrom>, C<pos>, C<id>, C<ref> and C<alt>,
plus what the function says. C<chrom> is PLINK 2's name for the chromosome,
1 to 22 without a C<chr> prefix, whatever the VCF calls it, and C<id> is the
VCF's C<ID>, C<.> included. Variants come in the VCF's order.

=item * Samples are named by their IIDs: a VCF's sample names, or a fileset's IIDs.
A fileset in which two samples share an IID, in different families, dies.
A fileset's C<.psam> may name each sample's parents, and PLINK 2 then counts
only the founders for allele frequencies and for C<hardy_weinberg>; a VCF
names none, so every sample is a founder.

=item * PLINK 2 prints its numbers to 6 significant figures, so that is what each
number returned is good to. A C<NA> or C<nan> of PLINK 2's is undef.

=back

The usual order is to prune first, and to compute principal components or Fst
on the variants kept, since PLINK 2's own help advises a set of variants in
approximate linkage equilibrium for C<--pca>, with no very rare ones. The
functions take no list of variants, so filter the VCF with the variants
C<ld_prune> keeps, or with C<bcftools view -i>, before handing it to the next.
In the 60 people of three populations of C<t/data/popgen.vcf>, variants
20 kb or more apart were still in strong linkage disequilibrium: 97 pairs of
210 such variants had an r² of 0.5 or more.

=head3 pca(%args)

The principal components of the samples, PLINK 2's C<--pca>: the leading
eigenvectors of the variance-standardized relationship matrix.

 my $p = pca(vcf => 'cohort.vcf.gz', n => 4);
 # { eigenvalues => [10.79, 6.01, 5.40, ...], variants => 270,
 #   samples => { NA06984 => [-0.0847, -0.0160, 0.0837, ...], ... } }

=over

=item * C<n>: how many components, 10 by default, as PLINK 2 has it.

=back

It returns a hash ref of C<eigenvalues> (an array, largest first), C<samples>
(each sample's components, an array in the eigenvalues' order), and
C<variants>, how many variants were read. A component's sign is arbitrary, as
an eigenvector's is. PLINK 2 needs 50 samples or more to estimate the allele
frequencies it standardizes by, and fewer die with its message. For more than
about 5,000 samples, PLINK 2's help advises its randomized algorithm (C<--pca
approx>), which this function does not use.

=head3 fst(%args)

Fst between every two populations, PLINK 2's C<--fst>.

 my $f = fst(vcf => 'cohort.vcf.gz', populations => { NA06984 => 'CEU', NA18486 => 'YRI', ... });
 print $f->{fst}{CEU}{YRI};   # 0.170396; and $f->{fst}{YRI}{CEU} is the same

=over

=item * C<populations> (required): a hash ref of sample => population. A sample of
the VCF that it leaves out is left out of the estimate, a sample it names
that the VCF lacks is ignored, and a population of none of the VCF's
samples is not counted. Two populations with samples are needed. A name may
be anything that is not empty, a number or a phrase with spaces included.

=item * C<method>: C<hudson> (the default, as in PLINK 2), the estimator of Bhatia,
Patterson, Sankararaman and Price (2013), or C<wc>, Weir and Cockerham's
(1984). Either is a ratio of averages over the variants.

=item * C<per_variant>: 1 also returns each variant's Fst; 0 (the default) does not.

=back

It returns a hash ref of C<method>, C<populations> (each population with
samples in the VCF, and how many), C<fst> (C<< { A =E<gt> { B =E<gt> Fst } } >>, given both
ways round), and C<variants>. C<variants> is undef unless C<per_variant> is 1,
and is then C<< { A =E<gt> { B =E<gt> [ variant, ... ] } } >>, one list for each pair,
given both ways round, with each variant's C<fst> (undef where it cannot be
estimated).

=head3 hardy_weinberg(%args)

Tests each variant's genotypes for Hardy-Weinberg equilibrium, by the exact
test of Wigginton, Cutler and Abecasis (2005), PLINK 2's C<--hardy>.

 my $h = hardy_weinberg(vcf => 'cohort.vcf.gz');
 # [ { chrom => 1, pos => 30028088, id => '.', ref => 'A', alt => 'G',
 #     hom_ref => 13, het => 23, hom_alt => 24,
 #     observed_het => 0.383333, expected_het => 0.483194, p => 0.113585 }, ... ]

=over

=item * C<midp>: 1 gives the mid-p (Graffelman and Moreno 2013), which is less
conservative; 0 (the default, as in PLINK 2) gives the exact test's own p.

=back

It returns an array ref of the variants, each with C<hom_ref>, C<het> and
C<hom_alt> (the samples called with each genotype), C<observed_het> and
C<expected_het> (the share of those samples that are heterozygous, and the
share Hardy-Weinberg proportions would give) and C<p>. All the samples are
tested together, so in a cohort of several populations a variant whose
frequency differs between them shows too few heterozygotes; test each
population's VCF alone for that.

=head3 ld(%args)

Linkage disequilibrium between every two variants of a chromosome within a
window, PLINK 2's C<--r2-unphased> or C<--r2-phased>.

 my $pairs = ld(vcf => 'cohort.vcf.gz', window_kb => 250, min_r2 => 0.8);
 # [ { a => { chrom => 22, pos => 20000428, ... }, b => { chrom => 22, pos => 20003731, ... },
 #     r2 => 0.287761, dprime => undef }, ... ]

=over

=item * C<window_kb>: the farthest apart two variants of a pair are, in kb; 1000 by
default, as in PLINK 2.

=item * C<window>: the most variants apart they are, 1 being adjacent variants; no
limit by default.

=item * C<min_r2>: the least r² of a pair returned, 0.2 by default, as in PLINK 2;
0 returns every pair in the window.

=item * C<phased>: 0 (the default) gives the r² of the two variants' allele counts
(genotype dosages), which needs no phase. 1 gives the r² of the haplotypes,
and D′, PLINK 2's C<--r2-phased>, which uses each genotype's phase where the
VCF gives it (C<0|1>). D′ is signed, positive where the two variants' major
alleles go together.

=back

It returns an array ref of pairs, each a hash of C<a> and C<b> (the two
variants), C<r2> and C<dprime> (undef unless C<phased> is 1). The pairs are
PLINK 2's, in the order of their first variant. On a whole genome with a low
C<min_r2> there are a great many; give a high one, or a smaller window.

=head3 ld_prune(%args)

The variants to keep so that no two in a window are in strong linkage
disequilibrium, PLINK 2's C<--indep-pairwise>: within each window, of two
variants whose r² is above C<r2>, one is removed, and the window then moves on.

 my $r = ld_prune(vcf => 'cohort.vcf.gz');   # windows of 50 variants, moved on 5, r² 0.5
 my %keep = map { ("$_->{chrom}:$_->{pos}" => 1) } @{ $r->{keep} };

=over

=item * C<window>: the variants in each window, 50 by default.

=item * C<window_kb>: a window in kb instead, which PLINK 2 moves on one variant at a
time. Give one of C<window> and C<window_kb>.

=item * C<step>: the variants the window moves on by, 5 by default, or 1 (the only
value PLINK 2 takes) with C<window_kb>.

=item * C<r2>: the r² above which one of two variants is removed, 0.5 by default.

=back

The defaults, 50, 5 and 0.5, are the example the PLINK 1.9 manual gives for
C<--indep-pairwise>; PLINK 2 requires a window and an r² and has no defaults
for them. It returns a hash ref of C<keep> and C<remove>, each an array ref of
variants, which between them hold every variant read. Like C<pca>, it needs 50
samples or more, and fewer die with PLINK 2's message; C<ld> does not.

=head3 gwas(%args)

Tests every variant for association with a phenotype, PLINK 2's C<--glm>: a
linear regression of a quantitative phenotype, or a logistic regression of a
case-control one, on each sample's count of the ALT allele (0, 1 or 2), with
any covariates.

 my $g = gwas(vcf => 'cohort.vcf.gz', phenotypes => 'pheno.tsv', phenotype => 'height',
              covariates => [qw(age sex PC1 PC2)]);
 my ($top) = sort { $a->{p} <=> $b->{p} } grep { defined $_->{p} } @{ $g->{variants} };
 print "$top->{chrom}:$top->{pos} beta $top->{beta} p $top->{p}\n";

=over

=item * C<phenotypes> (required): the phenotypes and covariates, one row for each
sample, as a tab-separated file whose first line is its header (it may
begin with C<#>, as PLINK 2's own files do), or as a data frame. A column
C<IID> (or C<#IID>) names each row's sample by the VCF's name for it. A value
that is empty, undef or C<NA> is missing, and a sample missing the phenotype
or a covariate is left out, as is a sample with no row.

=item * C<phenotype> (required): the column to test. Its values must be numbers.

=item * C<covariates>: an array ref of the columns to adjust for. A column of numbers
is a quantitative covariate, and any other is categorical, which PLINK 2
turns into an indicator for each value but one. A categorical value may not
hold whitespace. The principal components from C<pca> are the usual
covariates for ancestry; put them in C<phenotypes> as columns.

=item * C<model>: C<linear> or C<logistic>. By default a phenotype of exactly two
values, 1 and 2 (PLINK's control and case) or 0 and 1 (control and case),
is case-control and tested by logistic regression, and any other is
quantitative and tested by linear regression. C<logistic> takes only a
phenotype of those two kinds. PLINK 2 falls back on Firth's penalized
regression for a variant where the plain logistic regression does not
converge.

=back

PLINK 2 takes any column whose values are all 0, 1 and 2 as case-control,
reading a 0 as missing. A quantitative phenotype or covariate of those values
(a count of something, say) is therefore given to it with 3 added, which
changes no variant's test, since in a linear regression neither the slopes nor
their standard errors depend on where the phenotype's or covariates' zeroes
are. Quantitative covariates are standardized (PLINK 2's
C<--covar-variance-standardize>), which leaves the variants' tests as they are
too, and keeps a covariate of large values, such as a year, from making the
regression too ill-conditioned for PLINK 2 to solve.

It returns a hash ref of C<model> (C<linear> or C<logistic>), C<samples> (those
of the VCF that have a value of the phenotype) and C<variants>, an array ref
of the variants, each with:

=over

=item * C<beta>: the change in the phenotype for each copy of the ALT allele, or,
for a logistic regression, in its log odds, so that C<exp(beta)> is the odds
ratio.

=item * C<se>: the standard error of C<beta>.

=item * C<stat>: the t statistic (linear) or z statistic (logistic).

=item * C<p>: its p-value, not corrected for the number of variants tested (5e-8 is
the usual genome-wide threshold).

=item * C<n>: the samples in the regression.

=item * C<alt_freq>: the ALT allele's frequency among them.

=item * C<firth>: 1 where Firth's regression was used, and 0 otherwise.

=item * C<error>: undef, or PLINK 2's code (its C<ERRCODE>) for why the variant
could not be tested, when C<beta>, C<se>, C<stat> and C<p> are undef.

=back

=head2 admixture(%args)

Estimates each sample's ancestry as fractions of C<k> ancestral populations,
and each population's allele frequencies, by the model of
L<ADMIXTURE|https://dalexander.github.io/admixture/> (Alexander, Novembre and
Lange 2009): a sample's count of a variant's ALT allele is binomial, with the
probability its fractions give, averaged over the populations' frequencies.
Unlike the functions above, it needs no PLINK 2: C<Bioinf.xs> reads the VCF and
fits the model, by the EM algorithm of Tang et al. (2005), accelerated by
SQUAREM (Varadhan and Roland 2008).

 my $a = admixture(vcf => 'cohort.vcf.gz', k => 3);
 # { k => 3, loglik => -15257.557473, converged => 1, iterations => 234,
 #   starts => [-15257.557474, -15321.242788, ...],
 #   samples => { NA06984 => [0.544524, 0.000010, 0.455466], ... },
 #   variants => [ { chrom => 1, pos => 30028088, id => '.', ref => 'A', alt => 'G',
 #                   freq => [0.29, 0.94, 0.57] }, ... ] }

=over

=item * C<vcf> (required): a C<.vcf>, C<.vcf.gz>, C<.vcf.bgz> or C<.vcf.bz2> file, as
C<sex_check> takes. Only biallelic records on the autosomes (1 to 22) are
read, as for the functions above; a call of one allele, or with a missing
allele, is missing.

=item * C<k> (required): the ancestral populations, 2 or more, and fewer than the
samples. Which C<k> fits best is not chosen here; compare the fits of
several.

=item * C<starts>: the random starts fitted, 10 by default, of which the one with the
highest likelihood is kept. The likelihood has local maxima: on the 60
people of three populations in C<t/data/popgen.vcf>, ADMIXTURE 1.3.0 itself
stopped at the lesser of two from 2 of 6 seeds.

=item * C<seed>: start C<s> (counting from 0) is drawn from C<seed + s>; 1 by default.
The starts are drawn from integers alone, so a seed gives the same start on
every platform.

=item * C<tolerance>: a start stops when an iteration raises its log-likelihood by
less than this, 1e-10 by default. ADMIXTURE's own default is 1e-4, which is
too loose for EM steps, which creep where the likelihood is flat. On that
file, 1e-4 stopped 1.1e-3 below ADMIXTURE's maximum, with fractions 8e-4
from ADMIXTURE's; at 1e-8, starts that reached the log-likelihood to 1e-6
still had fractions up to 1.4e-4 from it; and at 1e-10 every start that
reached the greater maximum had every fraction within 1.9e-5, which is
ADMIXTURE's own precision. A looser tolerance is faster, and may serve on
a large file.

=item * C<max_iterations>: the iterations (of three EM steps each) after which a
start stops, 10,000 by default. When the best start stopped so, it warns.

=item * C<min_depth>: a genotype whose C<DP> is below this is missing; 0 (the
default) keeps every one.

=back

It returns a hash ref of C<k>, C<loglik> (the best start's log-likelihood, as
ADMIXTURE prints it, without the binomial coefficients), C<converged> (1 or
0), C<iterations>, C<starts> (each start's log-likelihood, in order),
C<samples> (each sample's fractions, an array of C<k> that sums to 1) and
C<variants> (each variant, with C<freq>, its ALT allele's frequency in each
population). The populations are unnamed, and come in the order of their
share of the samples, the largest first, so that two fits of the same data
give them in the same order. No fraction or frequency is below 1e-5 or above
1 - 1e-5, ADMIXTURE's bounds. A sample with no called genotype gets an even
share of each population, with a warning.

All the genotypes are held, a byte each, so a cohort of 1,000 people at a
million variants takes 1 GB. Prune the variants first, as ADMIXTURE's manual
(section 2.3) advises, since the model takes no account of linkage
disequilibrium; its example, C<plink --indep-pairwise 50 10 0.1>, is
C<< ld_prune(vcf =E<gt> $vcf, window =E<gt> 50, step =E<gt> 10, r2 =E<gt> 0.1) >>. Each iteration takes time in proportion to the
samples, the variants and C<k>, times the starts.

=head2 sex_check(%args)

Tells each sample of a VCF as male or female from its genotypes on X, by the
method of L<peddy|https://github.com/brentp/peddy>'s C<sex_check> (0.4.3): of
the SNVs on X outside its pseudo-autosomal regions, the ratio of heterozygous
calls to homozygous-ALT ones, which is near 0 for a male, whose one X can be
heterozygous only by error, and above 1 for a female. The file is
decompressed by perl and its lines counted in XS, which holds nothing but
seven counters for each sample, so that a whole genome costs about what
decompressing it does. It prints a report to STDOUT and returns the same
results as a hash:

 use Cn::Bioinf 'sex_check';

 my $sex = sex_check(vcf => 'genome.vcf.gz');
 my $same = sex_check('genome.vcf.gz');    # the file may come first, unnamed

prints

 sex_check: genome.vcf.gz
 male when het/hom-ALT, over SNVs on X outside its pseudo-autosomal regions, is below 0.6; genotypes of DP below 7 not counted
 sample  sex   het/hom-ALT  X het  X hom-ALT  X haploid  X missing  Y called
 genome  male        0.029   1990      68035          0          0      2746

with one row for each sample, in the VCF's order, and a last line counting
the samples whose sex is unknown, if any. It returns

 # { sample => { sex => 'male', het_ratio => 0.0292, x_het => 1990,
 #               x_hom_alt => 68035, x_hom_ref => 0, x_haploid => 0,
 #               x_missing => 0, y_called => 2746, y_alt => 2746 } }

On 2026-10-18 a 155 MB C<.vcf.gz> of a whole genome (3.5 million records)
took 4.8 s and 47 MB, where C<zcat> alone takes 3.7 s; the same file as a
C<.vcf.bz2> took 19.4 s, nearly all of it bzip2's.

=over

=item * C<vcf> (required): a C<.vcf>, C<.vcf.gz>, C<.vcf.bgz> or C<.vcf.bz2> file, the
suffix in any case. It may also be given first, without its name, as
C<sex_check($file)> or C<< sex_check($file, report =E<gt> 0) >>. A VCF may name its chromosomes C<chrX>, C<X> or C<23>
(and C<chrY>, C<Y> or C<24>); records on any other are skipped unread.

=item * C<cutoff>: a sample whose C<het_ratio> is below this is male, and otherwise
female. The default, 0.6, is peddy's. On five genomes the three males' ratios
were 0.029 (a whole genome), 0.103 and 0.201 (exomes), and the two
females' 1.660 and 1.712 (exomes); an exome's off-target calls make more
false heterozygotes than a genome's.

=item * C<min_depth>: a genotype whose C<DP> is below this is not counted. The
default, 7, is peddy's; 0 counts every genotype. A genotype with no C<DP>,
or a C<DP> of C<.>, is counted.

=item * C<report>: 1 (the default) prints the report; 0 prints nothing, and only
returns the results.

=back

What is counted, and where C<sex_check> differs from peddy:

=over

=item * X's pseudo-autosomal regions are taken as X:10000-2781479 and
X:154931044-156030895, peddy's bounds, which cover GRCh37's and GRCh38's,
so no build need be given. Y's are both builds' too.

=item * Only biallelic SNVs are counted: a record whose C<REF> or C<ALT> is not a
single base (an indel, a multi-allelic site, or an C<ALT> of C<.>, C<*> or
C<< E<lt>NON_REFE<gt> >>) is skipped, where peddy keeps an insertion. A record with no
C<GT> in its C<FORMAT> is skipped too.

=item * Every site is counted, where peddy stops at 10,000, and peddy's filters on
a site's call rate and ALT frequency across the cohort, which mean nothing
for one genome, are left out.

=item * A haploid call, as a caller that knows a sample is male writes it on X,
counts as homozygous: C<1> as hom-ALT, C<0> as hom-REF.

=item * A sample with no het or hom-ALT call on X has C<sex> and C<het_ratio> undef.
peddy divides by a hom-ALT count of 0 as if it were 1, and so would call
such a sample male. When the whole VCF has no SNV on X outside the
pseudo-autosomal regions, C<sex_check> also warns.

=back

Returns a hash ref keyed by sample, a hash of hashes that C<write_table> can
write, with these fields for each sample:

=over

=item * C<sex>: C<male>, C<female>, or undef.

=item * C<het_ratio>: C<x_het> divided by C<x_hom_alt> (by 1 when C<x_hom_alt> is 0),
or undef when both are 0.

=item * C<x_het>, C<x_hom_alt>, C<x_hom_ref>: the sample's heterozygous,
homozygous-ALT and homozygous-REF calls at the SNVs counted on X. A VCF
that lists only the sites where its sample carries an ALT allele has no
hom-REF calls.

=item * C<x_haploid>: of those, the haploid calls.

=item * C<x_missing>: the sample's calls there that were missing (C<./.>, C<.>,
partly missing, such as C<./1>, or cut short, such as C<1/>), or not a call of
one or two alleles of the record's two. A genotype left out by C<min_depth> is in no count.

=item * C<y_called>, C<y_alt>: the sample's calls at SNVs on Y outside its
pseudo-autosomal regions, and those of them that carry the C<ALT>. They
decide nothing: an exome of a woman had 530 called SNVs on Y, and one of a
man 659, since a short read from X often maps to Y. They show at most
whether Y was called at all.

=back

A BCF or a C<.pgen> is not read; convert it with C<bcftools view -Oz>.

=head2 parent(%args)

Tells whether two people are parent and child from their genotypes, and
returns 1 if they are and 0 if not. A child has one allele from each parent at
every site, so wherever a parent is homozygous the child carries that allele,
and the two are never opposite homozygotes (one hom-REF and the other
hom-ALT, which is called IBS0) except by a genotyping error. Genotypes cannot
tell which of the two is the parent, so C<child> and C<parent> may be given
either way round, with the same result. Paternity and maternity are this
together with the parent's sex, which C<sex_check> tells.

Over the autosomal biallelic SNVs where either of the two carries the ALT, a
pair is parent and child when the IBS0 rate (the share of those sites that are
IBS0) is below C<max_ibs0>, and the
L<KING|https://www.kingrelatedness.com/manual.shtml>-robust kinship
coefficient is from 0.177 to 0.354, KING's range for first-degree relatives.
Full siblings have that kinship too, but they share no allele by descent at a
quarter of sites, so they have opposite homozygotes there, and the IBS0 rate
tells them apart. One person sequenced twice, or identical twins, have a
kinship above 0.354, and are not parent and child.

The file is decompressed by perl and counted in XS, as for C<sex_check>. The
two people are either two samples of one VCF, or each the one sample of a VCF
of their own, as a sequencing company delivers it:

 use Cn::Bioinf 'parent';

 my $is = parent(child => 'child.vcf.gz', parent => 'father.vcf.gz');
 my ($same, $stats) = parent(vcf => 'family.vcf.gz', child => 'C', parent => 'F');

The first prints

 parent: child child.vcf.gz, parent father.vcf.gz
 parent and child (1): the IBS0 rate, 0.0030, is below 0.012, and kinship 0.2587 is from 0.177 to 0.354, as for first-degree relatives
 sites compared           150970  autosomal biallelic SNVs where either carries the ALT, DP 10 or more
   in both VCFs            98828
   in the child's alone    27645  the parent taken as hom-REF
   in the parent's alone   24497  the child taken as hom-REF
 IBS0                        458  opposite homozygotes
   child hom-ALT             305  and the parent hom-REF
   child hom-REF             153  and the parent hom-ALT
 IBS1                      76262  one allele shared
 IBS2                      74250  both alleles shared
 het in both               43727
 het                       82821  the child's, and 80895 the parent's
 hom-ALT                   43652  the child's, and 42430 the parent's
 kinship                  0.2587  KING-robust, between-family

and returns 1. On 2026-10-18 the exomes of one family, all three sequenced and
called together, gave:

 child, parent    sites compared  IBS0 rate  kinship  returned
 child, father           150,970     0.0030   0.2587         1
 child, mother           158,616     0.0020   0.2604         1
 father, mother          171,033     0.0810   0.0174         0

Each pair took 1.6 s. A genome against an exome took 7.3 s and 89 MB, and is
not to be trusted, for the reason under "Each sample's own VCF" below.

=over

=item * C<child>, C<parent> (required): without C<vcf>, the two VCF files, each of one
sample (C<.vcf>, C<.vcf.gz>, C<.vcf.bgz> or C<.vcf.bz2>, as for C<sex_check>);
with C<vcf>, the names of two of its samples.

=item * C<vcf>: a VCF that holds both samples.

=item * C<min_depth>: a genotype whose C<DP> is below this is not counted. The
default is 10; 0 counts every genotype. A genotype with no C<DP>, or a C<DP>
of C<.>, is counted. On the family above, counting every genotype gave the
parent and child pairs IBS0 rates of 0.254 and 0.215, as high as an
unrelated pair's, from calls of C<DP> 1 to 3 made off the exome's targets. A
C<min_depth> of 7 gave 0.0053 and 0.0037, and 10 gave 0.0030 and 0.0020,
keeping 92% of the sites of 7.

=item * C<max_ibs0>: the IBS0 rate a parent and child must be below. The default,
0.012, is L<peddy|https://github.com/brentp/peddy> 0.4.3's (C<ped_check>).
It lies between the parent and child rates above (0.002 to 0.005) and the
0.02 or so expected of full siblings, a quarter of the unrelated pair's 0.081.

=item * C<report>: 1 (the default) prints the report to STDOUT; 0 prints nothing.

=back

What is counted:

=over

=item * Only the autosomes, named C<1> to C<22> or C<chr1> to C<chr22>; X is left out,
since a father gives his X to a daughter and not to a son.

=item * Only biallelic SNVs: a record whose C<REF> or C<ALT> is not a single base, or
that has no C<GT>, is skipped.

=item * A call counts when it is diploid and of the record's C<REF> and C<ALT>, and
is not below C<min_depth>. A missing or partly missing call (C<./.>, C<./1>), a
haploid one, or one with an allele the site lacks leaves that site out.
So do sites where both are hom-REF, which say nothing about relatedness; a
cohort's VCF has a great many of them.

=back

Each sample's own VCF lists only the sites where its sample carries an ALT
allele, so a site that one file lacks is taken as hom-REF in that person, and
the two files are compared site by site, holding both in memory (8 bytes a
site, so about 30 MB for a genome). A position is left out when either file has more
than one SNV there (as after C<bcftools norm -m->), a call that does not count,
or a record of more than one C<ALT>, or when the two files give it different
C<REF> or C<ALT> alleles. The files may name and order their chromosomes
differently.

Taking a missing site as hom-REF is right only when the other file was
sequenced and called there too, so two VCFs from one pipeline are what this
compares well. A genome's VCF has millions of sites that an exome's lacks, and
two exome capture kits target different regions; either makes IBS0 out of
sites that one of the two never had sequenced. The report gives the sites in
each file alone for that reason, and C<parent> warns when one file has more
than twice as many as the other: the three pairs of the family above had
ratios of 1.13 at most, an exome of another kit had 3.0 to 13 against them,
and a genome against an exome 58 (with a kinship of -19.8). The difference
must also be 50 sites or more, which chance does not give (a ratio over 2 with
a difference of 50 has a chance of 4.8e-5 at most, were a site as likely to be
in either file alone), and 0.9% or more of the sites compared, since fewer
could not carry the parent and child above over C<max_ibs0> even if every one
were an opposite homozygote; so two VCFs that list every site and differ by 3
sites against 1 are not warned of. A VCF
that leaves out filtered calls has holes that look hom-REF too.

C<parent> dies, rather than return a 0 or 1 that it has no grounds for, when

=over

=item * fewer than 1,000 sites are compared, which at the unrelated pair's IBS0 rate
would hold 81 opposite homozygotes on average, 8 standard deviations above
the 12 that C<max_ibs0> allows (an exome gives about 150,000 and a genome 3
million);

=item * neither has a hom-REF call where the other carries the ALT, so that IBS0
cannot be seen. A VCF merged from VCFs that list only their own sample's
variants, as C<bcftools merge> writes it without C<-0>, is like that, with
C<./.> wherever a sample had no variant; give each sample's own VCF instead;

=item * either has no het call at the sites compared, so that no kinship can be
taken.

=back

In scalar context C<parent> returns 1 or 0. In list context it returns that and
a hash ref of what it was decided from, with the same fields on every return:

=over

=item * C<parent>: 1 or 0, as returned.

=item * C<relationship>: C<parent-child>, C<full siblings>, C<duplicate> (one person or
identical twins), C<second-degree>, C<third-degree> or C<unrelated>, by
KING's kinship ranges, with the IBS0 rate telling parent and child from
full siblings.

=item * C<kinship>: the KING-robust between-family estimate (Manichaikul et al. 2010,
I<Bioinformatics> 26:2867), which is what PLINK 2's C<--make-king-table>
gives, and which agreed with it exactly on the VCF of two of the exomes
above merged by C<bcftools merge -0>.

=item * C<ibs0_rate>: C<ibs0> divided by C<sites>.

=item * C<sites>: the sites compared, and of them C<in_both>, C<child_only> and
C<parent_only>: those in both own VCFs, in the child's alone and in the
parent's alone. With C<vcf>, every site is C<in_both>.

=item * C<ibs0>, C<ibs1>, C<ibs2>: the sites where the two share no allele, one, or
both; and C<ibs0> split into C<child_alt_parent_ref> and
C<child_ref_parent_alt>.

=item * C<het_het>: the sites where both are het; C<child_het>, C<parent_het>,
C<child_hom_alt> and C<parent_hom_alt>: each one's het and hom-ALT calls at
the sites compared.

=back

A BCF is not read; convert it with C<bcftools view -Oz>.

=head2 relatedness(@vcf, %args)

Tells how every two people are related, from their genotypes: each pair's
KING-robust kinship and its IBS0, IBS1 and IBS2 counts, as C<parent> takes them
for one pair, and from those a relationship (parent and child, full siblings,
one person twice, second- or third-degree relatives, or unrelated). Each
person's sex is told from X in the same reading, as C<sex_check> tells it, so
that the relationship can be named: C<father-son>, C<mother-daughter>,
C<brother-sister>, C<brothers>, C<sisters>, and so on. Genotypes alone cannot
tell which of a parent and child is the parent, but a third person often can,
and C<relatedness> says which when one does.

The people are either every sample of one VCF, or the one sample of each of
several VCFs, as a sequencing company delivers them:

 use Cn::Bioinf 'relatedness';

 my $family = relatedness('family.vcf.gz');              # every pair of its samples
 my $same   = relatedness('mom.vcf.gz', 'dad.vcf.gz', 'kid.vcf.gz', report => 0);
 my ($pairs, $samples) = relatedness(vcf => ['mom.vcf.gz', 'dad.vcf.gz']);

 print $family->{js}{dc}{category}; # father-son
 print $family->{dc}{js}{category}; # the same hash, so the same

The second prints

 relatedness: mom.vcf.gz, dad.vcf.gz, kid.vcf.gz
 KING-robust kinship over autosomal biallelic SNVs where either carries the ALT, genotypes of DP below 10 not counted; first-degree from 0.177 to 0.354, and of those, parent and child when the IBS0 rate is below 0.012; male when het/hom-ALT on X outside its pseudo-autosomal regions is below 0.6
 sample  sex     X het/hom-ALT  VCF
 mom     female          1.690  mom.vcf.gz
 dad     male            0.206  dad.vcf.gz
 kid     female          1.698  kid.vcf.gz
 sample  sample   sites  IBS0 rate  kinship  relationship
 mom     dad     171033     0.0810   0.0174  unrelated
 mom     kid     158616     0.0020   0.2604  mother-daughter (mom the parent)
 dad     kid     150970     0.0030   0.2587  father-daughter (dad the parent)

for the exomes of the family under C<parent>, and returns the same. Every
pair's counts are those C<parent> gives for it.

The VCFs are decompressed by perl and counted in XS. One VCF of several
samples is read a record at a time, keeping nothing but each pair's counters,
and each pair's counts are taken 64 sites at a time from bit masks of the
samples' genotypes; several VCFs of one sample each are held in memory, 8 bytes
a site, as C<parent> holds two, and opened one at a time. On 2026-10-19 the
three exomes above took 2.5 s and 30 MB, where C<parent> takes 1.6 s for one
pair of them. The 17 samples of the CEPH 1463 pedigree (peddy's
C<ceph1463.peddy.vcf.gz>, 20,000 sites) took 0.27 s. A made-up VCF of 1,000
samples and 20,000 sites took 5.3 s and 890 MB: the counting took 1.7 s and 96
MB, and nearly all the rest is the 499,500 hashes returned.

=over

=item * The VCFs are given first, as C<relatedness($file)> or
C<relatedness($file, $file2, ...)>, before any option, or as C<vcf>. Each is a
C<.vcf>, C<.vcf.gz>, C<.vcf.bgz> or C<.vcf.bz2> file, as for C<sex_check>. One VCF
must have two samples or more; each of several must have one, and no two the
same sample name, which is what each sample is known by.

=item * C<vcf>: a VCF, or an array ref of them, in place of giving them first.

=item * C<min_depth>: a genotype whose C<DP> is below this is not counted, on X as on
the autosomes. The default, 10, is C<parent>'s, for C<parent>'s reasons; 0
counts every genotype.

=item * C<max_ibs0>: the IBS0 rate that a parent and child must be below, which tells
them from full siblings. The default, 0.012, is C<parent>'s.

=item * C<report>: 1 (the default) prints the report to STDOUT; 0 prints nothing.

=back

What is counted is what C<parent> counts, for every pair: the autosomal
biallelic SNVs where either of the two carries the ALT, a site that one own VCF
lacks taken as hom-REF in that person, and a site left out of a pair for the
reasons given under C<parent>. Each person's sex is from SNVs on X outside its
pseudo-autosomal regions, as C<sex_check> tells it with its default C<cutoff>
(0.6), but with C<min_depth> as given here.

A pair's relationship is decided as C<parent> decides it: by KING's kinship
ranges, with the IBS0 rate telling parent and child from full siblings. Its
category names it from the two sexes:

=over

=item * A parent and child is C<father-son>, C<father-daughter>, C<mother-son> or
C<mother-daughter> when it is known which is the parent and both sexes are
known, with C<parent> or C<child> in place of a word whose sex is unknown
(C<parent-son>). When it is not known which is the parent, two men are
C<father-son> and two women C<mother-daughter> all the same, and a man and a
woman are C<parent-child>.

=item * Full siblings are C<brothers>, C<sisters> or C<brother-sister>, or
C<full siblings> when either's sex is unknown.

=item * Any other relationship is its own category: C<duplicate>, C<second-degree>,
C<third-degree> or C<unrelated>.

=back

Which of a parent and child is the parent is told by a third person: x is y's
parent when x has another child who is y's full sibling, or when y has another
parent who is unrelated to x (the two being y's parents). When neither is
said, or both, as in a pedigree that this reading cannot untangle, C<parent> is
undef. On CEPH 1463, three generations of 17 people, C<relatedness> agreed with
the pedigree on all 17 sexes and on 134 of the 136 pairs, including every
father, mother, son, daughter, brother and sister, and which of each parent
and child was the parent. The other two pairs were the grandson NA12893 with
his grandfather and with his grandmother, whose kinships of 0.0839 and 0.0799
are just under KING's 0.0884 for second-degree relatives, and so are
C<third-degree>.

Where C<parent> would die, C<relatedness> decides nothing about that pair and
goes on to the next: its C<relationship> and C<category> are undef and
C<undecided> says why, and C<relatedness> warns once, counting such pairs. That
is when fewer than 1,000 sites are compared, when neither has a hom-REF call
where the other carries the ALT (as in a VCF merged without C<-0>), or when one
has no het call, which leaves C<kinship> undef too. When several VCFs are
given, C<relatedness> also warns once about the pairs whose VCFs look
sequenced over different regions, as C<parent> warns about one.

In scalar context C<relatedness> returns a hash of hashes keyed by each sample
and then by each other sample, so that C<< $r-E<gt>{js}{dc} >> and C<< $r-E<gt>{dc}{js} >> are
the same pair, and the same hash: changing one changes the other. In list
context it returns that and a hash ref of the samples. A pair's hash has these
fields on every return:

=over

=item * C<relationship>: as C<parent> gives it (C<parent-child>, C<full siblings>,
C<duplicate>, C<second-degree>, C<third-degree> or C<unrelated>), or undef when
the pair is undecided.

=item * C<category>: the relationship named by sex, as above, or undef.

=item * C<parent>: the name of the one that is the parent, for a parent and child
where a third person says which; otherwise undef.

=item * C<undecided>: why the pair is undecided, or undef.

=item * C<kinship>: the KING-robust between-family estimate, or undef when either has
no het call. On C<t/data/parent.vcf> it agreed with PLINK 2's
C<--make-king-table> for all 21 pairs.

=item * C<ibs0_rate>: C<ibs0> divided by C<sites>, or undef when there are no sites.

=item * C<sites>: the sites compared, of which C<in_both> were in both VCFs, and
C<only>, a hash of each of the two samples, those in that sample's VCF alone.
With one VCF, every site is C<in_both>.

=item * C<ibs0>, C<ibs1>, C<ibs2>: the sites where the two share no allele, one, or
both; C<het_het>: those where both are het; C<het>, a hash of each of the two
samples: its het calls at the sites compared.

=back

C<parent>'s split of C<ibs0>, and each one's hom-ALT count, are left out, since
each hash of two numbers adds a third to a pair's memory; C<parent> gives them
for any one pair.

The samples' hash has, for each sample, what C<sex_check> returns for it
(C<sex>, C<het_ratio>, C<x_het>, C<x_hom_alt> and the rest), and C<file>, its VCF.

A BCF is not read; convert it with C<bcftools view -Oz>.

=head2 concordance(%args)

Compares the genotype calls of a VCF under test with those of a truth VCF,
sample by sample, and counts each kind of agreement and disagreement, as
C<x.low_ram_local_concordance.pl> did:

 use Cn::Bioinf 'concordance';

 my $r = concordance(truth => 'truth.vcf.gz', test => 'test.vcf.gz');
 print $r->{NA12878}{metrics}{genotype_concordance};
 foreach my $site (@{ $r->{NA12878}{discordances} }) {
     print "$site->{chrom}:$site->{pos} $site->{type}: test $site->{test}, truth $site->{truth}\n";
 }

This is based off of https://link.springer.com/article/10.1186/s12920-022-01199-8

Each of the test's samples is compared with the truth's sample of the same
name, and a sample in only one of the files is left out. When each file has
exactly one sample, the two are compared whatever they are called, so a run
named C<run42> can be compared with its truth C<NA12878>. When no sample can be
paired, C<concordance> dies and names some of each file's samples.

Every record of the test is compared with the truth's record of the same
CHROM, POS, REF and ALT. A C<chr> prefix on CHROM, in any case, is ignored, and
so is ID. When the truth has no such record, its call there is a no-call. A
site that the truth has and the test lacks is not compared at all, so the
test's sites are the ones measured, as for a genotyping panel against a
genome. A site whose ALTs are listed in another order, or split over two
records, is a different site.

The two files have to be on the same genome build, since a site's POS in
GRCh37 (hg19) is not the same place in GRCh38 (hg38). Before either file is
read, C<concordance> compares the lengths that their headers' C<##contig> lines
give, matching contigs by name without C<chr>, as sites are matched. It dies if
any contig that both give a length for has different lengths, and names the
contigs and the build each header gives (its C<assembly>, or else its
C<##reference>). hg19 and b37, whose chromosomes are the same lengths, pass. A
header with no C<##contig> lengths cannot be checked this way. When none of the
test's sites is in the truth, C<concordance> warns that the builds may differ.

On C<t/data/concordance.test.vcf> against C<t/data/concordance.truth.vcf> it
prints

 concordance: test concordance.test.vcf against truth concordance.truth.vcf
 each test site compared with the truth's of the same CHROM, POS, REF and ALT, a site the truth lacks being a no-call there; precision, recall and specificity are of genotypes
 sample  sites  in truth  concordant  discordant  gained  lost  concordance  precision  recall  specificity
 B          46        45          34          10       2     0       0.7674     0.9412  0.8889       0.9375
 A          46        45          11          32       2     1       0.2381     0.4286  0.4286       0.1111
 1 of the test's 3 samples are not in the truth: D

When the paired samples' names differ, a C<truth sample> column follows
C<sample>.

The VCFs are decompressed by perl and compared in XS. The test is read first,
and its sites are kept with their calls for the samples compared, about 100
bytes a site for one sample. Then the truth is read a record at a time and
looked up among them, so memory grows with the test, which is usually the
smaller file. On 2026-10-19, one exome compared against another (274,879 test
sites) took 1.9 s and 211 MB, or 1.7 s and 47 MB with C<< discordances =E<gt> 0 >>,
because most of that memory is the 163,376 discordant and gained sites
returned. A genome compared with itself (3.5 million sites) took 14 s and 362
MB, most of the time being gzip.

=over

=item * C<truth>, C<test>: the two VCFs, each a C<.vcf>, C<.vcf.gz>, C<.vcf.bgz> or
C<.vcf.bz2> file, as for C<sex_check>.

=item * C<min_depth>: a genotype whose C<DP> is below this is a no-call, in either
file. The default, 0, compares every genotype, as the script did. A C<DP>
that is absent or C<.> leaves the genotype compared.

=item * C<discordances>: 1 (the default) lists each discordant, gained and lost site
in C<discordances>; 0 only counts them, and leaves C<discordances> undef.

=item * C<report>: 1 (the default) prints the report to STDOUT; 0 prints nothing.

=back

A call is compared by its alleles, in either order and phased or not, so
C<1/0>, C<0|1> and C<0/1> are the same call. Each call is one of hom-REF
(C<0/0>), het-REF (C<0/1>), hom-ALT (C<1/1>, C<2/2>), het-ALT (C<1/2>),
haploid-REF (C<0>), haploid-ALT (C<1>), or a no-call. A missing call (C<.> or
C<./.>), a partly missing one (C<./1>), one of more than two alleles, and one
where FORMAT has no C<GT> are all no-calls. Each comparison, truth first, is one
of 45 kinds, the script's:

=over

=item * C<concordant_> and the class, when the two calls are the same:
C<concordant_hom_ref>, C<concordant_het_ref>, C<concordant_hom_alt>,
C<concordant_het_alt>, C<concordant_haploid_ref>, C<concordant_haploid_alt> and
C<concordant_no_call>.

=item * C<concordant_diploid_ref_to_haploid_ref> and
C<concordant_haploid_ref_to_diploid_ref>, for C<0/0> against C<0> and C<0>
against C<0/0>; C<concordant_hom_alt_to_diploid_alt> and
C<concordant_haploid_alt_to_hom_alt>, for C<1/1> against C<1> and C<1> against
C<1/1>.

=item * C<lost_site>, when the truth has a call and the test a no-call, and
C<gained_site>, when the test has a call and the truth a no-call.

=item * C<discordant_> and the two classes otherwise, as in
C<discordant_het_ref_to_hom_alt> (C<0/1> in the truth, C<1/1> in the test).
Two different calls of the same class are discordant too, as in
C<discordant_het_ref_to_het_ref> (C<0/1> against C<0/2>).

=back

C<concordance> returns a hash keyed by the test's name for each sample
compared. Each sample's hash has these fields on every return:

=over

=item * C<test_sample>, C<truth_sample>: the sample's name in each file.

=item * C<sites>: the test's records, every one compared; C<in_truth>: how many of them
the truth has.

=item * C<counts>: a hash of the 45 kinds, each with its count, 0 included.

=item * C<metrics>: a hash of the script's metrics, taken from C<counts>:

=over

=item * C<tp_site>: the matched calls that carry an ALT: C<concordant_het_ref>,
C<concordant_het_alt>, C<concordant_hom_alt>, C<concordant_haploid_alt>,
C<concordant_hom_alt_to_diploid_alt> and
C<concordant_haploid_alt_to_hom_alt>. C<tp_genotype> is the same number.

=item * C<fp_site>: C<gained_site>; C<fn_site>: C<lost_site>.

=item * C<tn_site>: the matched reference calls: C<concordant_hom_ref>,
C<concordant_haploid_ref>, C<concordant_diploid_ref_to_haploid_ref> and
C<concordant_haploid_ref_to_diploid_ref>. C<tn_genotype> is the same
number.

=item * C<fp_genotype>: the discordances where the test's call carries an ALT,
whether the truth's is a reference call or another ALT-carrying call;
C<fn_genotype>: those where the truth's call carries an ALT, whether the
test's is a reference call or another ALT-carrying call. A discordance of
two ALT-carrying calls, such as C<0/1> against C<1/1>, is thus counted in
both, since the test's call is wrong and the truth's is missed.

=item * C<genotype_concordance>: the concordant comparisons, less
C<concordant_no_call>, over every comparison but C<concordant_no_call>,
C<gained_site> and C<lost_site>.

=item * C<precision_site>: C<tp_site / (tp_site + fp_site)>; C<recall_site>:
C<tp_site / (tp_site + fn_site)>; C<precision_genotype>:
C<tp_genotype / (tp_genotype + fp_genotype)>; C<recall_genotype>:
C<tp_genotype / (tp_genotype + fn_genotype)>; C<specificity_genotype>:
C<tn_genotype> over C<tn_genotype> and those of C<fp_genotype> where the
truth is a reference call, since only those truths are negatives. Each
ratio is undef when its
denominator is 0, where the script gave the string C<undefined>.

=back

=item * C<discordances>: an array ref of the discordant, gained and lost sites, in the
test's order, each a hash of C<chrom>, C<pos>, C<id>, C<ref> and C<alt> as the
test has them, C<type> (the kind), and C<test> and C<truth>, the two calls as
GT writes them, or C<.> for a no-call; or undef with C<< discordances =E<gt> 0 >>.

=back

Four of the metrics are corrected from the script's. Its C<tp_site> pattern,
C</^conc\w+(?:alt|hom)/>, matched the C<hom> in C<concordant_hom_ref>, so a
hom-REF site was a true positive as well as a true negative, and it missed
C<concordant_het_ref>, the commonest true positive. Its C<tn_site> missed
C<concordant_diploid_ref_to_haploid_ref>, though it took the reverse. And its
C<tn_genotype> was C<concordant_hom_ref> alone, though its false positives
counted a haploid-REF truth called wrong, so C<specificity_genotype> gave no
credit for one called right, as on a male's X. And it counted a discordance
of two ALT-carrying calls in neither C<fp_genotype> nor C<fn_genotype>, so that
a wrong genotype at a variant site changed neither C<precision_genotype> nor
C<recall_genotype>.

C<concordance> departs from the script where the script failed. The script
took ID as part of a site, and dropped C<chr> from the truth's CHROM alone, so
two files that both had it shared no site. It compared GT strings, and so died
on C<1/0>, C<0|1>, C<./1> and calls of three alleles. And it made a no-call
against C<.> C<discordant_no_call_to_no_call>, outside its own 45 kinds. Its XLSX workbook,
JSON files and ACMG59 column are left to the caller, who has everything they
were made from.

C<concordance> warns when the test has no records, and when none of the test's
sites is in the truth, which usually means two genome builds, or two naming
schemes for the chromosomes other than C<chr>.

A BCF is not read; convert it with C<bcftools view -Oz>.

=head2 blood_type(%args)

Tells each sample's ABO blood group and whether it is RhD positive or
negative from a VCF, with the genotype behind each:

 use Cn::Bioinf 'blood_type';

 my $b = blood_type(vcf => 'exome.vcf.gz');
 print $b->{NA12878}{type};               # A+
 print $b->{NA12878}{abo}{genotype};      # AO
 print $b->{NA12878}{rhesus}{phenotype};  # positive

and prints

 blood_type: exome.vcf.gz
 ABO from rs8176719 (O's deletion), rs8176746 (B) and rs41302905 (O2); RhD from 15 sites of RHD, or a record of the gene's deletion; matched by position on b37; genotypes of DP below 7 not counted
 sample   type  ABO  ABO genotype  RhD       RhD genotype  RHD sites
 NA12878  A+    A    AO            positive  D.                 2/15
 "RHD sites" is how many of the sites the sample has an ALT allele at; one is enough for RhD positive
 not in the file, and taken as homozygous for the reference allele: rs8176746, rs41302905, 13 of the 15 RHD sites

with one row for each sample, in the VCF's order.

B<This is not a blood test, and must not be used to choose blood for a
transfusion or for any other clinical purpose.> It reads the common alleles
and nothing else: a weak or partial D, an I<RHD> gene that is present but does
not work (the I<RHD> pseudogene, common in people of African ancestry, makes
somebody RhD negative whom this calls positive), a hybrid of I<RHD> and I<RHCE>,
the A2 and other subgroups, cis-AB and the rare O alleles are all outside it.

An exome's 22 MB C<.vcf.gz> took 0.8 s and 20 MB, and a whole genome's 155 MB
6.1 s and 47 MB (perl 5.44.0, 2026-11-10). The markers are in
C<share/blood_type_panel.tsv>, which C<share/make_blood_type_panel.pl> writes;
its header comment says where each comes from, and the module never runs it.

=head3 ABO

Three markers are read. C<rs8176719> is the single-base deletion that makes the
common O alleles; the reference genome carries the deletion, on GRCh37 and on
GRCh38, so a VCF writes a working gene there as an insertion, and a chromosome
with that insertion is A or B. C<rs8176746> is one of the changes that make
the B enzyme, and C<rs41302905> is the O2 allele, an O with no deletion, which
would otherwise be read as A. So a chromosome without the insertion is O,
whatever else it carries; one with it is B with C<rs8176746>'s T, O with
C<rs41302905>'s T, and otherwise A. The genotype is the two letters, A before B
before O (C<AO>, C<BO>, C<AB>, C<OO>), and the phenotype is what they make: C<A>,
C<B>, C<AB> or C<O>.

The genotypes are not phased, so somebody heterozygous at both C<rs8176719>
and C<rs8176746> is read as C<BO>, the B allele being taken to be on the
chromosome with the working gene. Of the 5,008 haplotypes of 1000 Genomes'
phase 3, 721 carried both and 44 the B allele without the insertion, which
makes that reading right 98.1% of the time.

Checked against 1000 Genomes on 2026-11-10: the ABO genotype read from phase
3's calls on GRCh37 and the one read from the New York Genome Center's 30x
resequencing of the same people, called afresh on GRCh38, were the same for
all 2,504 of them.

=head3 RhD

Most people who are RhD negative have no I<RHD> gene on either chromosome, and
a VCF of SNVs has no record for a gene that is not there. C<blood_type> reads
it in one of two ways.

Where the file has a record of a deletion that covers the whole gene, as 1000
Genomes' phase 3 does (C<< 1:25592642 E<lt>CN0E<gt> >>, C<END=25661222>), the sample's
genotype there is the answer: C<DD>, C<Dd> or C<dd>. A deletion is an ALT of
C<< E<lt>CN0E<gt> >>, C<< E<lt>DELE<gt> >> or C<< E<lt>DEL:...E<gt> >>, and has to start at or before the gene and
end, by C<END> or C<SVLEN>, at or after it.

Otherwise it reads 15 sites inside the gene at which the reference genome
carries a rare allele, so that almost everybody who has the gene has an ALT
call there, and nobody without it has. One such call makes a sample RhD
positive, written C<D.>, since SNVs cannot say whether the second chromosome
has the gene too: the ratio of heterozygous to homozygous-ALT calls inside the
gene, which tells sex on X, got a tenth to a quarter of 2,343 people wrong at
any cutoff. No such call makes a sample C<dd>, RhD negative, as long as it has
a genotype at one site at least: a call, or a site the file has no record of
that is read as REF (see below). A sample whose calls at every site are
missing, are not diploid, or have a DP below C<min_depth> has no RhD type.

The sites were chosen, and counted, in 1000 Genomes: the 30x calls of the
2,493 people whose deletion genotype phase 3 gives. Of the 150 with no gene,
none had a call at any of the 15; of the 2,343 with one or two, 5 had a call
at none, and so are called negative, and 2 at only one. Choosing the sites
on a random half of the people and counting on the other half chose the same
15 and gave the same counts.

An exome sees little of this: the capture kit of the three exomes tried
reached 2 of the 15 sites, at a depth of 13. The types of those three are
known from the depth of their reads: two cover I<RHD>'s exons at a mean depth
of 3 and 2 against 90 and 97 over I<RHCE>'s, and the third at 30 against 84;
C<blood_type> called them negative, negative and positive. A kit that reaches
none of the 15 sites would call everybody
negative, and C<carried> and C<listed>, below, are returned so that an answer
from few sites can be seen for what it is.

=head3 A marker the file has no record of

A VCF of one person usually lists only the sites where that person carries an
ALT allele, so that somebody who is OO, or has no B allele, or has no I<RHD>
gene, simply has no record at those markers. By default a marker with no
record is therefore read as homozygous for the reference allele, and each
answer says which markers that was done for. Two things are not read that
way, because the file could not have held the record:

=over

=item * a marker on a chromosome the file has no record on at all;

=item * C<rs8176719>, an insertion, in a file with no allele longer than one base on
chromosome 9. Such a file holds SNVs only, and reading the insertion's
absence as REF would call everybody O; no ABO type is given, and C<why> says
so.

=back

A file of every site, a cohort's, or a genotyping array's does have a record
where a sample is homozygous REF, and C<< assume_ref =E<gt> 0 >> makes a marker with
no record a marker with no genotype.

=head3 Arguments

=over

=item * C<vcf> (required): a C<.vcf>, C<.vcf.gz>, C<.vcf.bgz> or C<.vcf.bz2> file. As
C<sex_check> does, it may be given first and on its own:
C<blood_type('genome.vcf.gz')>.

=item * C<assume_ref>: 1 (the default) reads a marker the file has no record of as
homozygous for the reference allele, as above; 0 leaves it without a
genotype.

=item * C<build>: C<hg19>, C<b37>, C<hg38> or C<b38>, saying which of the panel's two sets
of coordinates to match on. By default it is read from the VCF's C<##contig>
lengths, as C<hirisplex_genotypes> reads it, and C<blood_type> dies asking for
it when the header gives no length it knows.

=item * C<min_depth>: a genotype whose FORMAT C<DP> is below this is not counted.
Defaults to 7, which is C<sex_check>'s and the depth the RhD sites were chosen
at; 0 counts every call whatever its depth. A genotype with no C<DP> is
always counted.

=item * C<report>: 1 (the default) prints the table to STDOUT; 0 returns the answers
only.

=back

=head3 What it returns

A hash ref keyed by sample name, each holding:

=over

=item * C<type>: the two together, as C<A+> or C<O->, or C<undef> when either is not
known.

=item * C<abo>: a hash ref of

=over

=item * C<genotype> and C<phenotype>: as above, or C<undef>;

=item * C<markers>: a hash ref of rs number => 0, 1 or 2 copies of the allele
counted, or C<undef> where the sample has no genotype;

=item * C<assumed_ref>: an array ref of the markers the file has no record of
that were read as homozygous REF;

=item * C<why>: C<undef>, or why no type could be given.

=back

=item * C<rhesus>: a hash ref of

=over

=item * C<genotype>: C<DD>, C<Dd> or C<dd> from a record of the deletion; C<D.> or
C<dd> from the sites; or C<undef>;

=item * C<phenotype>: C<positive>, C<negative> or C<undef>;

=item * C<basis>: C<deletion> or C<sites>, saying which of the two it was read
from, or C<undef>;

=item * C<sites>, C<listed> and C<carried>: how many RhD sites the panel has, how
many of them the file has a record of, and at how many this sample has
an ALT allele;

=item * C<deleted>: the copies of the deletion the sample has, 0 to 2, or C<undef>
when the file has no record of it that calls the sample;

=item * C<why>: C<undef>, or why no type could be given.

=back

=back

A genotype is counted only when the call is diploid and complete, as
C<hirisplex_genotypes> counts one. C<blood_type> warns when the file has no
record on chromosome 1 or on chromosome 9, which usually means the wrong
build.

=head2 hirisplex_genotypes(%args)

Reads the 41 markers of the HIrisPlex-S eye, hair and skin colour panel out of
a VCF, counting for each sample how many copies of each marker's model allele
it carries, and can write them as the CSV the HIrisPlex-S webtool uploads:

 use Cn::Bioinf 'hirisplex_genotypes';

 my $g = hirisplex_genotypes(vcf => 'genome.vcf.gz', file => 'hirisplexs.csv');
 print $g->{NA12878}{genotype}{'rs12913832_T'};  # 0, 1, 2, or undef
 print scalar @{ $g->{NA12878}{missing} }, " markers missing\n";

B<< This distribution ships no prediction model, and C<hirisplex_genotypes> makes
no prediction. >> The HIrisPlex-S regression coefficients are not published:
Chaitanya et al. (2018) cite them by reference rather than tabulating them,
the webtool offers no download and says that no part of it may be reproduced
without consent, and part of the knowledge behind it is covered by European
patent EP2195448. What is public, and what this function uses, is the panel
itself -- which markers, in which order, and which allele each model counts --
taken from the webtool's own input form. So C<hirisplex_genotypes> prepares the
input, and the prediction is made either at
L<the webtool|https://hirisplex.erasmusmc.nl/> or by C<trait_predict> from a
model table you hold yourself.

=head3 The panel

C<share/hirisplex_s_panel.tsv> holds the panel: each marker's rs number, gene,
the allele the model counts, its positions on GRCh37 and GRCh38, and whether
it belongs to the 6-marker IrisPlex and 24-marker HIrisPlex subsets.
C<share/make_hirisplex_panel.pl> writes that file from the webtool's form and
Ensembl, and its header comment says how to re-run it; the committed file is
what is used, and the generator is never run by the module.

The webtool asks for a count of the allele on the assay's strand, which is not
always the strand a VCF is written on, and the panel records the forward-strand
allele to count for each marker so that nothing has to be guessed at run time.
Fourteen of the 41 are counted as the complement of the allele the webtool
names. One, ASIP C<rs6119471>, carries the named allele on the forward strand
I<and> still has to be flipped -- the HIrisPlex-S manual singles it out as "the
only SNP that may cause confusion and therefore must be converted (from NCBI's
forward orientation)" -- so a tool that simply matched the named allele would
silently count the wrong one. MC1R C<rs312262906> is not a SNP but the 86insA
frameshift, merged in dbSNP into C<rs796296176>; it is counted as the C<ALT>
that is C<REF> with one C<A> put in (C<A> to C<AA>, or C<AA> to C<AAA> as GRCh38
writes it), so that an MNV or a symbolic C<< E<lt>INSE<gt> >> at that position is not taken
for it, and matching by rs number looks for both numbers. Bases are compared
regardless of case.

=head3 Arguments

=over

=item * C<vcf> (required): a C<.vcf>, C<.vcf.gz>, C<.vcf.bgz> or C<.vcf.bz2> file. As
C<sex_check> does, it may be given first and on its own:
C<hirisplex_genotypes('genome.vcf.gz')>.

=item * C<match>: C<position> (the default) matches CHROM and POS against the panel's
coordinates; C<id> matches the ID column against the markers' rs numbers,
which finds nothing in a VCF whose ID column is C<.>. An ID of several
names, separated by semicolons as the VCF specification has them, matches
when any of them is a marker's.

=item * C<build>: C<hg19>, C<b37>, C<hg38> or C<b38>, saying which of the panel's two sets
of coordinates to match on. By default it is read from the VCF's C<##contig>
lengths, and C<hirisplex_genotypes> dies asking for it when the header gives
no length it knows, or lengths that are neither build's.

=item * C<min_depth>: a genotype whose FORMAT C<DP> is below this is not counted.
Defaults to 7, C<sex_check>'s default; 0 counts every call whatever its depth.
A genotype with no C<DP> is always counted.

=item * C<file>: write the webtool's CSV here. Its header is that of the webtool's own
template, column for column, and a marker with no genotype is written C<NA>.

=item * C<report>: 1 (the default) prints a table of the samples to STDOUT; 0 returns
them only.

=back

=head3 What it returns

A hash ref keyed by sample name, each holding:

=over

=item * C<genotype>: a hash ref keyed as the webtool's CSV heads its columns,
C<< E<lt>rs numberE<gt>_E<lt>input alleleE<gt> >>, holding 0, 1 or 2 copies of that allele, or
C<undef> where the sample has no usable call.

=item * C<missing>: an array ref of the rs numbers with no genotype, in the panel's
order.

=item * C<markers> and C<called>: how many markers the panel holds, and how many this
sample has a genotype for.

=item * C<eye>, C<hair>, C<skin>: 1 or 0, whether the HIrisPlex-S rules allow that
prediction from these markers at all. The manual refuses an eye prediction
without HERC2 C<rs12913832>, a hair prediction when all 11 MC1R markers are
missing, and both when HERC2, SLC45A2 and IRF4 are all missing, because the
loss in AUC is too great. It sets no such rule for skin, so C<skin> is 0 only
when nothing at all was called. C<trait_predict> honours these.

=back

A genotype is counted only when the call is diploid and complete: a C<./.>, a
C<./1>, a haploid call (the panel is autosomal) or one below C<min_depth> leaves
the marker without a genotype. A site split into one record per ALT is counted
from whichever record carries the counted allele, in either order, and a record
at a marker's position whose REF is longer than one base is some other variant
and is passed over.

C<hirisplex_genotypes> warns when the file holds none of the 41 markers, which
usually means the wrong build or an ID column of C<.>.

Reading the markers is done in XS, in one pass, keeping one byte per sample per
marker, so a whole-genome VCF costs no more memory than a small one. A
275,879-record exome of 22 MB gzipped took 0.86 s (perl 5.44.0, 2026-10-20).

Most of the panel is intronic or intergenic, so an exome carries little of it:
that same exome held 9 of the 41 markers. A whole-genome VCF, a genotyping
array that covers the panel, or the SNaPshot assay the panel was designed for
is what the prediction expects, and C<missing> and C<called> are returned so that
a prediction made from a handful of markers can be seen for what it is.

=head2 trait_predict(%args)

Applies a multinomial logistic regression -- which is what the HIrisPlex-S,
HIrisPlex and IrisPlex models are -- to genotypes, and returns a probability
for each category of each trait:

 use Cn::Bioinf qw(hirisplex_genotypes trait_predict);

 my $g = hirisplex_genotypes(vcf => 'genome.vcf.gz', report => 0);
 my $p = trait_predict(genotypes => $g, model => 'my_model.tsv');
 print $p->{NA12878}{eye}{call};          # the most probable category
 print $p->{NA12878}{eye}{p}{blue};       # its probability

The model is yours to supply: see C<hirisplex_genotypes> above for why this
distribution ships none. Any model written in the form below works, so this is
not limited to pigmentation.

=head3 The model table

A tab-separated file (optionally gzipped), or a data frame as
C<Stats::LikeR>'s C<read_table> returns, with four columns:

 trait    category    marker    beta
 eye    blue    (intercept)    3.94
 eye    blue    rs12913832_T    -4.81
 eye    brown    (intercept)    0

C<marker> is a key of the C<genotype> hash C<hirisplex_genotypes> returns, which
is C<< E<lt>rs numberE<gt>_E<lt>input alleleE<gt> >>, or the literal C<(intercept)> for the
category's intercept. A category whose only row is an intercept of 0 is the
reference category, which is how a model of I<k> categories is written with
I<k> - 1 sets of betas; every category that should appear in the result needs at
least one row. Traits and their categories come out in the order the table
first names them. A frame's rows and columns must be of one length, as
C<pgs_score>'s must, and a gzipped file that ends early dies.

For each category the linear predictor is its intercept plus the sum of its
betas times the genotypes, and the probabilities are C<exp> of those over their
sum. The largest is taken out before C<exp>, so a linear predictor large enough
to overflow gives 1 rather than a NaN.

=head3 Arguments

=over

=item * C<genotypes> (required): what C<hirisplex_genotypes> returned, or a plain hash
ref of sample => { marker => 0, 1 or 2 }. A dosage may be any number from 0
to 2, as imputation gives, and C<undef> is no genotype; anything else, C<NA>
included, dies naming the sample and the marker. Only the markers the model
uses are looked at.

=item * C<model> (required): the table above, as a file name or a data frame.

=item * C<force>: 0 (the default) makes no prediction for a trait that the genotypes
say cannot be predicted -- that is, where C<hirisplex_genotypes> set C<eye>,
C<hair> or C<skin> to 0; 1 predicts it anyway. A trait the genotypes say
nothing about is always predicted.

=item * C<report>: 1 (the default) prints a table of the samples to STDOUT; 0 returns
them only.

=back

=head3 What it returns

A hash ref keyed by sample and then by trait, each holding:

=over

=item * C<p>: a hash ref of category => probability, which sum to 1; empty when the
prediction was refused.

=item * C<call>: the most probable category, or C<undef> when it was refused. A tie is
broken by the category's name, so the answer does not depend on hash order.

=item * C<markers> and C<called>: how many markers the trait's categories use between
them, and how many this sample has a genotype for.

=item * C<missing>: an array ref of the markers the model names and the sample has no
genotype for.

=item * C<refused>: C<undef>, or why no prediction was made.

=back

A marker the sample has no genotype for drops out of the sum, which is the same
as counting it 0 copies of the counted allele. That is a choice, not something
the HIrisPlex-S authors specify, and it biases the result towards whatever 0
copies means for that marker; C<missing> and C<called> are returned so that a
prediction made from few markers can be reported as such. The webtool reports a
loss in AUC for exactly this reason.

=head2 plot_msa(%args)

Aligns sequences with Clustal Omega and draws the alignment. Returns a hash ref
of the files made: C<filename>, C<msa_file>, C<python_file> (see C<fh> and
C<execute> below), and C<tree_file> if it was given. Once the image is written it
prints C<wrote> and its file name to STDOUT, the name in black on yellow when
STDOUT is a terminal; with C<< execute =E<gt> 0 >> it prints C<will write> instead.

 plot_msa(
     fasta      => 't/data/DEG20010421.fa',
     filename   => 'DEG20010421.msa.svg',
 );

=over

=item * C<fasta>, C<filename> (required): the sequences, as a FASTA file name or a
hash ref of name => sequence (the function tells the two apart by whether it
is a reference); and the image to draw, whose extension picks the format.
A name may hold spaces and punctuation: Clustal Omega is given the sequences
as C<s1>, C<s2> and so on, and the alignment and tree it writes get their
names back, in UTF-8. In the tree, a name with whitespace or any of
C<()[]':;,> in it is quoted as newick quotes one, as C<'it''s (x:1)'>.

=item * C<msa_file>, C<tree_file>: where to keep clustalo's alignment (FASTA; a
temporary file otherwise) and its guide tree (newick; not made otherwise).
Keep the tree to draw it with C<plot_phylo> without aligning a second time.

=item * C<order>: names, first to last (default: the input order; for a hash,
sorted). Only these are drawn, and the first is drawn at the bottom.

=item * C<labels>: a hash ref of name => label to show instead. matplotlib mathtext
works: C<< 'C.albicans' =E<gt> '$\it{C. albicans}$' >>. Two sequences drawn under one
label die, since they would be one row of the image.

=item * C<active_site_aa>, C<query>: C<< { His395 =E<gt> 395, ... } >>, a dashed vertical line
at each of these 1-based residue numbers of the sequence named by C<query>.
A number below 1 dies.

=item * C<tooltips>: 1 to give each residue a tooltip, which a browser shows when
the pointer rests on it, naming the sequence, the residue and its number
in that sequence, and the alignment column, as
C<S.cerevisiae: Lys100, alignment column 105> (default 0). The sequence is
named as it was given, not by its label. Only SVG carries tooltips, so
C<filename> must end in C<.svg>. Each residue is an element of the SVG, so a
large alignment makes a large file.

=item * C<title>, C<xlabel>, C<ylabel>, C<threads>, C<clustal_args>: the plot title; the
axis labels (default "Amino Acid Residue" and "Protein & Species");
clustalo threads (default 1); and an array ref of extra clustalo arguments.

=item * C<fh>, C<execute>: as for Matplotlib::Simple's C<plt>. The image is drawn by a
Python script, and C<fh> is a C<File::Temp> object to append that script to;
without it, the script goes in a new temporary file. C<execute> is 1 (the
default) to run the script now, under Alien::Bioinf's Python, or 0 only to
write it. So several calls with one C<fh> and C<< execute =E<gt> 0 >>, then a last one
with C<< execute =E<gt> 1 >>, draw every image in one run of Python. The C<fh> may be
one that Matplotlib::Simple's C<plt> also writes to, since the Python each
function appends stands alone. Clustal Omega runs either way; only the
drawing waits.

C<python_file> is the script's file name: C<fh>'s, or the temporary file's,
which is kept after perl exits only when C<execute> is 0. The script carries
the alignment and everything else it reads, so it can be run later, with
C<< perl -MAlien::Bioinf -e 'print Alien::Bioinf-E<gt>python' >> giving the Python to
run it with, after perl's own temporary files have gone.

=back

With fewer than two sequences it warns and returns an empty hash ref.

=head2 plot_phylo(%args)

Draws a guide tree, with Biopython's C<Bio.Phylo>, from a FASTA (aligned with
Clustal Omega first) or from a newick file that C<plot_msa> kept. Returns a
hash ref of the files made or used: C<output_file>, C<python_file>, and
C<tree_file> and C<msa_file> as below.

 plot_phylo(fasta => 't/data/DEG20010421.fa');   # writes phylo.svg
 plot_phylo(
     tree_file   => 'DEG20010421.newick',
     output_file => 'DEG20010421.tree.png',
 );

=over

=item * C<output_file>: the image to draw (default C<phylo.svg>, in the working
directory); the extension picks the format.

=item * C<fasta>, C<tree_file>: with C<fasta> (as for C<plot_msa>), the sequences are
aligned with Clustal Omega and the guide tree drawn; C<tree_file> and
C<msa_file> then say where to keep the tree and alignment, and C<threads> and
C<clustal_args> are as for C<plot_msa>. Without C<fasta>, C<tree_file> is an
existing newick file to draw, such as one C<plot_msa> kept, and no alignment
is made.

=item * C<labels>, C<title>: a hash ref of name => label for the tips, as for
C<plot_msa>; and the plot title.

=item * C<fh>, C<execute>: as for C<plot_msa>, which can share an C<fh> with this; the
script carries the newick tree it draws. C<python_file> is the script's file
name.

=back

With C<fasta> of fewer than two sequences it warns and returns an empty hash
ref.

=head2 msa_quality_table(%args)

Draws an all-against-all BLAST score table with matplotlib, and returns
C<filename>. The simplest call is

 msa_quality_table(
     fasta      => 't/data/DEG20010421.fa',  # or { name => sequence }, aligned or not
     filename   => 'DEG20010421.scores.png',
 );

=over

=item * C<fasta>, C<filename> (required): the sequences, as a FASTA file name or a
hash ref of name => sequence, as for C<plot_msa>; they are aligned all
against all with C<blastp>. Gaps are stripped first, so an aligned FASTA,
such as the one C<plot_msa> keeps, will do. Names must look like
C<Genus.species[.strain]>. C<fasta> is not needed when an existing
C<alignment_json> is given. C<unaligned_fa> is its old name.

=item * C<alignment_json>: the C<blastp -outfmt 15> report, as a parsed hash ref or a
file name. An existing file is read, and nothing is aligned; otherwise
C<blastp> is run on C<fasta> and its report kept there for next time. Without
it, the report is a temporary file.

=item * C<metric>: the hsp field to show (default C<score>).

=item * C<normalize>: divide every value by the largest, after adding
C<logscale_add> to both, so the scale runs to 1. A largest value of 0 or
less, as C<evalue> has when BLAST has rounded every e-value to 0, dies.

=item * C<order>, C<logscale_add>, C<default_undefined>, C<title>, C<cb_label>, C<cb_min>,
C<cb_max>, C<cblogscale>, C<show_numbers>: the sequences to show, in order; a
number added to every value; the value of a pair with no hit (otherwise
drawn grey); the title; the colour bar's label, lower and upper ends, and
whether it is logarithmic; and whether each cell shows its number. A name
in C<order> that the report does not hold dies, and so does a
C<logscale_add>, C<default_undefined>, C<cb_min>, C<cb_max> or C<normalize> that
is not a number.

=back

C<msa_file> is accepted and ignored, for old callers.

=head2 view_alignment($alignment, %args)

Shows an alignment in the terminal, as Stats::LikeR's C<view> shows a
dataframe, and draws it as an SVG or writes it as LaTeX tables when asked, with
chosen residues colored. It was C<clustal_view_residues> until 2026-11-16,
which wrote only the LaTeX.

 my %seqs = (a => 'MK-LV', b => 'M-QLV');
 view_alignment(\%seqs, row_width => 3, track => 'a',
     color_residues => { a => { 2 => 'red', 3 => [1, 0, 0] } });

prints

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

Each block of C<row_width> columns has its first and last alignment column
above it, and each row ends with how many residues that sequence has had so
far. Colored residues are in their colors when the output is a terminal. As
in C<view>, the banner comes first and last, so that an alignment longer than
the screen still says what it is where the scrolling stops.

 view_alignment('orthologs.fa', output_file => 'orthologs.svg');      # an SVG too
 view_alignment(msa_file => 'orthologs.fa', output_file => 'aln.tex'); # LaTeX tables
 my $text = view_alignment(\%seqs, return_only => 1);                 # print nothing

The alignment is the first argument, a hash ref of C<< name =E<gt> sequence >> or a FASTA
file name, followed by C<< name =E<gt> value >> pairs. It can also be given as
C<msa_file> among the pairs. If its sequences are all one length (such as the
alignment C<plot_msa> keeps), it is shown as it is. If not, it is first aligned
with Clustal Omega, which needs Alien::Bioinf; a FASTA file given is never
written. C<view_alignment> always returns the text, as UTF-8 bytes and without
the colors, whether or not it also prints it. When it writes a file, it then
prints C<wrote> and that file name to STDOUT, the name in black on cyan when
STDOUT is a terminal.

=over

=item * C<msa_file>: the FASTA file, when it is not given first.

=item * C<output_file>: a file to write as well, whose name says what it is: a
C<.svg> is drawn as the terminal shows the alignment, and a C<.tex> is written
as LaTeX tables, to be C<\input> into a document whose preamble loads
C<xcolor> (for the colors) and C<placeins> (for the C<\FloatBarrier> after each
table). Any other ending dies.

=item * C<title>: a line above the alignment in C<output_file>. The SVG draws it
in bold above the first block, and widens the image when the title is wider
than the alignment. The LaTeX writes it in bold above each table, with
"(continued)" after the first table. It is plain text, written so that LaTeX
prints it as it is, so C<_>, C<&> and C<%> need no escaping. The terminal and the
text returned do not show it. Without an C<output_file> it dies, and so does
a title that holds a control character, such as a newline. The default is no
title.

=item * C<color_residues>: C<< { protein =E<gt> { residue number =E<gt> color } } >>, where
residue numbers are 1-based and a color is one of xcolor's 19 base colors
(C<black>, C<blue>, C<brown>, C<cyan>, C<darkgray>, C<gray>, C<green>,
C<lightgray>, C<lime>, C<magenta>, C<olive>, C<orange>, C<pink>, C<purple>, C<red>,
C<teal>, C<violet>, C<white> and C<yellow>, with the RGB values xcolor 3.01
gives them) or C<[r, g, b]>, each 0 to 1. A colored column is colored in every
protein.

=item * C<color>: 1 to put every residue on its own color, as C<plot_msa> colors it
and as other alignment viewers do (default 0, which colors only
C<color_residues>). See L</"Coloring every residue">.

=item * C<track>: a protein that gets a row under it showing its colored residue
numbers, each starting at its residue's column, or just after the number
before it. A number that would run past the end of its block ends at the
block's last column instead, and is left out only when it would then
overwrite the number before it.

=item * C<order>: an array ref of the proteins to show, top to bottom (default:
sorted, ignoring case).

=item * C<row_width>: alignment columns per block (default 100).

=item * C<to>: the filehandle to print to (default: the one C<select> names, which is
STDOUT unless the program changed it).

=item * C<return_only>: 1 to print nothing, not even the C<wrote> line, and only
return the text (default 0).

=item * C<threads>, C<clustal_args>: clustalo threads (default 1) and an array ref of
further clustalo arguments, when the sequences have to be aligned.

=back

These four shape the LaTeX only, and die with any other C<output_file>:

=over

=item * C<split>: blocks per LaTeX table (default 4); further tables are captioned
"(continued)".

=item * C<caption>: the table caption (default empty).

=item * C<label>: written as C<\label{tab:label}>, or as C<tab:label0>, C<tab:label1>,
... when there is more than one table.

=item * C<table_text_size>: the LaTeX size command put at the start of each table
(default C<\footnotesize>).

=back

In the terminal and the SVG, a tab, carriage return or newline in a name is
shown as C<\t>, C<\r> or C<\n>, and any other control character as C<\x{..}>. A
sequence that holds a control character dies. In LaTeX, names and residues are
written so that LaTeX prints them as they are, C<_>, C<^>, C<{>, C<|>, C<< E<lt> >> and the
like included.

=head3 Coloring every residue

With C<< color =E<gt> 1 >>, every residue is on the color C<plot_msa> draws it in:
CIAlign's color-blind-safe "CBS" palette (Tumescheit, Firth & Brown, PeerJ
2022), which gives residues of like chemistry one color (D and E, K and R, S
and T, F and Y, N and Q, and L, V and I share theirs). The nucleotide palette is
used instead when every character is a nucleotide code or a gap, as C<plot_msa>
decides it, so a protein made only of letters that are also IUPAC nucleotide
codes (such as C<ACGT>) is colored as DNA. Gaps and C<*> stay uncolored. Each
residue's letter is white or black, whichever contrasts more with its color
by WCAG 2.2's contrast ratio.

The residues of C<color_residues> are then on their own colors instead, and
are bold and underlined. In the terminal the colors are 24-bit ANSI
backgrounds, which most terminals show; the text returned has none. In the SVG
each run of a color is one rectangle under the row. In LaTeX each residue is a
C<\colorbox>, and each table sets C<\fboxsep> to 0 so that the boxes meet.

 view_alignment('orthologs.fa', color => 1, output_file => 'aln.svg');

=head3 The SVG

The SVG is written by this module, not by matplotlib, so an aligned input
needs neither Alien::Bioinf nor Python. Its text stays text: a sequence can be
selected and copied out of it, and searched for in a browser. Each
residue is placed at the center of its own column, so the letters line up with
each other and with their colors in any font and any viewer, Eye of GNOME
(librsvg) included. Each colored residue has a
tooltip that names its sequence, its residue number and its alignment column,
such as C<a: K2, alignment column 2>.

Its provenance is where Matplotlib::Simple puts it, as the only metadata in
the file, in C<< E<lt>dc:creatorE<gt>E<lt>cc:AgentE<gt>E<lt>dc:titleE<gt> >>, on one line:

 /home/me/view.pl called using "view_alignment" in .../Cn/Bioinf.pm version 0.031 by user me on host box (linux) with Perl 5.44.0 (/usr/bin/perl), written as SVG by .../Cn/Bioinf.pm itself; from the FASTA file /home/me/orthologs.fa (SHA-256 781f...) of 4 sequences; showing 4 of 4 sequences in blocks of 100 columns, tracking S.cerevisiae, coloring 3 columns

When the sequences had to be aligned, the clause after "itself" says how, as
C<plot_msa>'s does: the ungapped file clustalo read, the Clustal Omega and
Alien::Bioinf versions, the alignment it wrote, each with its SHA-256, and the
command. A LaTeX file has the same line as its first, a C<%> comment.

=head1 Thanks

A lot of this work (not all!) used Claude AI, which was paid for by the University of Idaho's IMCI

=head1 AUTHOR

David E. Condon <dcondon@uidaho.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026-present by David E. Condon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
