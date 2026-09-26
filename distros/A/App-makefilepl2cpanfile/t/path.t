use strict;
use warnings;

# Path-coverage tests: one case for every distinct path through every
# routine in lib/App/makefilepl2cpanfile.pm, including early exits,
# implicit else branches, and loops taken zero and many times.
#
# Each path has an ID in %PATHS, written as ROUTINE.N with a short
# description of the route through the control-flow graph.  A test that
# drives execution down a path calls took() with its ID; the last subtest
# fails if any path was never taken.
#
# Path analysis found no dead code and no loop that runs exactly once or
# at most once:
#   - loops over fixed lists (@REL_ORDER, %PHASE_MAP, 'runtime' plus
#     @PHASE_ORDER) always run 3, 4 and 5 times;
#   - every data-driven loop (lines, pairs, matches, config keys, binary
#     search) is reachable with zero and with several iterations.
# The only unreachable outcomes are the all-undef ends of '//' chains that
# follow a regex alternation: each alternative captures into its own
# group, so a successful match always defines one of them.  Those are
# proved impossible in the last-but-one subtest rather than marked dead,
# because each '//' is still needed to choose the defined group.

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use lib 't/lib';
use Test::Permissions qw(can_revoke_read can_revoke_search);
use File::Temp qw(tempdir);
use Path::Tiny;
use POSIX qw(EIO);
use Readonly;
use YAML::Tiny;

use App::makefilepl2cpanfile;

Readonly my $PKG => 'App::makefilepl2cpanfile';

Readonly my %CFG => (
	header   => '# Generated from Makefile.PL using makefilepl2cpanfile',
	cfg_dir  => '.config',
	cfg_file => 'makefilepl2cpanfile.yml',
	io_error => 'Input/output error',
	yaml_err => 'synthetic YAML error',
	defaults => [qw(Devel::Cover Perl::Critic Test::Pod Test::Pod::Coverage)],
);

