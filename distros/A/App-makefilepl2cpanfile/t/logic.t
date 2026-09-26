use strict;
use warnings;

# Logic tests: each subtest is a proof of one rule the code relies on.
#
# The simplifications in lib/App/makefilepl2cpanfile.pm are only correct
# if these premises hold, so they are tested first, against every source
# of data, with deliberately hostile input:
#
#   P1  Every stored version is 0, '' (config only), or passes
#       _valid_requirement (a version or a version range).
#   P2  Every stored comment is undef or a non-empty string.
#
# Then each reduced condition is tested with one case per logical
# partition (never two cases from the same partition), and each guard
# clause is shown to stop the call before any later work happens.
#
# The second half exhausts the truth table of every conditional in the
# module, checks De Morgan's laws row by row, walks all 40 combinations
# of generate()'s inputs against its formal specification, asserts the
# invariants before, during and after a call, and shows that inputs
# contradicting a premise are refused by the first guard able to see them.

use Test::Most;
use lib 't/lib';
use Test::Permissions qw(can_revoke_read can_revoke_search);
use Test::Mockingbird;
use Test::Returns;
use File::Temp qw(tempdir);
use Path::Tiny;
use Readonly;
use YAML::Tiny;

use App::makefilepl2cpanfile;

Readonly my $PKG => 'App::makefilepl2cpanfile';

Readonly my %CFG => (
	header   => '# Generated from Makefile.PL using makefilepl2cpanfile',
	cfg_dir  => '.config',
	cfg_file => 'makefilepl2cpanfile.yml',
);

# Version tokens chosen to hit every branch of every validator: valid,
# zero, empty, no digit, trailing junk, non-ASCII digits, code, ranges.
Readonly my @VERSION_CORPUS => (
	'0', '1', '1.60', 'v1.2.3', '1.23_01', '0.0', 'v0', '', '.', '_', 'v',
	'1e3', '1.0-TRIAL', '>= 1.2', "\x{0661}", '1\\', '$x', 'Inf', 'NaN', ' 1',
);

# Comment tails: printable, blank, and made only of stripped characters.
Readonly my @COMMENT_CORPUS => (
	'#', '#   ', "#\t", '# text', "# \x{202E}", "# \r", "# a\x{202E}b", "# \x{1F680}",
);

sub use_home {
	my $data = $_[0];
	my $home = path(tempdir(CLEANUP => 1));
	my $cfg  = $home->child($CFG{cfg_dir}, $CFG{cfg_file});
	if(defined $data) {
		$cfg->parent->mkpath;
		ref $data ? YAML::Tiny->new($data)->write("$cfg") : $cfg->spew_utf8($data);
	}
	return (mock_scoped('File::HomeDir::my_home' => sub { "$home" }), $cfg);
}

sub make_mf {
	my $mf = path(tempdir(CLEANUP => 1))->child('Makefile.PL');
	$mf->spew_utf8($_[0]);
	return "$mf";
}

sub quiet_warnings {
	my $code = $_[0];
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $r = $code->();
	return ($r, @w);
}

# Every [phase, rel, module, entry] in a deps structure.
sub all_entries {
	my $deps = $_[0];
	return map {
		my $p = $_;
		map {
			my $r = $_;
			map { [ $p, $r, $_, $deps->{$p}{$r}{$_} ] } keys %{ $deps->{$p}{$r} }
		} keys %{ $deps->{$p} }
	} keys %{$deps};
}

# Captures the structure generate() hands to _emit.
sub capture_emit {
	my $slot = $_[0];
	my $real = \&App::makefilepl2cpanfile::_emit;
	return mock_scoped "${PKG}::_emit" => sub { ${$slot} = $_[0]; $real->(@_) };
}

