use strict;
use warnings;

# Domain tests: equivalence partitioning and boundary value analysis for
# every input of the public API, following the "Domains" sections of the
# POD (under API SPECIFICATION for generate() and parse_prereqs()).
#
# For each input the valid and invalid partitions are exercised with one
# representative value each, and every documented edge is tested on both
# sides.  Each input has its own subtest.

use Test::Most;
use lib 't/lib';
use Test::Permissions qw(can_revoke_read);
use Test::Mockingbird;
use Test::Returns;
use Config;
use File::Temp qw(tempdir);
use Path::Tiny;
use POSIX qw(EIO);
use Readonly;
use YAML::Tiny;

use App::makefilepl2cpanfile;

Readonly my %CFG => (
	header        => '# Generated from Makefile.PL using makefilepl2cpanfile',
	default_mf    => 'Makefile.PL',
	cfg_dir       => '.config',
	cfg_file      => 'makefilepl2cpanfile.yml',
	name_max_fallback => 255,		# POSIX minimum guarantee on common systems
	long_name     => 1_000,			# "no maximum" probe for module names
	long_comment  => 100_000,
	long_version  => 1_000,
	many_entries  => 1_000,
	topic         => 'caller topic',
);

Readonly my $MF_ONE => "WriteMakefile(PREREQ_PM => { 'One::Mod' => 0 });\n";

# A file name full of shell metacharacters that is still legal on this OS.
# Windows forbids < > : " / \ | ? * in names, so there it uses the
# characters cmd.exe treats specially instead.
Readonly my $SHELL_CHARS_NAME => $^O eq 'MSWin32' ? 'a;b&c^d%PATH%e.PL' : 'a;b|c>d&e.PL';

# Character-domain samples, written as escapes to keep this file ASCII.
Readonly my %TEXT => (
	umlauts => "Gr\x{fc}\x{df}e f\x{fc}r \x{d6}sterreich",		# Gruesse fuer Oesterreich
	emoji   => "rocket \x{1F680} family \x{1F468}\x{200D}\x{1F469}\x{200D}\x{1F467} flag \x{1F1E9}\x{1F1EA}",
	zalgo   => "Z\x{0351}\x{034B}\x{0300}a\x{0308}\x{0301}\x{0316}l\x{0327}\x{0310}g\x{0338}o",
	arabic  => "\x{0645}\x{0631}\x{062D}\x{0628}\x{0627}",			# RTL script: kept
	cjk     => "\x{4F9D}\x{8D56}",
);
Readonly my %UNSAFE => (
	'RLO override'   => "\x{202E}",
	'LRE embedding'  => "\x{202A}",
	'RLI isolate'    => "\x{2067}",
	'PDI pop'        => "\x{2069}",
	'RLM mark'       => "\x{200F}",
	'ALM mark'       => "\x{061C}",
	'carriage return'=> "\r",
	'escape'         => "\e",
	'NUL'            => "\0",
	'C1 control'     => "\x{85}",
);

# -----------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------