my %PATHS = (
	# generate()
	'G.1'  => 'makefile guard fails: not a regular file -> croak',
	'G.17' => 'makefile guard fails: regular file, unreadable -> croak',
	'G.2'  => 'makefile undef -> default Makefile.PL',
	'G.3'  => 'UTF-8 read ok, no develop block, with_develop false -> emit',
	'G.4'  => 'UTF-8 read dies with a decode error -> carp, raw read',
	'G.5'  => 'UTF-8 read dies with another error -> rethrown',
	'G.6'  => 'existing develop: invalid name -> next',
	'G.7'  => 'existing develop: no version',
	'G.8'  => "existing develop: empty version ''",
	'G.9'  => 'existing develop: valid version',
	'G.10' => 'existing develop: invalid version -> carp, 0',
	'G.11' => 'existing develop: module already defined -> first kept',
	'G.12' => 'existing develop: double-quoted name and version',
	'G.13' => 'existing develop block with zero entries (while runs 0 times)',
	'G.14' => 'with_develop: tool already listed -> not added',
	'G.15' => 'with_develop: tool not listed -> added',
	'G.16' => 'with_develop: config empty -> injection loop runs 0 times',

	# parse_prereqs()
	'P.1'  => 'undef -> {}',
	'P.2'  => 'reference -> {}',
	'P.3'  => 'simple key block live -> extracted',
	'P.4'  => 'simple key block in a comment -> skipped',
	'P.5'  => 'no dependency blocks at all (every while runs 0 times)',
	'P.6'  => 'prereqs block in a comment -> skipped',
	'P.7'  => 'prereqs: unknown phase -> next',
	'P.8'  => 'prereqs: phase in a comment -> next',
	'P.9'  => 'prereqs: unknown relationship -> next',
	'P.10' => 'prereqs: relationship in a comment -> next',
	'P.11' => 'prereqs: phase and relationship valid -> extracted',
	'P.12' => 'legacy block inside a prereqs span -> skipped',
	'P.13' => 'legacy block in a comment -> skipped',
	'P.14' => 'legacy block live -> runtime',
	'P.15' => 'legacy block before a prereqs span (span test fails on start)',

	# _extract_pairs()
	'E.1'  => 'empty block -> line loop runs 0 times',
	'E.2'  => 'line with neither comment nor pair',
	'E.3'  => 'comment that is non-empty after cleaning',
	'E.4'  => 'comment that is empty after cleaning -> undef',
	'E.5'  => 'pair with an invalid name -> next',
	'E.6'  => 'pair with an invalid version -> 0',
	'E.7'  => 'pair with a valid version',
	'E.8'  => 'several pairs: comment only on the last',
	'E.9'  => 'duplicate -> //= keeps the first',
	'E.10' => 'version as single-quoted, double-quoted and bare token',
	'E.11' => 'no version token at all -> 0',

	# _parse_min_perl()
	'M.1'  => 'content undef -> undef',
	'M.2'  => 'no MIN_PERL_VERSION -> undef',
	'M.3'  => 'present but invalid -> undef',
	'M.4'  => 'single-quoted valid',
	'M.5'  => 'double-quoted valid',
	'M.6'  => 'bare valid',

	# _comment_spans() / _in_comment()
	'C.1'  => "content '' -> no lines",
	'C.2'  => 'line without #',
	'C.3'  => '# only inside quotes -> no span',
	'C.4'  => 'real comment -> span to end of line',
	'C.5'  => 'several lines -> offsets accumulate',
	'I.1'  => 'no spans -> search loop runs 0 times',
	'I.2'  => 'pos before a span -> move left',
	'I.3'  => 'pos at or after a span end -> move right',
	'I.4'  => 'pos inside a span -> 1',

	# _valid_version()
	'V.1'  => 'undef -> 0',
	'V.2'  => 'disallowed character -> 0',
	'V.3'  => 'allowed characters, no digit -> 0',
	'V.4'  => 'valid -> 1',

	# _load_develop_config()
	'L.1'  => 'home undef -> defaults',
	'L.2'  => "home '' -> defaults",
	'L.3'  => 'stat fails ENOENT -> defaults',
	'L.4'  => 'stat fails ENOTDIR -> defaults',
	'L.5'  => 'stat fails otherwise -> croak',
	'L.6'  => 'not a regular file -> defaults',
	'L.7'  => 'YAML read dies -> croak with its message, location removed',
	'L.8'  => 'YAML read false, errstr set -> croak with errstr',
	'L.9'  => "YAML read false, errstr undef -> croak with ''",
	'L.10' => 'document is not a hash -> carp, defaults',
	'L.11' => 'develop is not a hash -> carp, defaults',
	'L.12' => 'develop hash empty -> loop runs 0 times -> {}',
	'L.13' => 'invalid name -> carp, next',
	'L.14' => 'version undef -> 0',
	'L.15' => "version '' kept",
	'L.16' => 'invalid version -> carp, 0',
	'L.17' => 'valid version kept',

	# _emit() / _phase_entries() / _fmt_dep() / _has_version()
	'T.1'  => 'no deps, no perl -> header only',
	'T.2'  => 'perl version zero -> no perl line',
	'T.3'  => 'perl version real -> perl line',
	'T.4'  => 'runtime section (unwrapped)',
	'T.5'  => 'other phase section (on-block)',
	'T.6'  => 'phase present but empty -> skipped',
	'Q.1'  => 'phase undef -> []',
	'Q.2'  => 'relationship missing -> skipped',
	'Q.3'  => 'several modules -> sorted',
	'F.1'  => 'no version, no comment',
	'F.2'  => 'no version, comment',
	'F.3'  => 'version, no comment',
	'F.4'  => 'version, comment',
	'H.1'  => 'undef -> 0',
	'H.2'  => 'zero -> 0',
	'H.3'  => 'real version -> 1',

	# Outcomes proved impossible
	'N.1'  => 'name alternation matched with both groups undef',
	'N.2'  => 'MIN_PERL_VERSION token matched with all groups undef',
);

my $PATH_COUNT = scalar keys %PATHS;

sub took {
	for my $id (@_) {
		fail("unknown or repeated path '$id'") unless exists $PATHS{$id};
		delete $PATHS{$id};
	}
	return;
}

# -----------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------