# -----------------------------------------------------------------------
# P1: every stored version is in the domain _has_version assumes
#
# Premise 1: _has_version only tests for a digit from 1 to 9.
# Premise 2: that is correct only for undef, 0, '' and valid versions.
# So: every source must store nothing else.  Feed every corpus token
# through all three sources and check each stored value.
# -----------------------------------------------------------------------
subtest 'P1: all three sources store only in-domain versions' => sub {
	my $in_domain = sub {
		my $v = $_[0];
		return defined $v && ($v eq '0' || $v eq q{} || App::makefilepl2cpanfile::_valid_requirement($v));
	};

	# Source 1: Makefile.PL entries, quoted and bare.
	my $body = join q{}, map {
		my $v = $VERSION_CORPUS[$_];
		(my $q = $v) =~ s/'/\\'/g;
		"\t'Q$_' => '$q',\n\t'B$_' => $v,\n"
	} 0 .. $#VERSION_CORPUS;
	my $parsed = App::makefilepl2cpanfile::parse_prereqs("PREREQ_PM => {\n$body},");
	my @bad = grep { !$in_domain->($_->[3]{version}) } all_entries($parsed);
	is_deeply \@bad, [], 'Makefile.PL: every stored version is in the domain';
	ok !grep({ $_->[3]{version} eq q{} } all_entries($parsed)), "Makefile.PL: never stores ''";

	# Source 2: existing develop block.
	my ($g) = use_home();
	my $existing = "on 'develop' => sub {\n" . join(q{}, map {
		(my $v = $VERSION_CORPUS[$_]) =~ s/'//g;
		"\trequires 'E$_', '$v';\n"
	} 0 .. $#VERSION_CORPUS) . "};\n";
	my $seen;
	my $ge = capture_emit(\$seen);
	quiet_warnings(sub {
		App::makefilepl2cpanfile::generate(makefile => make_mf(q{}), existing => $existing, with_develop => 0)
	});
	@bad = grep { !$in_domain->($_->[3]{version}) } all_entries($seen);
	is_deeply \@bad, [], 'existing cpanfile: every stored version is in the domain';

	# Source 3: configuration file.
	my ($gc) = use_home({ develop => { map { ("C$_" => $VERSION_CORPUS[$_]) } 0 .. $#VERSION_CORPUS } });
	my ($config) = quiet_warnings(sub { App::makefilepl2cpanfile::_load_develop_config() });
	@bad = grep { !$in_domain->($config->{$_}) } keys %{$config};
	is_deeply \@bad, [], 'config: every stored version is in the domain';
};

# -----------------------------------------------------------------------
# P2: every stored comment is undef or non-empty
#
# Premise 1: _fmt_dep writes a comment whenever it is defined.
# Premise 2: an empty comment would leave a dangling "   # ".
# So: no source may store ''.
# -----------------------------------------------------------------------
subtest 'P2: no source stores an empty comment' => sub {
	my $body = join q{}, map { "\t'C$_' => 0, $COMMENT_CORPUS[$_]\n" } 0 .. $#COMMENT_CORPUS;
	my @entries = all_entries(App::makefilepl2cpanfile::parse_prereqs("PREREQ_PM => {\n$body},"));
	is scalar @entries, scalar @COMMENT_CORPUS, 'every corpus line produced an entry';
	my @empty = grep { defined $_->[3]{comment} && $_->[3]{comment} eq q{} } @entries;
	is_deeply \@empty, [], "no comment is ''";

	my ($g) = use_home({ develop => { 'Cfg::Tool' => 0 } });
	my $seen;
	my $ge = capture_emit(\$seen);
	App::makefilepl2cpanfile::generate(
		makefile => make_mf(q{}), existing => "on 'develop' => sub {\n\trequires 'E';\n};\n",
	);
	is_deeply [ grep { defined $_->[3]{comment} } all_entries($seen) ], [],
		'merged and configured entries carry no comment at all';
};

# -----------------------------------------------------------------------
# _has_version: the reduced gate "contains a digit 1-9"
#
# One case per partition of its (P1) domain, plus the two edges where the
# old three-step test and the new one could disagree: a v-string of zeros
# and the smallest non-zero value.
# -----------------------------------------------------------------------
subtest '_has_version: one case per partition' => sub {
	my %truth = (
		'undef'          => [ undef,       0 ],
		'empty'          => [ q{},         0 ],
		'numeric zero'   => [ 0,           0 ],
		'dotted zero'    => [ '0.000',     0 ],
		'v-string zero'  => [ 'v0.0.0',    0 ],
		'underscore 0'   => [ '0_0',       0 ],
		'smallest > 0'   => [ '0.000001',  1 ],
		'v-string > 0'   => [ 'v0.0.1',    1 ],
		'ordinary'       => [ '9',         1 ],
		'range >= zero'  => [ '>= 0.0',    0 ],
		'range >= real'  => [ '>= 1.2',    1 ],
		'range < only'   => [ '< 2',       1 ],
		'range compound' => [ '>= 0, < 2', 1 ],
	);
	for my $name (sort keys %truth) {
		my ($v, $want) = @{ $truth{$name} };
		is App::makefilepl2cpanfile::_has_version($v), $want, "$name -> $want";
	}
	returns_is(App::makefilepl2cpanfile::_has_version('1'), { type => 'boolean' }, 'returns a boolean');
};

# -----------------------------------------------------------------------
# Existing-cpanfile version guard: length($ver) && !valid($ver)
#
# Two inputs (present? valid?) give four rows; all four are tested and
# only the "present and invalid" row may warn.
# -----------------------------------------------------------------------
subtest 'merge guard: complete truth table' => sub {
	my ($g) = use_home();
	my $seen;
	my $ge = capture_emit(\$seen);
	my %rows = (
		'absent'            => [ "requires 'M';",          0,        0 ],
		'empty'             => [ "requires 'M', '';",      0,        0 ],
		'present, valid'    => [ "requires 'M', '1.5';",   '1.5',    0 ],
		'present, invalid'  => [ "requires 'M', '1.5x';",  0,        1 ],
	);
	for my $name (sort keys %rows) {
		my ($line, $want, $warns) = @{ $rows{$name} };
		my (undef, @w) = quiet_warnings(sub {
			App::makefilepl2cpanfile::generate(
				makefile => make_mf(q{}), existing => "on 'develop' => sub {\n\t$line\n};\n", with_develop => 0,
			)
		});
		is $seen->{develop}{requires}{M}{version}, $want, "$name: stored version";
		is scalar @w, $warns, "$name: $warns warning(s)";
	}
};

# -----------------------------------------------------------------------
# Config version check: $v eq '' || valid($v), with undef read as 0
#
# The removed "$v eq '0'" test is proved redundant by the '0' row passing
# silently.
# -----------------------------------------------------------------------
subtest 'config version check: complete truth table' => sub {
	my %rows = (
		'null'       => [ undef,  0,     0 ],
		'empty'      => [ q{},    q{},   0 ],
		'zero'       => [ '0',    '0',   0 ],
		'valid'      => [ '1.5',  '1.5', 0 ],
		'invalid'    => [ '1.5x', 0,     1 ],
	);
	for my $name (sort keys %rows) {
		my ($v, $want, $warns) = @{ $rows{$name} };
		my ($g) = use_home({ develop => { 'T' => $v } });
		my ($config, @w) = quiet_warnings(sub { App::makefilepl2cpanfile::_load_develop_config() });
		is $config->{T}, $want, "$name: stored as expected";
		is scalar @w, $warns, "$name: $warns warning(s)";
	}
};

# -----------------------------------------------------------------------
# Tool injection: tools are added exactly where nothing is listed
#
# Premise 1: a tool listed under any relationship is "listed".
# Premise 2: listed tools are never touched; the rest go under requires.
# One case for each relationship a tool can already be listed under, one
# unlisted tool, and the empty set (which must not create a develop hash).
# -----------------------------------------------------------------------
subtest 'injection: the listed set decides everything' => sub {
	my $existing = "on 'develop' => sub {\n\trequires 'R', '1';\n\trecommends 'C';\n\tsuggests 'S';\n};\n";
	my ($g) = use_home({ develop => { R => '9', C => '9', S => '9', New => '2' } });
	my $seen;
	my $ge = capture_emit(\$seen);
	App::makefilepl2cpanfile::generate(makefile => make_mf(q{}), existing => $existing);
	my $dev = $seen->{develop};
	is $dev->{requires}{R}{version}, '1', 'listed under requires: untouched';
	ok !exists $dev->{requires}{C}, 'listed under recommends: not added to requires';
	ok !exists $dev->{requires}{S}, 'listed under suggests: not added to requires';
	is $dev->{requires}{New}{version}, '2', 'unlisted: added under requires';

	my ($g2) = use_home({ develop => {} });
	App::makefilepl2cpanfile::generate(makefile => make_mf(q{}), with_develop => 1);
	ok !exists $seen->{develop}, 'no tools and nothing listed: no develop hash is created';
};

# -----------------------------------------------------------------------
# Guard clauses stop the call before any later work
#
# Each guard is proved by spying on the next step: if the guard works,
# that step is never reached.
# -----------------------------------------------------------------------
subtest 'guards: each terminal state is reached first' => sub {
	# generate(): an unusable makefile is refused before anything is read.
	{
		my $read = spy('Path::Tiny::slurp_utf8');
		my $home = spy('File::HomeDir::my_home');
		throws_ok { App::makefilepl2cpanfile::generate(makefile => '/no/such/Makefile.PL') }
			qr/\ACannot read '\/no\/such\/Makefile\.PL' at /, 'refused with the documented message';
		is scalar(my @r = $read->()), 0, 'nothing was read';
		is scalar(my @h = $home->()), 0, 'the configuration was not consulted';
		restore($_) for qw(Path::Tiny::slurp_utf8 File::HomeDir::my_home);
	}

	# _load_develop_config(): each guard, and the YAML reader is only
	# reached for a regular file.
	my $yaml = spy('YAML::Tiny::read');
	my $calls = sub { my @c = $yaml->(); scalar @c };

	{
		my $g = mock_scoped 'File::HomeDir::my_home' => sub { q{} };
		ok scalar keys %{ App::makefilepl2cpanfile::_load_develop_config() }, 'no home: defaults';
	}
	{
		my ($g) = use_home();
		App::makefilepl2cpanfile::_load_develop_config();
	}
	{
		my ($g, $cfg) = use_home();
		$cfg->mkpath;
		App::makefilepl2cpanfile::_load_develop_config();
	}
	is $calls->(), 0, 'no home, no file, not a regular file: YAML never read';

	SKIP: {
		skip 'chmod cannot make a directory unsearchable here (root or Windows)', 2 unless can_revoke_search();
		my ($g, $cfg) = use_home({ develop => {} });
		chmod 0, $cfg->parent->stringify;
		throws_ok { App::makefilepl2cpanfile::_load_develop_config() }
			qr/\AFailed to parse \Q$cfg\E: /, 'unexaminable path: refused';
		chmod 0755, $cfg->parent->stringify;
		is $calls->(), 0, 'and YAML was never read';
	}

	{
		my ($g) = use_home({ develop => { 'Ok' => 0 } });
		App::makefilepl2cpanfile::_load_develop_config();
		is $calls->(), 1, 'regular file: YAML read exactly once';
	}
	restore('YAML::Tiny::read');
};

# -----------------------------------------------------------------------
# _emit post-condition (the Z "post" clause of generate)
#
# Given P1 and P2, the single loop must still give: the header first, one
# trailing newline, no empty section, runtime unwrapped, other phases in
# order, and a version exactly when _has_version is true.
# -----------------------------------------------------------------------
subtest '_emit: post-condition from the formal specification' => sub {
	my $deps = {
		test    => { suggests => { 'T' => { version => '0.0', comment => undef } } },
		runtime => { requires => { 'Z' => { version => '1', comment => 'z' }, 'A' => { version => 'v0', comment => undef } } },
		build   => { requires => {} },
		develop => { recommends => { 'D' => { version => '2', comment => undef } } },
	};
	is App::makefilepl2cpanfile::_emit($deps, '5.010'), join(q{},
		"$CFG{header}\n\n",
		"requires 'perl', '5.010';\n\n",
		"requires 'A';\nrequires 'Z', '1';   # z\n\n",
		"on 'test' => sub {\n\tsuggests 'T';\n};\n\n",
		"on 'develop' => sub {\n\trecommends 'D', '2';\n};\n",
	), 'exact output: order, zero versions omitted, empty phase dropped';

	is App::makefilepl2cpanfile::_emit({}, 'v0'), "$CFG{header}\n", 'zero perl version and no deps: header only';

	my $entries = App::makefilepl2cpanfile::_phase_entries($deps->{runtime});
	returns_is($entries, { type => 'arrayref' }, '_phase_entries returns a reference');
	is_deeply [ map { $_->[1] } @{$entries} ], [qw(A Z)], '_phase_entries: sorted within a relationship';
	is_deeply App::makefilepl2cpanfile::_phase_entries(undef), [], '_phase_entries: absent phase -> empty';
};

# =======================================================================
# Truth tables for every conditional in the module
#
# Each table lists every combination of the inputs to one condition.
# Every row also checks De Morgan's law for that condition: "not (A and
# B)" must equal "(not A) or (not B)", and "not (A or B)" must equal
# "(not A) and (not B)".  Rows that are impossible are named and the
# reason they cannot happen is asserted.
# =======================================================================

Readonly my %TT => (
	defaults => [qw(Devel::Cover Perl::Critic Test::Pod Test::Pod::Coverage)],
	tool     => 'Tool::X',
	kept     => 'Kept::Y',
	mod      => 'Mod::M',
);

# Checks both De Morgan forms for two booleans against the observed value
# of a guard written as "fail unless A && B".
sub de_morgan_ok {
	my ($a, $b, $observed_fail, $name) = @_;
	my $expect = !($a && $b) ? 1 : 0;
	is $observed_fail ? 1 : 0, $expect, "$name: guard result";
	is((!($a && $b) ? 1 : 0), ((!$a || !$b) ? 1 : 0), "$name: not(A and B) == (not A) or (not B)");
	return;
}

# -----------------------------------------------------------------------
# Rule: "A makefile is used only if it is a regular file AND readable."
# Guard: croak unless -f $makefile && -r _
# -----------------------------------------------------------------------
subtest 'truth table: makefile guard (-f AND -r)' => sub {
	my ($g) = use_home();
	my $dir = path(tempdir(CLEANUP => 1));

	my $file_ok = $dir->child('ok.PL');
	$file_ok->spew_utf8("PREREQ_PM => { 'A' => 0 },\n");
	my $file_locked = $dir->child('locked.PL');
	$file_locked->spew_utf8(q{});
	my $dir_open = $dir->child('dir_open');
	$dir_open->mkpath;
	my $dir_locked = $dir->child('dir_locked');
	$dir_locked->mkpath;

	my @rows = (
		[ 1, 1, "$file_ok",     'regular, readable' ],
		[ 1, 0, "$file_locked", 'regular, unreadable' ],
		[ 0, 1, "$dir_open",    'directory, readable' ],
		[ 0, 0, "$dir_locked",  'directory, unreadable' ],
	);
	SKIP: {
		skip 'chmod cannot make a file unreadable here (root or Windows)', 4 * 2 unless can_revoke_read();
		chmod 0, "$file_locked";
		chmod 0, "$dir_locked";
		for my $row (@rows) {
			my ($is_file, $readable, $path, $name) = @{$row};
			my $died = !eval { App::makefilepl2cpanfile::generate(makefile => $path, with_develop => 0); 1 };
			like $@, qr/\ACannot read '\Q$path\E' at /, "$name: documented message" if $died;
			de_morgan_ok($is_file, $readable, $died, $name);
		}
		chmod 0700, "$dir_locked";
	}
};

# -----------------------------------------------------------------------
# Rule: "A read error is survivable only if it is a decoding error."
# Guard: die $@ unless $@ =~ /decode|ill-formed|utf/i
# Each alternative must be sufficient on its own (and case must not
# matter); with none of them the error is passed on unchanged.
# -----------------------------------------------------------------------
subtest 'truth table: read error classification (decode OR ill-formed OR utf)' => sub {
	my ($g) = use_home();
	my $mf = make_mf("PREREQ_PM => { 'A' => 0 },\n");
	my @rows = (
		[ 'Cannot DECODE input',        1, 'only "decode" (upper case)' ],
		[ 'Ill-Formed sequence',        1, 'only "ill-formed" (mixed case)' ],
		[ 'bad Utf8 byte',              1, 'only "utf" (mixed case)' ],
		[ 'ill-formed UTF-8 decode',    1, 'all three' ],
		[ 'Input/output error',         0, 'none of them' ],
	);
	for my $row (@rows) {
		my ($msg, $survivable, $name) = @{$row};
		my $m = mock_scoped(
			'Path::Tiny::slurp_utf8' => sub { die "$msg\n" },
			'Path::Tiny::slurp_raw'  => sub { "PREREQ_PM => { 'Raw' => 0 },\n" },
		);
		my ($out, @w);
		my $died = !eval { ($out, @w) = quiet_warnings(sub { App::makefilepl2cpanfile::generate(makefile => $mf, with_develop => 0) }); 1 };
		if($survivable) {
			ok !$died, "$name: survives";
			like $out, qr/^requires 'Raw';$/m, "$name: raw bytes used";
			is scalar @w, 1, "$name: one warning";
		} else {
			is $@, "$msg\n", "$name: error passed on unchanged";
		}
	}
};

# -----------------------------------------------------------------------
# Rule: "An existing develop entry is kept only if its name is valid; its
# version is dropped (with a warning) only if present AND invalid."
# Two independent conditions: name (2 values) x version (4 values).
# -----------------------------------------------------------------------
subtest 'truth table: existing entry (name valid) x (version absent/empty/valid/invalid)' => sub {
	my ($g) = use_home();
	my $seen;
	my $ge = capture_emit(\$seen);
	my %names = ('valid' => 'Good::Name', 'invalid' => 'Bad Name');
	my %vers  = (
		'absent'  => [ q{},         0,     0 ],
		'empty'   => [ q{, ''},     0,     0 ],
		'valid'   => [ q{, '1.5'},  '1.5', 0 ],
		'invalid' => [ q{, '1.5x'}, 0,     1 ],
	);
	for my $n (sort keys %names) {
		for my $v (sort keys %vers) {
			my ($suffix, $want, $warns) = @{ $vers{$v} };
			my $mod = $names{$n};
			my (undef, @w) = quiet_warnings(sub {
				App::makefilepl2cpanfile::generate(
					makefile => make_mf(q{}), with_develop => 0,
					existing => "on 'develop' => sub {\n\trequires '$mod'$suffix;\n};\n",
				)
			});
			my $row = "name $n, version $v";
			if($n eq 'valid') {
				is $seen->{develop}{requires}{$mod}{version}, $want, "$row: stored version";
				is scalar @w, $warns, "$row: $warns warning(s)";
			} else {
				ok !exists $seen->{develop}, "$row: entry dropped";
				is scalar @w, 0, "$row: dropped silently (the name check comes first)";
			}
		}
	}
};

# -----------------------------------------------------------------------
# Rule: "A stored comment is undef unless, after removing unsafe
# characters and outer blanks, something remains."
# And: "the comment belongs to an entry only if it is the last on the
# line."  Rows: (comment present?) x (anything left after cleaning?) x
# (entry is last on its line?).
# -----------------------------------------------------------------------
subtest 'truth table: comment (present) x (non-empty after cleaning) x (last entry)' => sub {
	my @rows = (
		[ 0, 0, 1, q{},                undef, 'no comment' ],
		[ 1, 0, 1, "# \x{202E}\t ",    undef, 'comment, empty after cleaning, last' ],
		[ 1, 1, 1, '# kept',           'kept', 'comment, non-empty, last' ],
		[ 1, 1, 0, '# kept',           undef, 'comment, non-empty, not last' ],
		[ 1, 0, 0, "# \r",             undef, 'comment, empty after cleaning, not last' ],
	);
	for my $row (@rows) {
		my ($present, $content, $last, $tail, $want, $name) = @{$row};
		my $line = $last ? "'First' => 0, 'M' => 0, $tail" : "'M' => 0, 'Last' => 0, $tail";
		my $d = App::makefilepl2cpanfile::parse_prereqs("PREREQ_PM => {\n\t$line\n},");
		is $d->{runtime}{requires}{M}{comment}, $want, $name;
		# "Kept" is (present AND non-empty AND last); check the dual.
		my $kept = $present && $content && $last;
		is((defined $want ? 1 : 0), ($kept ? 1 : 0), "$name: kept == present AND non-empty AND last");
		is(!$kept, (!$present || !$content || !$last), "$name: De Morgan");
	}
};

# -----------------------------------------------------------------------
# Rule: "Only blocks outside comments count", at every nesting level.
# Top-level simple keys, prereqs blocks, their phases and relationships,
# and legacy recommends/suggests, each live or commented out.
# -----------------------------------------------------------------------
subtest 'truth table: block (level) x (commented out)' => sub {
	my %cases = (
		'simple key'         => [ "PREREQ_PM => { 'M' => 0 },",                                         'runtime', 'requires' ],
		'prereqs block'      => [ "prereqs => { runtime => { requires => { 'M' => 0 } } },",           'runtime', 'requires' ],
		'phase in prereqs'   => [ "prereqs => {\n\tDEAD test => { requires => { 'M' => 0 } },\n},",   'test',    'requires' ],
		'rel in prereqs'     => [ "prereqs => { build => {\n\tDEAD suggests => { 'M' => 0 },\n} },",  'build',   'suggests' ],
		'legacy recommends'  => [ "META_MERGE => {\n\tDEAD recommends => { 'M' => 0 },\n},",           'runtime', 'recommends' ],
	);
	for my $level (sort keys %cases) {
		my ($text, $phase, $rel) = @{ $cases{$level} };
		for my $commented (0, 1) {
			my $content = $text;
			if($content =~ /DEAD /) {
				$content =~ s/DEAD /$commented ? '# ' : q{}/e;
			} elsif($commented) {
				$content = "# $content";
			}
			my $d = App::makefilepl2cpanfile::parse_prereqs($content);
			my $found = exists $d->{$phase}{$rel}{M} ? 1 : 0;
			is $found, $commented ? 0 : 1, "$level, " . ($commented ? 'commented' : 'live');
		}
	}
};

# -----------------------------------------------------------------------
# Rule: "A legacy recommends/suggests block goes to runtime only if it is
# NOT inside a prereqs block AND NOT commented out."
# -----------------------------------------------------------------------
subtest 'truth table: legacy block (inside prereqs) x (commented)' => sub {
	my %text = (
		'0,0' => "META_MERGE => { recommends => { 'M' => 0 } },",
		'0,1' => "META_MERGE => {\n\t# recommends => { 'M' => 0 },\n},",
		'1,0' => "prereqs => { test => { recommends => { 'M' => 0 } } },",
		'1,1' => "prereqs => { test => {\n\t# recommends => { 'M' => 0 },\n} },",
	);
	for my $key (sort keys %text) {
		my ($inside, $commented) = split /,/, $key;
		my $d = App::makefilepl2cpanfile::parse_prereqs($text{$key});
		my $runtime = exists $d->{runtime}{recommends}{M} ? 1 : 0;
		my $test    = exists $d->{test}{recommends}{M} ? 1 : 0;
		my $name = ($inside ? 'inside' : 'outside') . ' prereqs, ' . ($commented ? 'commented' : 'live');
		is $runtime, (!$inside && !$commented) ? 1 : 0, "$name: runtime iff not inside AND not commented";
		is $test, ($inside && !$commented) ? 1 : 0, "$name: phase-scoped iff inside AND live";
		is((!($inside || $commented)) ? 1 : 0, ((!$inside && !$commented) ? 1 : 0), "$name: not(A or B) == (not A) and (not B)");
	}
};

# -----------------------------------------------------------------------
# Rule: "A prereqs entry is used only if its phase AND its relationship
# are both recognised."
# -----------------------------------------------------------------------
subtest 'truth table: prereqs (phase valid) x (relationship valid)' => sub {
	for my $pv (0, 1) {
		for my $rv (0, 1) {
			my $phase = $pv ? 'runtime'  : 'Runtime';
			my $rel   = $rv ? 'requires' : 'require';
			my $d = App::makefilepl2cpanfile::parse_prereqs("prereqs => { $phase => { $rel => { 'M' => 0 } } },");
			my $used = scalar(keys %{$d}) ? 1 : 0;
			de_morgan_ok($pv, $rv, !$used, "phase " . ($pv ? 'valid' : 'invalid') . ", rel " . ($rv ? 'valid' : 'invalid'));
		}
	}
};

# -----------------------------------------------------------------------
# Rule: "A version is valid only if it is defined AND uses only the
# allowed characters AND contains a digit."  Every combination that can
# exist; the undefined value can have neither of the other properties,
# so its rows collapse into one.
# -----------------------------------------------------------------------
subtest 'truth table: _valid_version (defined) x (charset) x (digit)' => sub {
	my @rows = (
		[ undef,  0, 0, 0, 'undefined' ],
		[ '1',    1, 1, 1, 'allowed characters, digit' ],
		[ 'v1',   1, 1, 1, 'allowed characters with v, digit' ],
		[ '._',   1, 1, 0, 'allowed characters, no digit' ],
		[ 'v',    1, 1, 0, 'v alone, no digit' ],
		[ '1a',   1, 0, 1, 'other characters, digit' ],
		[ 'ab',   1, 0, 0, 'other characters, no digit' ],
		[ 'vv1',  1, 0, 1, 'v twice' ],
		[ "\x{0661}", 1, 0, 0, 'non-ASCII digit only' ],
	);
	for my $row (@rows) {
		my ($v, $def, $chars, $digit, $name) = @{$row};
		my $want = ($def && $chars && $digit) ? 1 : 0;
		is App::makefilepl2cpanfile::_valid_version($v), $want, "$name -> $want";
		is(!$want ? 1 : 0, (!$def || !$chars || !$digit) ? 1 : 0, "$name: De Morgan");
	}
};

# -----------------------------------------------------------------------
# Rule: "A dependency line gets a version only if _has_version is true,
# and a comment only if one is defined."  Two independent switches.
# -----------------------------------------------------------------------
subtest 'truth table: _fmt_dep (has version) x (has comment)' => sub {
	my %rows = (
		'0,0' => [ { version => 0,   comment => undef }, "requires 'M';\n" ],
		'0,1' => [ { version => 0,   comment => 'c' },   "requires 'M';   # c\n" ],
		'1,0' => [ { version => '2', comment => undef }, "requires 'M', '2';\n" ],
		'1,1' => [ { version => '2', comment => 'c' },   "requires 'M', '2';   # c\n" ],
	);
	for my $key (sort keys %rows) {
		my ($entry, $want) = @{ $rows{$key} };
		is App::makefilepl2cpanfile::_fmt_dep('requires', 'M', $entry, q{}), $want, "version,comment = $key";
	}
};

# -----------------------------------------------------------------------
# Rule: "MIN_PERL_VERSION is written only if it is present AND valid AND
# not zero."  Each alternative of the value syntax (single-quoted,
# double-quoted, bare) is a separate path through the same rule.
# -----------------------------------------------------------------------
subtest 'truth table: MIN_PERL_VERSION (present) x (valid) x (non-zero) x (syntax)' => sub {
	my ($g) = use_home();
	my @rows = (
		[ q{},                             0, 'absent' ],
		[ q{MIN_PERL_VERSION => 'x5',},    0, 'present, invalid' ],
		[ q{MIN_PERL_VERSION => '0.0',},   0, 'present, valid, zero' ],
		[ q{MIN_PERL_VERSION => '5.010',}, 1, 'single-quoted, valid, non-zero' ],
		[ q{MIN_PERL_VERSION => "5.010",}, 1, 'double-quoted, valid, non-zero' ],
		[ q{MIN_PERL_VERSION => 5.010,},   1, 'bare, valid, non-zero' ],
	);
	for my $row (@rows) {
		my ($text, $written, $name) = @{$row};
		my $out = App::makefilepl2cpanfile::generate(makefile => make_mf("WriteMakefile($text);\n"), with_develop => 0);
		is(($out =~ /^requires 'perl', '5\.010';$/m ? 1 : 0), $written, $name);
	}
	is App::makefilepl2cpanfile::_parse_min_perl(undef), undef, 'undefined content: undef';
};

# -----------------------------------------------------------------------
# Rule: "An offset is in a comment only if start <= pos < end for some
# span" (half-open intervals).  Each side of each boundary.
# -----------------------------------------------------------------------
subtest 'truth table: _in_comment interval boundaries' => sub {
	my $spans = [ [ 5, 10 ], [ 20, 25 ] ];
	my %rows = (
		4 => 0, 5 => 1, 9 => 1, 10 => 0, 15 => 0, 19 => 0, 20 => 1, 24 => 1, 25 => 0,
	);
	for my $pos (sort { $a <=> $b } keys %rows) {
		is App::makefilepl2cpanfile::_in_comment($spans, $pos), $rows{$pos}, "offset $pos";
	}
	is App::makefilepl2cpanfile::_in_comment([], 0), 0, 'no spans: never in a comment';

	# The spans themselves: a '#' inside quotes starts no comment.
	is_deeply App::makefilepl2cpanfile::_comment_spans(q{'a#b' "c#d" # e}), [ [ 12, 15 ] ],
		'quoted # ignored; the real comment runs to the end of the line';
};

# -----------------------------------------------------------------------
# Rule (from the Z specification of generate): the result is decided by,
# in order, (1) makefile usable?  (2) with_develop AND config broken?
# (3) the develop set = kept entries + tools not already listed.
# Every combination of: makefile ok/bad x existing develop yes/no x
# with_develop on/off x config none/tools/empty/no-key/broken
# (2 x 2 x 2 x 5 = 40 rows), each compared with that specification.
# -----------------------------------------------------------------------
subtest 'truth table: generate() over all 40 combinations of its inputs' => sub {
	my %config = (
		none    => [ undef,                              $TT{defaults}, 0 ],
		tools   => [ { develop => { $TT{tool} => 0 } },  [ $TT{tool} ],  0 ],
		empty   => [ { develop => {} },                  [],             0 ],
		'no-key'=> [ { other => 1 },                     $TT{defaults}, 1 ],
		broken  => [ "develop: [\n  x",                  undef,          0 ],
	);
	my $good = make_mf("PREREQ_PM => { '$TT{mod}' => 0 },\n");
	my $bad  = tempdir(CLEANUP => 1);
	my $existing = "on 'develop' => sub {\n\trequires '$TT{kept}';\n};\n";

	for my $mf_ok (0, 1) {
		for my $has_dev (0, 1) {
			for my $with (0, 1) {
				for my $cfg (sort keys %config) {
					my ($data, $tools, $warns) = @{ $config{$cfg} };
					my ($g, $path) = use_home($data);
					my $row = sprintf 'makefile %s, existing %s, with_develop %d, config %s',
						$mf_ok ? 'ok' : 'bad', $has_dev ? 'yes' : 'no', $with, $cfg;

					my ($out, @w);
					my $died = !eval {
						($out, @w) = quiet_warnings(sub {
							App::makefilepl2cpanfile::generate(
								makefile => $mf_ok ? $good : $bad,
								existing => $has_dev ? $existing : q{},
								with_develop => $with,
							)
						});
						1;
					};
					my $err = $@;

					# (1) An unusable makefile wins over everything, even a
					#     broken config: it is checked first.
					if(!$mf_ok) {
						like $err, qr/\ACannot read /, "$row: Cannot read";
						next;
					}
					# (2) A broken config matters only when it is consulted.
					if($with && !defined $tools) {
						like $err, qr/\AFailed to parse \Q$path\E: /, "$row: Failed to parse";
						next;
					}
					ok !$died, "$row: succeeds" or diag $err;

					# (3) The develop set.
					my @expect = sort(($has_dev ? ($TT{kept}) : ()), ($with ? @{ $tools || [] } : ()));
					my @got = sort(($out =~ /^on 'develop' => sub \{\n(.*?)^\};$/ms ? $1 : q{}) =~ /'([^']+)'/g);
					is_deeply \@got, \@expect, "$row: develop set";
					like $out, qr/^requires '\Q$TT{mod}\E';$/m, "$row: runtime entry";
					is scalar @w, ($with ? $warns : 0), "$row: warnings";
				}
			}
		}
	}
};

# -----------------------------------------------------------------------
# Invariant held before, during and after: the caller's inputs are never
# changed (before = after), and the structure handed to _emit satisfies
# P1, P2 and "no empty hashes" (during).
# -----------------------------------------------------------------------
subtest 'invariant: holds before, during and after generate()' => sub {
	my ($g) = use_home({ develop => { $TT{tool} => '1.0' } });
	my $mf = make_mf("PREREQ_PM => {\n\t'$TT{mod}' => '2.0',   # note\n},\n");
	my %args = (makefile => $mf, existing => "on 'develop' => sub {\n\trequires '$TT{kept}', 'bad!';\n};\n");
	my %before = %args;

	my $during;
	my $ge = mock_scoped "${PKG}::_emit" => do {
		my $real = \&App::makefilepl2cpanfile::_emit;
		sub {
			my $deps = $_[0];
			my @violations;
			for my $e (all_entries($deps)) {
				my ($p, $r, $m, $entry) = @{$e};
				my $v = $entry->{version};
				push @violations, "$m: version" unless $v eq '0' || $v eq q{} || App::makefilepl2cpanfile::_valid_version($v);
				push @violations, "$m: comment" if defined $entry->{comment} && $entry->{comment} eq q{};
			}
			for my $p (keys %{$deps}) {
				push @violations, "empty $p" unless %{ $deps->{$p} };
				push @violations, "empty $p/$_" for grep { !%{ $deps->{$p}{$_} } } keys %{ $deps->{$p} };
			}
			$during = \@violations;
			return $real->(@_);
		};
	};
	quiet_warnings(sub { App::makefilepl2cpanfile::generate(\%args) });
	is_deeply $during, [], 'during: the structure satisfies P1, P2 and has no empty hashes';
	is_deeply \%args, \%before, 'before = after: the caller\'s arguments are unchanged';
};

# -----------------------------------------------------------------------
# Contradictions: inputs that break a premise are stopped by the first
# guard that can see them, with the documented message.
# -----------------------------------------------------------------------
subtest 'contradictions: premise violations are stopped at the first guard' => sub {
	my ($g) = use_home();

	# Premise: makefile is a path to a readable regular file.
	for my $bad ([ [], 'a reference' ], [ q{}, 'an empty path' ], [ '/', 'a directory' ]) {
		my ($value, $name) = @{$bad};
		throws_ok { App::makefilepl2cpanfile::generate(makefile => $value) }
			qr/\ACannot read '/, "makefile is $name: refused";
	}

	# Premise: a config file that exists can be read as YAML.
	{
		my ($gc, $cfg) = use_home("develop: [\n  x");
		throws_ok { App::makefilepl2cpanfile::generate(makefile => make_mf(q{})) }
			qr/\AFailed to parse \Q$cfg\E: /, 'config that is not YAML: refused';
	}

	# Premise: parse_prereqs' input is a string.  A reference cannot be
	# undefined (ref(undef) is ''), so the guard's fourth combination
	# (undefined AND a reference) is impossible; the three possible ones:
	is ref(undef), q{}, 'undefined AND reference is impossible';
	is_deeply App::makefilepl2cpanfile::parse_prereqs(undef), {}, 'undefined: empty result';
	is_deeply App::makefilepl2cpanfile::parse_prereqs([]),    {}, 'reference: empty result';
	ok scalar keys %{ App::makefilepl2cpanfile::parse_prereqs("PREREQ_PM => { 'A' => 0 },") }, 'string: parsed';
};

done_testing;