sub make_mf {
	my ($content, $name) = @_;
	my $mf = path(tempdir(CLEANUP => 1))->child($name // $CFG{default_mf});
	$mf->spew_utf8($content);
	return $mf;
}

sub use_home {
	my $data = $_[0];
	my $home = path(tempdir(CLEANUP => 1));
	if(defined $data) {
		my $cfg = $home->child($CFG{cfg_dir}, $CFG{cfg_file});
		$cfg->parent->mkpath;
		YAML::Tiny->new($data)->write("$cfg");
	}
	return mock_scoped 'File::HomeDir::my_home' => sub { "$home" };
}

sub gen {
	my %args = @_;
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $out = App::makefilepl2cpanfile::generate(%args);
	return wantarray ? ($out, @w) : $out;
}

# The runtime requires map for one entry line, via the public parser.
sub parse_entry {
	my $line = $_[0];
	return App::makefilepl2cpanfile::parse_prereqs("PREREQ_PM => {\n\t$line\n},")->{runtime}{requires} || {};
}

sub develop_block {
	my $out = $_[0];
	return $out =~ /^on 'develop' => sub \{\n(.*?)^\};$/ms ? $1 : undef;
}

# -----------------------------------------------------------------------
# generate(): makefile
#
# Partitions: valid path forms / default / refused.  Boundaries: the file
# name length limit (NAME_MAX and NAME_MAX + 1) and file size (0 bytes,
# 1 byte, one entry).
# -----------------------------------------------------------------------
subtest 'domain: generate() makefile' => sub {
	my $g = use_home();

	# Valid partition: one representative of each path form.
	my $mf = make_mf($MF_ONE);
	my %forms = (
		'absolute path'     => "$mf",
		'Path::Tiny object' => $mf,
		'non-ASCII + space' => make_mf($MF_ONE, "\xC3\x84rger \xC3\x9F.PL")->stringify,
		'shell characters'  => make_mf($MF_ONE, $SHELL_CHARS_NAME)->stringify,
	);
	for my $form (sort keys %forms) {
		like gen(makefile => $forms{$form}, with_develop => 0), qr/^requires 'One::Mod';$/m, "valid: $form";
	}
	{
		my $cwd = Path::Tiny->cwd;
		chdir $mf->parent or die "chdir: $!";
		my $rel = eval { gen(makefile => $CFG{default_mf}, with_develop => 0) };
		my $def = eval { gen(with_develop => 0) };
		my $und = eval { gen(makefile => undef, with_develop => 0) };
		chdir $cwd or die "chdir: $!";
		like $rel, qr/One::Mod/, 'valid: relative path';
		is $def, $rel, 'default: omitted -> ./Makefile.PL';
		is $und, $rel, 'default: undef -> ./Makefile.PL';
	}

	# Refused partition: one representative of each kind.
	my $dir = tempdir(CLEANUP => 1);
	my %refused = (
		'empty string' => q{},
		'zero'         => 0,
		'missing file' => "$dir/absent.PL",
		'directory'    => $dir,
		'device'       => File::Spec->devnull,
	);
	for my $kind (sort keys %refused) {
		my $v = $refused{$kind};
		throws_ok { gen(makefile => $v) } qr/\ACannot read '\Q$v\E' at /, "refused: $kind";
	}
	throws_ok { gen(makefile => [$mf]) } qr/\ACannot read 'ARRAY\(0x[0-9a-f]+\)' at /, 'refused: reference';
	SKIP: {
		skip 'chmod cannot make a file unreadable here (root or Windows)', 1 unless can_revoke_read();
		my $locked = make_mf($MF_ONE);
		chmod 0, "$locked";
		throws_ok { gen(makefile => "$locked") } qr/\ACannot read '\Q$locked\E' at /, 'refused: unreadable';
	}

	# Boundary: file name length at NAME_MAX and one past it.  pathconf is
	# not implemented everywhere (Windows), and a whole path may hit a
	# shorter limit first (Windows MAX_PATH), so the edge is only tested
	# where a name of exactly NAME_MAX bytes can really be created.
	SKIP: {
		my $name_max = eval { POSIX::pathconf($dir, POSIX::_PC_NAME_MAX()) } || $CFG{name_max_fallback};
		my $at_max = path($dir)->child('M' x $name_max);
		skip "a $name_max-byte file name cannot be created here", 2 unless eval { $at_max->spew_utf8($MF_ONE); 1 };
		like gen(makefile => "$at_max", with_develop => 0), qr/One::Mod/, "boundary: name of $name_max bytes accepted";
		my $over = path($dir)->child('M' x ($name_max + 1));
		throws_ok { gen(makefile => "$over") } qr/\ACannot read /, 'boundary: name of NAME_MAX + 1 bytes refused';
	}

	# Boundary: file size.
	is gen(makefile => make_mf(q{})->stringify, with_develop => 0), "$CFG{header}\n", 'boundary: 0-byte file -> header only';
	is gen(makefile => make_mf("\n")->stringify, with_develop => 0), "$CFG{header}\n", 'boundary: 1-byte file -> header only';
	is gen(makefile => make_mf("PREREQ_PM=>{'A'=>0}")->stringify, with_develop => 0),
		"$CFG{header}\n\nrequires 'A';\n", 'boundary: smallest file with one entry';
};

# -----------------------------------------------------------------------
# generate(): existing
#
# Partitions: none / no develop block / a develop block / ignored forms.
# Boundaries: 0, 1 and many entries; the closing "};" at the start of a
# line (with and without indentation) versus on the same line.
# -----------------------------------------------------------------------
subtest 'domain: generate() existing' => sub {
	my $g  = use_home();
	my $mf = make_mf($MF_ONE)->stringify;
	my $plain = gen(makefile => $mf, with_develop => 0);

	for my $case ([undef, 'undef'], [q{}, 'empty'], ["requires 'X';\n", 'no develop block'],
			[{ a => 1 }, 'reference'], ["on 'develop' => sub {\n\trequires 'X';\n", 'never closed']) {
		is gen(makefile => $mf, existing => $case->[0], with_develop => 0), $plain, "no effect: $case->[1]";
	}

	my $block = sub { "on $_[0] => sub {\n$_[1]$_[2]\n" };
	is develop_block(gen(makefile => $mf, existing => $block->(q{'develop'}, q{}, '};'), with_develop => 0)), undef,
		'boundary: 0 entries -> no develop block';
	is develop_block(gen(makefile => $mf, existing => $block->(q{'develop'}, "\trequires 'A';\n", '};'), with_develop => 0)),
		"\trequires 'A';\n", 'boundary: 1 entry';
	my $many = join q{}, map { "\trequires 'M$_';\n" } 1 .. $CFG{many_entries};
	my @kept = gen(makefile => $mf, existing => $block->(q{'develop'}, $many, '};'), with_develop => 0) =~ /^\trequires 'M\d+';$/mg;
	is scalar @kept, $CFG{many_entries}, "boundary: $CFG{many_entries} entries all kept";

	like gen(makefile => $mf, existing => $block->(q{"develop"}, "\trequires 'A';\n", '};'), with_develop => 0),
		qr/^\trequires 'A';$/m, 'valid: "develop" in double quotes';
	like gen(makefile => $mf, existing => $block->(q{'develop'}, "\trequires 'A';\n", "  \t};"), with_develop => 0),
		qr/^\trequires 'A';$/m, 'boundary: indented closing };';
	is gen(makefile => $mf, existing => "on 'develop' => sub { requires 'A'; };\n", with_develop => 0), $plain,
		'boundary: }; not at the start of a line -> block not recognised (documented)';

	# Entry names: quotes must match; the old "'" separator is not a name.
	my $names = gen(makefile => $mf, with_develop => 0, existing => $block->(q{'develop'},
		qq{\trequires "A'B";\n\trequires 'Mixed";\n\trequires "Double::Q";\n}, '};'));
	like   $names, qr/^\trequires 'Double::Q';$/m, 'entry name: double-quoted kept';
	unlike $names, qr/'A'|'B'|Mixed/, 'entry name: "A\'B" and mismatched quotes not misread';

	# Entry versions: valid kept, invalid replaced (with a warning).
	my ($out, @w) = gen(makefile => $mf, with_develop => 0,
		existing => $block->(q{'develop'}, "\trequires 'V', 'v1.2.3';\n\trequires 'I', '1.0-TRIAL';\n", '};'));
	like $out, qr/^\trequires 'V', 'v1\.2\.3';$/m, 'entry version: valid kept';
	like $out, qr/^\trequires 'I';$/m, 'entry version: invalid dropped';
	is scalar @w, 1, 'entry version: one warning for the invalid one';
};

# -----------------------------------------------------------------------
# generate(): with_develop
#
# Partitions: Perl-true / Perl-false / default.  The edge values are the
# ones Perl treats surprisingly: '0.0' and ' ' are true, '0' is false.
# -----------------------------------------------------------------------
subtest 'domain: generate() with_develop' => sub {
	my $g  = use_home();
	my $mf = make_mf($MF_ONE)->stringify;
	for my $v (1, 'yes', '0.0', ' ', -1) {
		like gen(makefile => $mf, with_develop => $v), qr/on 'develop'/, "true: '$v'";
	}
	for my $v (0, '0', q{}) {
		unlike gen(makefile => $mf, with_develop => $v), qr/on 'develop'/, "false: '$v'";
	}
	like gen(makefile => $mf, with_develop => undef), qr/on 'develop'/, 'default: undef -> true';
	like gen(makefile => $mf), qr/on 'develop'/, 'default: omitted -> true';
};

# -----------------------------------------------------------------------
# generate(): combinations of edges
#
# Strategy: pair one argument at its minimum with another at its maximum,
# and check the documented interactions between them.
# -----------------------------------------------------------------------
subtest 'domain: generate() argument combinations' => sub {
	my $empty = make_mf(q{})->stringify;
	my $existing = "on 'develop' => sub {\n\trequires 'Kept::Tool';\n};\n";

	{
		my $g = use_home();
		is gen(makefile => $empty, existing => $existing, with_develop => 0),
			"$CFG{header}\n\non 'develop' => sub {\n\trequires 'Kept::Tool';\n};\n",
			'empty Makefile.PL + develop block + with_develop false -> header and kept block';
		my $both = gen(makefile => $empty, existing => $existing, with_develop => 1);
		like $both, qr/^\trequires 'Kept::Tool';$/m, 'with_develop true keeps the existing entry ...';
		like $both, qr/^\trequires 'Perl::Critic';$/m, '... and adds the tools';
	}
	{
		my $g = use_home({ develop => {} });
		is gen(makefile => $empty, with_develop => 1), "$CFG{header}\n",
			'empty Makefile.PL + empty develop config + with_develop true -> header only';
	}
	{
		my $g = use_home();
		my $big = join q{}, map { "\trequires 'D$_';\n" } 1 .. $CFG{many_entries};
		my $mf = make_mf("PREREQ_PM => {\n" . join(q{}, map { "\t'R$_' => 0,\n" } 1 .. $CFG{many_entries}) . "},\n");
		my $out = gen(makefile => "$mf", existing => "on 'develop' => sub {\n$big};\n", with_develop => 1);
		my @runtime = $out =~ /^requires 'R\d+';$/mg;
		my @dev     = $out =~ /^\trequires 'D\d+';$/mg;
		is scalar @runtime, $CFG{many_entries}, 'many Makefile.PL entries + many develop entries: all runtime kept';
		is scalar @dev,     $CFG{many_entries}, '... and all develop kept';
		returns_is($out, { type => 'string', matches => qr/\A\Q$CFG{header}\E\n.*(?<!\n)\n\z/s },
			'... and the output still matches the documented schema');
	}
};

# -----------------------------------------------------------------------
# parse_prereqs(): content
# -----------------------------------------------------------------------
subtest 'domain: parse_prereqs() content' => sub {
	for my $case ([undef, 'undef'], [q{}, 'empty'], [[], 'arrayref'], [\q{x}, 'scalar ref'],
			['no dependency lists here', 'unrelated text']) {
		my @w;
		local $SIG{__WARN__} = sub { push @w, $_[0] };
		is_deeply App::makefilepl2cpanfile::parse_prereqs($case->[0]), {}, "empty result: $case->[1]";
		is scalar @w, 0, "no warning: $case->[1]";
	}
	returns_is(App::makefilepl2cpanfile::parse_prereqs($MF_ONE), { type => 'hashref' }, 'valid: hashref result');
};

# -----------------------------------------------------------------------
# Module name (the key of every entry)
#
# Boundaries: one character (shortest valid), the empty name, and a very
# long name (no maximum).  Invalid partitions: each malformed shape once.
# -----------------------------------------------------------------------
subtest 'domain: module name' => sub {
	for my $name ('A', '_', 'a', 'A1', 'A_b', 'A::B', 'A::B::C', 'A::1', 'Z' x $CFG{long_name}) {
		my $shown = length $name > 20 ? 'Z x ' . length $name : $name;
		ok exists parse_entry("'$name' => 0,")->{$name}, "valid: $shown";
	}
	for my $name (q{}, '1A', '::A', 'A::', 'A:::B', 'A::::B', 'A-B', 'A B', 'A;B',
			"\x{c4}rger", "T\x{435}st::More", "A\x{2028}B") {
		(my $shown = $name) =~ s/([^\x20-\x7e])/sprintf '\\x{%x}', ord $1/ge;
		is_deeply parse_entry("'$name' => 0,"), {}, "invalid: '$shown'";
	}
	is_deeply parse_entry('Bareword => 0,'), {}, 'invalid: unquoted key';
	is_deeply parse_entry(q{"A'B" => 0,}), {}, q{invalid: old "'" separator (not misread as a different module)};
	is_deeply parse_entry(q{'A" => 0,}), {}, 'invalid: mismatched quotes';
};

# -----------------------------------------------------------------------
# Version (entry values and MIN_PERL_VERSION)
#
# Partitions: valid / zero / invalid.  Boundaries: the zero edge ('0',
# '0.0', 'v0' versus the smallest non-zero '0.000001'), the one-character
# edge ('v' invalid, '1' valid), and a very long version.
# -----------------------------------------------------------------------
subtest 'domain: version' => sub {
	my $g = use_home();

	for my $v ("'1'", '1.60', "'v1.2.3'", "'1.23_01'", "'5.010001'", '"2.0"', "'0.000001'", "'v1'") {
		(my $bare = $v) =~ s/['"]//g;
		is parse_entry("'M' => $v,")->{M}{version}, $bare, "valid: $v kept exactly";
	}
	for my $v ("'.'", "'_'", "'v'", "'1e3'", "'1.0-TRIAL'", "'1 0'", "'-1'", "'\x{0661}'",
			'$VERSION', "version->parse('1.0')", "'>= 1.2 < 2.0'", "'1.2, 2.0'", "' >= 1.2'", "''") {
		(my $shown = $v) =~ s/([^\x20-\x7e])/sprintf '\\x{%x}', ord $1/ge;
		is parse_entry("'M' => $v,")->{M}{version}, 0, "invalid: $shown -> no minimum";
	}
	# Version ranges (CPAN::Meta): every part after the first needs an
	# operator, and parts are separated by commas.
	for my $range ("'>= 1.2, < 2.0'", "'== 1.5'", "'!= 1.3, >= 1.0'", "'< 2'") {
		(my $bare = $range) =~ s/'//g;
		is parse_entry("'M' => $range,")->{M}{version}, $bare, "range: $range kept exactly";
	}
	my $long = '1' x $CFG{long_version};
	is parse_entry("'M' => '$long',")->{M}{version}, $long, 'boundary: very long version kept whole';

	# Zero edge: stored, but never written as a requirement.
	for my $v ('0', '0.0', '0.000', 'v0', 'v0.0.0') {
		unlike gen(makefile => make_mf("PREREQ_PM => { 'M' => '$v' },\n")->stringify, with_develop => 0),
			qr/'M', /, "zero: '$v' writes no version";
	}
	like gen(makefile => make_mf("PREREQ_PM => { 'M' => '0.000001' },\n")->stringify, with_develop => 0),
		qr/^requires 'M', '0\.000001';$/m, 'zero edge: smallest non-zero is written';

	# MIN_PERL_VERSION uses the same domain.
	my %perl = ('5' => 1, '5.010' => 1, 'v5.10.0' => 1, '0' => 0, '0.0' => 0, 'v0' => 0,
		'5.010abc' => 0, '.' => 0, '1e3' => 0);
	for my $v (sort keys %perl) {
		my $out = gen(makefile => make_mf("WriteMakefile(MIN_PERL_VERSION => '$v');\n")->stringify, with_develop => 0);
		if($perl{$v}) {
			like $out, qr/^requires 'perl', '\Q$v\E';$/m, "MIN_PERL_VERSION '$v': written";
		} else {
			unlike $out, qr/'perl'/, "MIN_PERL_VERSION '$v': not written";
		}
	}
};

# -----------------------------------------------------------------------
# Phase and relationship names
# -----------------------------------------------------------------------
subtest 'domain: phase and relationship names' => sub {
	for my $phase (qw(runtime configure build test develop)) {
		for my $rel (qw(requires recommends suggests conflicts)) {
			my $d = App::makefilepl2cpanfile::parse_prereqs("prereqs => { $phase => { $rel => { 'M' => 0 } } },");
			ok exists $d->{$phase}{$rel}{M}, "valid: $phase/$rel";
		}
	}
	for my $case (['Runtime', 'requires'], ['RUNTIME', 'requires'], ['x_phase', 'requires'],
			['runtime', 'Requires'], ['runtime', 'recommend'], ['runtime', 'require'], ['runtime', 'conflict']) {
		my ($phase, $rel) = @{$case};
		is_deeply App::makefilepl2cpanfile::parse_prereqs("prereqs => { $phase => { $rel => { 'M' => 0 } } },"),
			{}, "invalid: $phase/$rel";
	}
};

# -----------------------------------------------------------------------
# Comment text: multibyte and hostile character partitions
#
# Strategy: every printable partition (umlauts, emoji including ZWJ
# sequences and flags, Zalgo stacks, RTL script, CJK) must survive the
# whole trip - parse, generate, write as UTF-8, read back, load with
# Module::CPANfile - with its length unchanged.  Every unsafe partition
# (bidi controls, C0/C1 controls) must be removed, and a comment made only
# of unsafe characters must disappear.
# -----------------------------------------------------------------------
subtest 'domain: comment characters' => sub {
	my $g = use_home();
	for my $kind (sort keys %TEXT) {
		my $text = $TEXT{$kind};
		my $entry = parse_entry("'M' => 0,\t# $text");
		is $entry->{M}{comment}, $text, "$kind: parsed unchanged";
		is length $entry->{M}{comment}, length $text, "$kind: same length in characters";

		my $out = gen(makefile => make_mf("PREREQ_PM => {\n\t'M' => 0,\t# $text\n},\n")->stringify, with_develop => 0);
		my $file = path(tempdir(CLEANUP => 1))->child('cpanfile');
		$file->spew_utf8($out);
		is $file->slurp_utf8, $out, "$kind: survives a UTF-8 write and read";
		like $out, qr/^requires 'M';   # \Q$text\E$/m, "$kind: written verbatim";
		SKIP: {
			skip 'Module::CPANfile not installed', 1 unless eval { require Module::CPANfile; 1 };
			ok eval { Module::CPANfile->load("$file"); 1 }, "$kind: output loads as a cpanfile" or diag $@;
		}
	}

	for my $kind (sort keys %UNSAFE) {
		my $c = $UNSAFE{$kind};
		is parse_entry("'M' => 0,\t# before${c}after")->{M}{comment}, 'beforeafter', "unsafe $kind: removed";
		is parse_entry("'M' => 0,\t# $c")->{M}{comment}, undef, "unsafe $kind alone: no comment";
	}
	is parse_entry("'M' => 0,\t# a\tb")->{M}{comment}, "a\tb", 'TAB inside a comment is kept';

	my $long = 'x' x $CFG{long_comment};
	is length parse_entry("'M' => 0, # $long")->{M}{comment}, $CFG{long_comment}, 'boundary: very long comment kept whole';
};

# -----------------------------------------------------------------------
# Configuration file entries
# -----------------------------------------------------------------------
subtest 'domain: configuration develop entries' => sub {
	my $mf = make_mf($MF_ONE)->stringify;
	my %cases = (
		'valid name, version'  => [ { 'Good::Tool' => '1.5' },   qr/^\trequires 'Good::Tool', '1\.5';$/m, 0 ],
		'valid name, zero'     => [ { 'Good::Tool' => 0 },       qr/^\trequires 'Good::Tool';$/m,         0 ],
		'valid name, empty'    => [ { 'Good::Tool' => q{} },     qr/^\trequires 'Good::Tool';$/m,         0 ],
		'valid name, null'     => [ { 'Good::Tool' => undef },   qr/^\trequires 'Good::Tool';$/m,         0 ],
		'invalid name'         => [ { 'Bad Tool'   => 0 },       qr/\A(?!.*Bad Tool)/s,                   1 ],
		'invalid version'      => [ { 'Good::Tool' => '1.0x' },  qr/^\trequires 'Good::Tool';$/m,         1 ],
		'non-ASCII name'       => [ { "T\x{fc}r" => 0 },         qr/\A(?!.*T\x{fc}r)/s,                    1 ],
	);
	for my $name (sort keys %cases) {
		my ($data, $expect, $warnings) = @{ $cases{$name} };
		my $g = use_home({ develop => $data });
		my ($out, @w) = gen(makefile => $mf, with_develop => 1);
		like $out, $expect, "$name: output";
		is scalar @w, $warnings, "$name: $warnings warning(s)";
	}
};

# -----------------------------------------------------------------------
# Failures leave the caller's globals alone
# -----------------------------------------------------------------------
subtest 'domain: rejected input does not pollute globals' => sub {
	my $g = use_home();
	local $_ = $CFG{topic};
	local $! = EIO;
	for my $bad (q{}, 0, [], '/no/such/file') {
		eval { App::makefilepl2cpanfile::generate(makefile => $bad) };
	}
	is $_, $CFG{topic}, '$_ unchanged after refused calls';
	is 0 + $!, EIO, '$! unchanged after refused calls';
};

done_testing;