sub make_mf {
	my $mf = path(tempdir(CLEANUP => 1))->child('Makefile.PL');
	$mf->spew_utf8($_[0]);
	return "$mf";
}

sub use_home {
	my $data = $_[0];
	my $home = path(tempdir(CLEANUP => 1));
	my $cfg  = $home->child($CFG{cfg_dir}, $CFG{cfg_file});
	if(defined $data) {
		$cfg->parent->mkpath;
		ref $data ? YAML::Tiny->new($data)->write("$cfg") : $cfg->spew_utf8($data);
	}
	return (mock_scoped('File::HomeDir::my_home' => sub { "$home" }), $cfg, $home);
}

sub warnings_of {
	my $code = $_[0];
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $r = $code->();
	return ($r, @w);
}

sub capture_emit {
	my $slot = $_[0];
	my $real = \&App::makefilepl2cpanfile::_emit;
	return mock_scoped "${PKG}::_emit" => sub { ${$slot} = $_[0]; $real->(@_) };
}

sub parse { return App::makefilepl2cpanfile::parse_prereqs($_[0]) }

# -----------------------------------------------------------------------
# generate(): early exits, the read branches, the merge loop, injection
# -----------------------------------------------------------------------
subtest 'generate() paths' => sub {
	my ($g) = use_home();

	throws_ok { App::makefilepl2cpanfile::generate(makefile => '/no/such/Makefile.PL') }
		qr/\ACannot read '\/no\/such\/Makefile\.PL' at /, 'G.1: guard croaks';
	took('G.1');

	SKIP: {
		skip 'chmod cannot make a file unreadable here (root or Windows)', 1 unless can_revoke_read();
		my $locked = make_mf(q{});
		chmod 0, $locked;
		throws_ok { App::makefilepl2cpanfile::generate(makefile => $locked) }
			qr/\ACannot read '\Q$locked\E' at /, 'G.17: -f true, -r false -> croak';
		chmod 0600, $locked;
	}
	took('G.17');

	{
		my $dir = tempdir(CLEANUP => 1);
		path($dir)->child('Makefile.PL')->spew_utf8("PREREQ_PM => { 'Dflt' => 0 },\n");
		my $cwd = Path::Tiny->cwd;
		chdir $dir or die "chdir: $!";
		my $out = eval { App::makefilepl2cpanfile::generate(makefile => undef, with_develop => 0) };
		chdir $cwd or die "chdir: $!";
		like $out, qr/^requires 'Dflt';$/m, 'G.2: default makefile used';
		took('G.2');
	}

	my $mf = make_mf("PREREQ_PM => { 'M' => 0 },\n");
	my $out = App::makefilepl2cpanfile::generate(makefile => $mf, existing => 'no block here', with_develop => 0);
	is $out, "$CFG{header}\n\nrequires 'M';\n", 'G.3: straight-through path';
	returns_is($out, { type => 'string' }, 'G.3: returns a string');
	took('G.3');

	{
		my $m = mock_scoped(
			'Path::Tiny::slurp_utf8' => sub { die "Can't decode ill-formed UTF-8\n" },
			'Path::Tiny::slurp_raw'  => sub { "PREREQ_PM => { 'Raw' => 0 },\n" },
		);
		my ($o, @w) = warnings_of(sub { App::makefilepl2cpanfile::generate(makefile => $mf, with_develop => 0) });
		like $o, qr/^requires 'Raw';$/m, 'G.4: raw content used';
		like $w[0], qr/\AWarning: '\Q$mf\E' contains invalid UTF-8; reading as raw bytes: /, 'G.4: warned';
		took('G.4');
	}
	{
		my $m = mock_scoped 'Path::Tiny::slurp_utf8' => sub { die "$CFG{io_error}\n" };
		throws_ok { App::makefilepl2cpanfile::generate(makefile => $mf, with_develop => 0) }
			qr/\A\Q$CFG{io_error}\E\n\z/, 'G.5: rethrown unchanged';
		took('G.5');
	}

	# Merge loop: every branch in one develop block, observed at _emit.
	my $seen;
	my $ge = capture_emit(\$seen);
	my $dev_mf = make_mf("prereqs => { develop => { requires => { 'Dup' => '9' } } },\n");
	my (undef, @w) = warnings_of(sub {
		App::makefilepl2cpanfile::generate(makefile => $dev_mf, with_develop => 0, existing => <<'END');
on 'develop' => sub {
	requires 'Bad Name';
	requires 'NoVer';
	requires 'EmptyVer', '';
	requires 'GoodVer', '1.5';
	requires 'BadVer', '1.5x';
	requires 'Dup', '1';
	requires "DQ", "2.5";
};
END
	});
	my $r = $seen->{develop}{requires};
	ok !exists $r->{'Bad Name'},     'G.6: invalid name skipped';
	is $r->{NoVer}{version},    0,     'G.7: no version -> 0';
	is $r->{EmptyVer}{version}, 0,     'G.8: empty version -> 0';
	is $r->{GoodVer}{version},  '1.5', 'G.9: valid version kept';
	is $r->{BadVer}{version},   0,     'G.10: invalid version -> 0';
	is scalar(grep { /BadVer/ } @w), 1, 'G.10: one warning';
	is $r->{Dup}{version},      '9',   'G.11: Makefile.PL entry kept';
	is $r->{DQ}{version},       '2.5', 'G.12: double quotes';
	took(map { "G.$_" } 6 .. 12);

	App::makefilepl2cpanfile::generate(makefile => $mf, with_develop => 0, existing => "on 'develop' => sub {\n};\n");
	ok !exists $seen->{develop}, 'G.13: empty develop block adds nothing';
	took('G.13');

	{
		my ($gc) = use_home({ develop => { Listed => '9', Fresh => '1' } });
		App::makefilepl2cpanfile::generate(makefile => $mf, existing => "on 'develop' => sub {\n\trecommends 'Listed';\n};\n");
		ok !exists $seen->{develop}{requires}{Listed}, 'G.14: listed tool not added';
		is $seen->{develop}{requires}{Fresh}{version}, '1', 'G.15: unlisted tool added';
		took('G.14', 'G.15');
	}
	{
		my ($gc) = use_home({ develop => {} });
		App::makefilepl2cpanfile::generate(makefile => $mf, with_develop => 1);
		ok !exists $seen->{develop}, 'G.16: no tools, nothing added';
		took('G.16');
	}
};

# -----------------------------------------------------------------------
# parse_prereqs(): guard, the three scanning loops and their branches
# -----------------------------------------------------------------------
subtest 'parse_prereqs() paths' => sub {
	is_deeply parse(undef), {}, 'P.1';
	is_deeply parse([]),    {}, 'P.2';
	took('P.1', 'P.2');

	ok exists parse("PREREQ_PM => { 'A' => 0 },")->{runtime}{requires}{A}, 'P.3';
	is_deeply parse("# PREREQ_PM => { 'A' => 0 },"), {}, 'P.4';
	is_deeply parse('WriteMakefile(NAME => "x");'), {}, 'P.5';
	is_deeply parse("# prereqs => { runtime => { requires => { 'A' => 0 } } },"), {}, 'P.6';
	took(map { "P.$_" } 3 .. 6);

	my $d = parse(<<'END');
prereqs => {
	bogus => { requires => { 'P7' => 0 } },
	# test => { requires => { 'P8' => 0 } },
	build => {
		wanted => { 'P9' => 0 },
		# suggests => { 'P10' => 0 },
		requires => { 'P11' => 0 },
	},
	configure => { recommends => { 'P12' => 0 } },
},
META_MERGE => {
	# suggests => { 'P13' => 0 },
	recommends => { 'P14' => 0 },
},
END
	ok !exists $d->{bogus},                    'P.7: unknown phase';
	ok !exists $d->{test},                     'P.8: commented phase';
	ok !exists $d->{build}{wanted},            'P.9: unknown relationship';
	ok !exists $d->{build}{suggests},          'P.10: commented relationship';
	ok exists $d->{build}{requires}{P11},      'P.11: extracted';
	ok exists $d->{configure}{recommends}{P12}, 'P.12: block inside prereqs stays in its phase ...';
	is_deeply [ keys %{ $d->{runtime}{recommends} } ], ['P14'],
		'P.12: ... and the legacy scan skipped it; P.14: the live legacy block reached runtime';
	ok !exists $d->{runtime}{suggests},        'P.13: commented legacy block';
	took(map { "P.$_" } 7 .. 14);

	my $before = parse("META_MERGE => { suggests => { 'Early' => 0 } },
prereqs => { test => { requires => { 'T' => 0 } } },");
	ok exists $before->{runtime}{suggests}{Early}, 'P.15: legacy block ahead of a prereqs span is used';
	took('P.15');
};

# -----------------------------------------------------------------------
# _extract_pairs(): the line loop, comment branches, the pair loop
# -----------------------------------------------------------------------
subtest '_extract_pairs() paths' => sub {
	my $x = sub {
		my %deps;
		App::makefilepl2cpanfile::_extract_pairs($_[0], \%deps, 'runtime', 'requires');
		return $deps{runtime}{requires} || {};
	};

	is_deeply $x->(q{}), {}, 'E.1: empty block';
	is_deeply $x->("\n\tNAME => x,\n"), {}, 'E.2: nothing on the line';
	is $x->("'A' => 0, # note")->{A}{comment}, 'note', 'E.3: comment kept';
	is $x->("'A' => 0, # \x{202E}")->{A}{comment}, undef, 'E.4: comment cleaned away';
	is_deeply $x->("'Bad Name' => 0,"), {}, 'E.5: invalid name';
	is $x->("'A' => '1x',")->{A}{version}, 0, 'E.6: invalid version';
	is $x->("'A' => '1.5',")->{A}{version}, '1.5', 'E.7: valid version';
	my $multi = $x->("'A' => 0, 'B' => 0, # last");
	is_deeply [ $multi->{A}{comment}, $multi->{B}{comment} ], [ undef, 'last' ], 'E.8: comment on the last pair';
	is $x->("'A' => '1',\n'A' => '2',")->{A}{version}, '1', 'E.9: first kept';
	is_deeply [ map { $x->("'A' => $_,")->{A}{version} } q{'1'}, q{"2"}, '3' ], [ 1, 2, 3 ], 'E.10: three token forms';
	is $x->("'A' => ,")->{A}{version}, 0, 'E.11: no token';
	took(map { "E.$_" } 1 .. 11);
};

subtest '_parse_min_perl() paths' => sub {
	my $p = \&App::makefilepl2cpanfile::_parse_min_perl;
	is $p->(undef), undef, 'M.1';
	is $p->('NAME => 1'), undef, 'M.2';
	is $p->("MIN_PERL_VERSION => 'x'"), undef, 'M.3';
	is $p->("MIN_PERL_VERSION => '5.010'"), '5.010', 'M.4';
	is $p->('MIN_PERL_VERSION => "5.012"'), '5.012', 'M.5';
	is $p->('MIN_PERL_VERSION => 5.014,'), '5.014', 'M.6';
	took(map { "M.$_" } 1 .. 6);
};

subtest '_comment_spans() and _in_comment() paths' => sub {
	my $s = \&App::makefilepl2cpanfile::_comment_spans;
	is_deeply $s->(q{}), [], 'C.1';
	is_deeply $s->('no hash here'), [], 'C.2';
	is_deeply $s->(q{'#' "#"}), [], 'C.3';
	is_deeply $s->('ab # c'), [ [ 3, 6 ] ], 'C.4';
	is_deeply $s->("x\n# y\nz # w"), [ [ 2, 5 ], [ 8, 11 ] ], 'C.5';
	took(map { "C.$_" } 1 .. 5);

	my $i = \&App::makefilepl2cpanfile::_in_comment;
	is $i->([], 3), 0, 'I.1';
	is $i->([ [ 10, 20 ] ], 5), 0, 'I.2';
	is $i->([ [ 10, 20 ] ], 20), 0, 'I.3';
	is $i->([ [ 10, 20 ], [ 30, 40 ] ], 35), 1, 'I.4 (after moving right past the first span)';
	took(map { "I.$_" } 1 .. 4);
};

subtest '_valid_version() paths' => sub {
	my $v = \&App::makefilepl2cpanfile::_valid_version;
	is $v->(undef), 0, 'V.1';
	is $v->('1x'), 0, 'V.2';
	is $v->('._'), 0, 'V.3';
	is $v->('v1.2'), 1, 'V.4';
	took(map { "V.$_" } 1 .. 4);
};

# -----------------------------------------------------------------------
# _load_develop_config(): every guard clause and the validation loop
# -----------------------------------------------------------------------
subtest '_load_develop_config() paths' => sub {
	my $load = \&App::makefilepl2cpanfile::_load_develop_config;
	my %defaults = map { $_ => 0 } @{ $CFG{defaults} };

	for my $case ([ undef, 'L.1' ], [ q{}, 'L.2' ]) {
		my $g = mock_scoped 'File::HomeDir::my_home' => sub { $case->[0] };
		is_deeply $load->(), \%defaults, $case->[1];
		took($case->[1]);
	}
	{
		my ($g) = use_home();
		is_deeply $load->(), \%defaults, 'L.3: ENOENT';
		took('L.3');
	}
	{
		# ~/.config is a file, so the config path fails with ENOTDIR.
		my ($g, $cfg, $home) = use_home();
		$home->child($CFG{cfg_dir})->spew_utf8('not a directory');
		is_deeply $load->(), \%defaults, 'L.4: ENOTDIR';
		took('L.4');
	}
	SKIP: {
		skip 'chmod cannot make a directory unsearchable here (root or Windows)', 1 unless can_revoke_search();
		my ($g, $cfg) = use_home({ develop => {} });
		chmod 0, $cfg->parent->stringify;
		throws_ok { $load->() } qr/\AFailed to parse \Q$cfg\E: \S/, 'L.5: other stat error';
		chmod 0755, $cfg->parent->stringify;
	}
	took('L.5');
	{
		my ($g, $cfg) = use_home();
		$cfg->mkpath;
		is_deeply $load->(), \%defaults, 'L.6: not a regular file';
		took('L.6');
	}

	my ($g, $cfg) = use_home({ develop => { Placeholder => 0 } });
	{
		my $m = mock_scoped 'YAML::Tiny::read' => sub { die "$CFG{yaml_err} at /x/YAML/Tiny.pm line 42.\n" };
		throws_ok { $load->() } qr/\AFailed to parse \Q$cfg\E: \Q$CFG{yaml_err}\E at /, 'L.7: location removed';
		took('L.7');
	}
	{
		my $m = mock_scoped('YAML::Tiny::read' => sub { undef }, 'YAML::Tiny::errstr' => sub { $CFG{yaml_err} });
		throws_ok { $load->() } qr/\AFailed to parse \Q$cfg\E: \Q$CFG{yaml_err}\E at /, 'L.8: errstr used';
		took('L.8');
	}
	{
		my $m = mock_scoped('YAML::Tiny::read' => sub { undef }, 'YAML::Tiny::errstr' => sub { undef });
		throws_ok { $load->() } qr/\AFailed to parse \Q$cfg\E:  at /, "L.9: '' when errstr is undef";
		took('L.9');
	}
	for my $case ([ bless([ 'text' ], 'YAML::Tiny'), 'L.10' ], [ bless([ { develop => [] } ], 'YAML::Tiny'), 'L.11' ]) {
		my $m = mock_scoped 'YAML::Tiny::read' => sub { $case->[0] };
		my ($r, @w) = warnings_of($load);
		is_deeply $r, \%defaults, "$case->[1]: defaults";
		like $w[0], qr/\ANo 'develop' key found in /, "$case->[1]: warned";
		took($case->[1]);
	}
	{
		my $m = mock_scoped 'YAML::Tiny::read' => sub { bless [ { develop => {} } ], 'YAML::Tiny' };
		is_deeply $load->(), {}, 'L.12: empty develop hash';
		took('L.12');
	}
	{
		my $m = mock_scoped 'YAML::Tiny::read' => sub {
			bless [ { develop => { 'Bad Name' => 0, Nul => undef, Empty => q{}, Wrong => '1x', Right => '2.0' } } ], 'YAML::Tiny'
		};
		my ($r, @w) = warnings_of($load);
		is_deeply $r, { Nul => 0, Empty => q{}, Wrong => 0, Right => '2.0' }, 'L.13-L.17: each entry branch';
		is scalar @w, 2, 'L.13, L.16: one warning each';
		took(map { "L.$_" } 13 .. 17);
	}
};

# -----------------------------------------------------------------------
# Output: _emit and its helpers
# -----------------------------------------------------------------------
subtest '_emit() and helper paths' => sub {
	my $e = \&App::makefilepl2cpanfile::_emit;
	my $entry = { version => 0, comment => undef };
	is $e->({}, undef), "$CFG{header}\n", 'T.1';
	is $e->({}, '0.0'), "$CFG{header}\n", 'T.2';
	is $e->({}, '5.010'), "$CFG{header}\n\nrequires 'perl', '5.010';\n", 'T.3';
	is $e->({ runtime => { requires => { R => $entry } } }, undef), "$CFG{header}\n\nrequires 'R';\n", 'T.4';
	is $e->({ test => { requires => { T => $entry } } }, undef),
		"$CFG{header}\n\non 'test' => sub {\n\trequires 'T';\n};\n", 'T.5';
	is $e->({ build => { requires => {} } }, undef), "$CFG{header}\n", 'T.6';
	took(map { "T.$_" } 1 .. 6);

	my $q = \&App::makefilepl2cpanfile::_phase_entries;
	is_deeply $q->(undef), [], 'Q.1';
	is_deeply $q->({ suggests => { S => $entry } }), [ [ 'suggests', 'S', $entry ] ], 'Q.2';
	is_deeply [ map { $_->[1] } @{ $q->({ requires => { B => $entry, A => $entry } }) } ], [qw(A B)], 'Q.3';
	took(map { "Q.$_" } 1 .. 3);

	my $f = \&App::makefilepl2cpanfile::_fmt_dep;
	is $f->('requires', 'M', { version => 0,   comment => undef }, q{}), "requires 'M';\n",           'F.1';
	is $f->('requires', 'M', { version => 0,   comment => 'c' },   q{}), "requires 'M';   # c\n",     'F.2';
	is $f->('requires', 'M', { version => '1', comment => undef }, q{}), "requires 'M', '1';\n",      'F.3';
	is $f->('requires', 'M', { version => '1', comment => 'c' },   q{}), "requires 'M', '1';   # c\n", 'F.4';
	took(map { "F.$_" } 1 .. 4);

	my $h = \&App::makefilepl2cpanfile::_has_version;
	is $h->(undef), 0, 'H.1';
	is $h->('0.0'), 0, 'H.2';
	is $h->('0.1'), 1, 'H.3';
	took(map { "H.$_" } 1 .. 3);
};

# -----------------------------------------------------------------------
# Impossible outcomes
#
# Each capture group sits in one arm of a regex alternation, so a match
# always defines at least one of them: the final undef of a '//' chain
# can never be produced.  Proved by trying every arm and checking that
# exactly one group is defined each time.
# -----------------------------------------------------------------------
subtest 'impossible paths: all-undef capture chains' => sub {
	my $name_re = qr/(?:'([^'\n]++)'|"([^"\n]++)")\s*=>/;
	for my $text (q{'A' =>}, q{"A" =>}) {
		ok $text =~ $name_re, "N.1: '$text' matches";
		is scalar(grep { defined } $1, $2), 1, "N.1: exactly one name group defined for $text";
	}
	my $token_re = qr/(?:'([^'\n]*+)'|"([^"\n]*+)"|([^\s,}#'"]++))/;
	for my $text (q{'1'}, q{"1"}, '1') {
		ok $text =~ /\A$token_re/, "N.2: $text matches";
		is scalar(grep { defined } $1, $2, $3), 1, "N.2: exactly one token group defined for $text";
	}
	took('N.1', 'N.2');
};

subtest 'path ledger: every path was taken' => sub {
	if(%PATHS) {
		fail("path never taken: $_ - $PATHS{$_}") for sort keys %PATHS;
	} else {
		pass("all $PATH_COUNT paths taken");
	}
};

done_testing;
