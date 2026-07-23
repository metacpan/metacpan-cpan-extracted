use strict;
use warnings;

# Integration tests for App::makefilepl2cpanfile.
#
# These tests validate end-to-end workflows that cross function boundaries:
# parse_prereqs() feeding generate(), config loading interacting with the
# develop block, develop-merge semantics, format invariants across scenarios,
# and statelessness under repeated or interleaved calls.
#
# NOTE ON OPTIONAL DEPENDENCIES
# All CPAN dependencies in this module are hard 'use' requirements — there are
# no soft/optional require paths.  Test::Without::Module is therefore not
# applicable.  The closest analog is the OPTIONAL CONFIG FILE at
# ~/.config/makefilepl2cpanfile.yml; its absent/present/malformed paths are
# exercised in dedicated subtests below.

use Test::Most;
use Test::Mockingbird;
use File::Temp qw(tempdir);
use Path::Tiny;
use Readonly;
use YAML::Tiny;

use_ok('App::makefilepl2cpanfile');

# -----------------------------------------------------------------------
# Fixture constants — shared across all subtests.
# -----------------------------------------------------------------------

# Makefile.PL with only PREREQ_PM entries; no version constraints, no comments.
Readonly my $MF_SIMPLE => <<'END';
use ExtUtils::MakeMaker;
WriteMakefile(
	PREREQ_PM => {
		'Moo'     => 0,
		'Try::Tiny' => 0,
	},
);
END

# Makefile.PL with all four simple key types.
Readonly my $MF_ALL_PHASES => <<'END';
use ExtUtils::MakeMaker;
WriteMakefile(
	CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.64' },
	BUILD_REQUIRES     => { 'Module::Build' => '0.42' },
	TEST_REQUIRES      => { 'Test::More' => '0.98' },
	PREREQ_PM          => { 'Scalar::Util' => 0 },
);
END

# Makefile.PL with a MIN_PERL_VERSION declaration.
Readonly my $MF_MIN_PERL => <<'END';
use ExtUtils::MakeMaker;
WriteMakefile(
	MIN_PERL_VERSION => '5.010',
	PREREQ_PM => { 'Moo' => 0 },
);
END

# Makefile.PL with inline comments on dependency lines.
Readonly my $MF_COMMENTS => <<'END';
use ExtUtils::MakeMaker;
WriteMakefile(
	PREREQ_PM => {
		'HTTP::Tiny' => 0,    # used for HTTP calls
		'JSON::PP'   => '2.00', # decode API responses
	},
);
END

# Makefile.PL with a CPAN Meta Spec structured prereqs block.
Readonly my $MF_STRUCTURED => <<'END';
use ExtUtils::MakeMaker;
WriteMakefile(
	prereqs => {
		runtime => {
			requires   => { 'Moo'            => '2.00' },
			recommends => { 'Moo::XS'        => 0      },
			suggests   => { 'MooX::TypeTiny' => 0      },
		},
		test => {
			requires => { 'Test::More' => '0.98' },
		},
	},
);
END

# Makefile.PL with a META_MERGE nested prereqs block (recommends).
Readonly my $MF_META_MERGE => <<'END';
use ExtUtils::MakeMaker;
WriteMakefile(
	PREREQ_PM => { 'Carp' => 0 },
	META_MERGE => {
		prereqs => {
			runtime => {
				recommends => { 'Cpanel::JSON::XS' => '4.00' },
			},
		},
	},
);
END

# Makefile.PL with the same module declared twice: once in PREREQ_PM
# (version 0) and once in a structured requires block (version 2.00).
# The first occurrence should win.
Readonly my $MF_DUPLICATE => <<'END';
use ExtUtils::MakeMaker;
WriteMakefile(
	PREREQ_PM => { 'Moo' => 0 },
	prereqs => {
		runtime => {
			requires => { 'Moo' => '2.00' },
		},
	},
);
END

# An existing cpanfile string with a hand-curated develop block.
Readonly my $EXISTING_DEVELOP => <<'END';
# Generated from Makefile.PL using makefilepl2cpanfile

requires 'Moo';

on 'develop' => sub {
	requires    'My::Linter', '1.00';
	recommends  'My::Formatter';
	suggests    'My::Profiler';
};
END

# -----------------------------------------------------------------------
# Shared infrastructure: mock File::HomeDir so _load_develop_config
# never touches the developer's real home directory.  Each helper returns
# a mock_scoped guard; callers store it (my $g = empty_home()) so the
# mock stays active for the enclosing subtest block, then is auto-restored.
# -----------------------------------------------------------------------

sub empty_home {
	my $h = tempdir( CLEANUP => 1 );
	return mock_scoped 'File::HomeDir::my_home' => sub { $h };
}

sub home_with_config {
	my ($data) = @_;
	my $h = tempdir( CLEANUP => 1 );
	path($h)->child('.config')->mkpath;
	YAML::Tiny->new($data)
		->write( path($h)->child('.config', 'makefilepl2cpanfile.yml')->stringify );
	return mock_scoped 'File::HomeDir::my_home' => sub { $h };
}

sub make_mf {
	my ($content) = @_;
	my $dir = tempdir( CLEANUP => 1 );
	my $mf  = path($dir)->child('Makefile.PL');
	$mf->spew_utf8($content);
	return $mf;
}

# -----------------------------------------------------------------------
# 1. parse_prereqs() ↔ generate() cross-validation
#
# Strategy: for the same Makefile.PL content, every module that
# parse_prereqs() reports must appear in the cpanfile string that
# generate() produces.  This validates the two functions share the same
# parsing logic (they do internally, but we verify the contract here).
# -----------------------------------------------------------------------

subtest 'pipeline: parse_prereqs output consistent with generate output' => sub {
	my $g = empty_home();
	my $mf = make_mf($MF_ALL_PHASES);

	my $content = $mf->slurp_utf8;
	my $parsed  = App::makefilepl2cpanfile::parse_prereqs($content);
	my $out     = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 0,
	);

	diag "generate() output:\n$out" if $ENV{TEST_VERBOSE};

	# Every module parse_prereqs() found must appear in the generated output.
	my @missing;
	for my $phase (sort keys %{$parsed}) {
		for my $rel (sort keys %{ $parsed->{$phase} }) {
			for my $mod (sort keys %{ $parsed->{$phase}{$rel} }) {
				push @missing, "$mod ($phase/$rel)"
					unless $out =~ /\b\Q$mod\E\b/;
			}
		}
	}

	is scalar @missing, 0,
		'all parse_prereqs() modules present in generate() output'
		or diag "Missing: " . join(', ', @missing);

	# Verify each phase mapped to the correct cpanfile output structure.
	like   $out, qr/requires 'Scalar::Util'/,            'PREREQ_PM at top level';
	like   $out, qr/on 'configure' => sub/,              'configure block present';
	like   $out, qr/on 'build' => sub/,                  'build block present';
	like   $out, qr/on 'test' => sub/,                   'test block present';
	unlike $out, qr/on 'runtime' => sub/,                'runtime NOT in on block';
};

# -----------------------------------------------------------------------
# 2. MIN_PERL_VERSION flows through to the cpanfile perl version line
#
# Strategy: verify the complete pipeline from Makefile.PL parsing through
# _emit() — MIN_PERL_VERSION must appear as "requires 'perl', 'X.XXX';"
# in the generate() output and be absent when not declared.
# -----------------------------------------------------------------------

subtest "pipeline: MIN_PERL_VERSION flows through to cpanfile" => sub {
	my $g = empty_home();

	# With MIN_PERL_VERSION declared.
	my $mf_with  = make_mf($MF_MIN_PERL);
	my $out_with = App::makefilepl2cpanfile::generate(
		makefile     => "$mf_with",
		with_develop => 0,
	);
	like $out_with, qr/requires 'perl', '5\.010'/,
		"MIN_PERL_VERSION 5.010 emitted as requires 'perl' line";

	# Without MIN_PERL_VERSION declared.
	my $mf_without  = make_mf($MF_SIMPLE);
	my $out_without = App::makefilepl2cpanfile::generate(
		makefile     => "$mf_without",
		with_develop => 0,
	);
	unlike $out_without, qr/requires 'perl'/,
		"no requires 'perl' line when MIN_PERL_VERSION absent";

	diag "With:\n$out_with\nWithout:\n$out_without" if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# 3. Inline comment round-trip through the full pipeline
#
# Strategy: inline comments in the Makefile.PL must survive the full
# parse_prereqs() → generate() pipeline and appear on the same line as
# the module entry in the cpanfile output.  Both the raw data structure
# (from parse_prereqs) and the rendered string (from generate) are checked.
# -----------------------------------------------------------------------

subtest 'pipeline: inline comments round-trip' => sub {
	my $g = empty_home();
	my $mf = make_mf($MF_COMMENTS);

	# parse_prereqs must capture the comment in the data structure.
	my $content = $mf->slurp_utf8;
	my $parsed  = App::makefilepl2cpanfile::parse_prereqs($content);
	is $parsed->{runtime}{requires}{'HTTP::Tiny'}{comment},
		'used for HTTP calls',
		'parse_prereqs captures first inline comment';
	is $parsed->{runtime}{requires}{'JSON::PP'}{comment},
		'decode API responses',
		'parse_prereqs captures second inline comment';

	# generate must emit the comment on the correct output line.
	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 0,
	);
	like $out, qr/requires 'HTTP::Tiny';\s+#\s*used for HTTP calls/,
		'generate() emits first inline comment after semicolon';
	like $out, qr/requires 'JSON::PP', '2\.00';\s+#\s*decode API responses/,
		'generate() emits second inline comment with version';

	diag "Output:\n$out" if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# 4. Structured prereqs block → recommends and suggests in output
#
# Strategy: a structured 'prereqs => { phase => { rel => { ... } } }' block
# with all three relationship types must produce correct on-phase blocks in
# the generate() output, with entries under the right rel keyword.
# parse_prereqs() must also reflect the full three-level structure.
# -----------------------------------------------------------------------

subtest 'pipeline: structured prereqs block -> recommends/suggests in output' => sub {
	my $g = empty_home();
	my $mf = make_mf($MF_STRUCTURED);

	# Verify parse_prereqs extracts all three relationship types.
	my $content = $mf->slurp_utf8;
	my $parsed  = App::makefilepl2cpanfile::parse_prereqs($content);
	ok exists $parsed->{runtime}{requires}{'Moo'},
		'structured requires extracted by parse_prereqs';
	ok exists $parsed->{runtime}{recommends}{'Moo::XS'},
		'structured recommends extracted by parse_prereqs';
	ok exists $parsed->{runtime}{suggests}{'MooX::TypeTiny'},
		'structured suggests extracted by parse_prereqs';
	ok exists $parsed->{test}{requires}{'Test::More'},
		'structured test/requires extracted by parse_prereqs';

	# Verify generate emits all three rel types in the output.
	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 0,
	);
	like $out, qr/requires\s+'Moo'/,           'requires Moo in output';
	like $out, qr/recommends\s+'Moo::XS'/,     'recommends Moo::XS in output';
	like $out, qr/suggests\s+'MooX::TypeTiny'/, 'suggests MooX::TypeTiny in output';
	like $out, qr/on 'test' => sub/,           'test block in output';

	diag "Output:\n$out" if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# 5. META_MERGE nested prereqs — consistent parse and generate
#
# Strategy: META_MERGE => { prereqs => { ... } } is a common idiom.
# Both parse_prereqs() and generate() must extract deps from it; the
# top-level PREREQ_PM and the nested META_MERGE recommends must coexist.
# -----------------------------------------------------------------------

subtest 'pipeline: META_MERGE nested prereqs consistent across parse and generate' => sub {
	my $g = empty_home();
	my $mf = make_mf($MF_META_MERGE);

	my $content = $mf->slurp_utf8;
	my $parsed  = App::makefilepl2cpanfile::parse_prereqs($content);

	ok exists $parsed->{runtime}{requires}{'Carp'},
		'PREREQ_PM entry extracted';
	ok exists $parsed->{runtime}{recommends}{'Cpanel::JSON::XS'},
		'META_MERGE recommends extracted';
	is $parsed->{runtime}{recommends}{'Cpanel::JSON::XS'}{version}, '4.00',
		'META_MERGE recommends version correct';

	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 0,
	);
	like $out, qr/requires\s+'Carp'/,                       'Carp in output';
	like $out, qr/recommends\s+'Cpanel::JSON::XS', '4\.00'/, 'META_MERGE recommends in output';

	diag "Output:\n$out" if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# 6. First-occurrence-wins for duplicate module declarations
#
# Strategy: when the same module appears in both PREREQ_PM (version 0)
# and a structured requires block (version 2.00), parse_prereqs() and
# generate() must honour the first occurrence (PREREQ_PM, version 0).
# -----------------------------------------------------------------------

subtest 'pipeline: first-occurrence-wins for duplicate module declarations' => sub {
	my $g = empty_home();
	my $mf = make_mf($MF_DUPLICATE);

	my $content = $mf->slurp_utf8;
	my $parsed  = App::makefilepl2cpanfile::parse_prereqs($content);

	# PREREQ_PM is parsed first; its version (0) must win over structured (2.00).
	is $parsed->{runtime}{requires}{'Moo'}{version}, 0,
		'first-occurrence-wins: PREREQ_PM version 0 takes precedence';

	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 0,
	);

	# Version 0 → no version constraint in output (just "requires 'Moo';").
	like   $out, qr/requires 'Moo';/,     'Moo present without version (version 0 wins)';
	unlike $out, qr/requires 'Moo', '2\.00'/, 'version 2.00 from structured block NOT used';

	# Moo must appear exactly once.
	my @hits = ( $out =~ /\bMoo\b/g );
	is scalar @hits, 1, 'Moo appears exactly once in output';

	diag "Output:\n$out" if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# 7. Idempotency: feeding generate() output back as 'existing'
#
# Strategy: generate a cpanfile from a Makefile.PL, then call generate()
# again with that output as the 'existing' argument.  The second output
# must equal the first — regeneration must be stable.
# This verifies that the develop-merge logic does not accumulate duplicates
# or otherwise mutate the output across iterations.
# -----------------------------------------------------------------------

subtest 'pipeline: generate() is idempotent when output fed back as existing' => sub {
	my $g = empty_home();
	my $mf = make_mf($MF_ALL_PHASES);

	my $first = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 0,
	);

	my $second = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		existing     => $first,
		with_develop => 0,
	);

	is $second, $first,
		'generate() is idempotent: second call with own output yields identical result';

	diag "First:\n$first\nSecond:\n$second" if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# 8. Config file interaction: absent config → default develop tools
#
# Strategy: when no config file exists in the (mocked) home dir,
# generate() with with_develop => 1 must inject the built-in defaults
# (Devel::Cover, Perl::Critic, Test::Pod, Test::Pod::Coverage) into the
# develop block.
# -----------------------------------------------------------------------

subtest 'optional config: absent config -> default develop tools injected' => sub {
	my $g = empty_home();    # no config file in fake home
	my $mf  = make_mf($MF_SIMPLE);
	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 1,
	);

	like $out, qr/on 'develop' => sub/,    'develop block present';
	like $out, qr/Perl::Critic/,           'default Perl::Critic injected';
	like $out, qr/Devel::Cover/,           'default Devel::Cover injected';
	like $out, qr/Test::Pod\b/,            'default Test::Pod injected';
	like $out, qr/Test::Pod::Coverage/,    'default Test::Pod::Coverage injected';

	diag "Output:\n$out" if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# 9. Config file interaction: present config with custom tools
#
# Strategy: when a config file with a 'develop' section is present, those
# tools replace the built-in defaults entirely.  Default tools that are NOT
# listed in the config must NOT appear in the output.
# -----------------------------------------------------------------------

subtest 'optional config: present config -> custom tools replace defaults' => sub {
	my $g = home_with_config( {
		develop => {
			'My::CustomTool' => 0,
			'Another::Dev'   => '2.00',
		}
	} );
	my $mf  = make_mf($MF_SIMPLE);
	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 1,
	);

	like $out, qr/My::CustomTool/,    'custom tool from config present';
	like $out, qr/Another::Dev/,      'versioned custom tool from config present';
	unlike $out, qr/Perl::Critic/,    'default Perl::Critic absent (not in config)';
	unlike $out, qr/Devel::Cover/,    'default Devel::Cover absent (not in config)';

	diag "Output:\n$out" if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# 10. Develop merge: existing develop entries preserved; defaults added
#
# Strategy: generate() with with_develop => 1 AND an existing cpanfile that
# has a develop block must:
#   (a) Preserve all three rel types (requires/recommends/suggests) from the
#       existing develop block.
#   (b) Inject default tools that are NOT already present.
#   (c) NOT duplicate tools that already appear in the existing block.
# -----------------------------------------------------------------------

subtest 'develop merge: existing entries preserved, defaults added (with_develop=1)' => sub {
	my $g = empty_home();    # default tools injected (unless already present)
	my $mf  = make_mf($MF_SIMPLE);
	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		existing     => $EXISTING_DEVELOP,
		with_develop => 1,
	);

	# Hand-curated entries across all rel types must survive.
	like $out, qr/requires\s+'My::Linter', '1\.00'/,  'hand-curated requires preserved';
	like $out, qr/recommends\s+'My::Formatter'/,       'hand-curated recommends preserved';
	like $out, qr/suggests\s+'My::Profiler'/,          'hand-curated suggests preserved';

	# Default tools not already in the existing develop must also appear.
	like $out, qr/Perl::Critic/,    'default Perl::Critic added to merged develop';
	like $out, qr/Devel::Cover/,    'default Devel::Cover added to merged develop';

	diag "Output:\n$out" if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# 11. Develop merge with with_develop => 0: existing block preserved,
#     no defaults injected
#
# Strategy: with_develop => 0 suppresses the default-tools injection step.
# Existing develop entries from the 'existing' cpanfile must still be merged
# (the merge step runs independently of with_develop), but no default tools
# should appear.
# -----------------------------------------------------------------------

subtest 'develop merge: existing entries preserved, no defaults (with_develop=0)' => sub {
	my $g = empty_home();
	my $mf  = make_mf($MF_SIMPLE);
	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		existing     => $EXISTING_DEVELOP,
		with_develop => 0,
	);

	like   $out, qr/My::Linter/,     'hand-curated requires still merged';
	like   $out, qr/My::Formatter/,  'hand-curated recommends still merged';
	like   $out, qr/My::Profiler/,   'hand-curated suggests still merged';
	unlike $out, qr/Perl::Critic/,   'default Perl::Critic NOT injected (with_develop=0)';
	unlike $out, qr/Devel::Cover/,   'default Devel::Cover NOT injected (with_develop=0)';

	diag "Output:\n$out" if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# 12. Hand-curated develop entry not overwritten by default injection
#
# Strategy: if a default tool (Perl::Critic) appears in the existing
# cpanfile's develop block with a pinned version, generate() must not
# add a second un-versioned entry for it.  The pinned version wins.
# -----------------------------------------------------------------------

subtest 'develop merge: hand-curated version-pinned entry not overwritten by default' => sub {
	my $g = empty_home();
	my $mf = make_mf($MF_SIMPLE);

	Readonly my $EXISTING_PINNED => <<'END';
on 'develop' => sub {
	requires 'Perl::Critic', '1.140';
};
END

	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		existing     => $EXISTING_PINNED,
		with_develop => 1,
	);

	# Perl::Critic must appear exactly once.
	my @critic_hits = ( $out =~ /Perl::Critic/g );
	is scalar @critic_hits, 1, 'Perl::Critic appears exactly once';

	# The pinned version must be preserved.
	like $out, qr/Perl::Critic.*1\.140|1\.140.*Perl::Critic/,
		'version-pinned Perl::Critic preserved';

	diag "Output:\n$out" if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# 13. Output format invariants across all Makefile.PL variants
#
# Strategy: no matter what the input Makefile.PL contains, the generate()
# output must always satisfy a set of structural invariants derived from
# the POD and cpanfile conventions:
#   - Starts with the generator comment header
#   - Terminates with exactly one newline
#   - No double blank lines (no adjacent empty lines)
#   - Runtime deps at the top level; non-runtime in 'on phase => sub' blocks
#   - Module entries within each block are alphabetically sorted
# -----------------------------------------------------------------------

subtest 'output format: invariants across all Makefile.PL variants' => sub {
	my $g = empty_home();

	my @fixtures = (
		[ 'simple',      $MF_SIMPLE      ],
		[ 'all-phases',  $MF_ALL_PHASES  ],
		[ 'min-perl',    $MF_MIN_PERL    ],
		[ 'comments',    $MF_COMMENTS    ],
		[ 'structured',  $MF_STRUCTURED  ],
		[ 'meta-merge',  $MF_META_MERGE  ],
		[ 'duplicate',   $MF_DUPLICATE   ],
	);

	for my $fixture (@fixtures) {
		my ($name, $content) = @{$fixture};
		my $mf  = make_mf($content);
		my $out = App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			with_develop => 0,
		);

		diag "[$name] output:\n$out" if $ENV{TEST_VERBOSE};

		like $out, qr/^# Generated from Makefile\.PL/,
			"[$name] output starts with generator header";

		like $out, qr/\n$/,
			"[$name] output ends with a newline";

		ok $out !~ /\n\n$/,
			"[$name] output does not end with double newline";

		ok $out !~ /\n\n\n/,
			"[$name] output has no triple (or more) consecutive newlines";

		# Runtime deps must NOT be inside an 'on' block.
		# (Simple test: if requires 'Moo' appears, it must not be inside on 'runtime')
		ok $out !~ /on 'runtime' => sub/,
			"[$name] no 'on runtime' block (runtime emitted at top level)";
	}
};

# -----------------------------------------------------------------------
# 14. Alphabetical sort invariant within phase blocks
#
# Strategy: verify that within each relationship group, modules are emitted
# in alphabetical order regardless of the order they appear in Makefile.PL.
# -----------------------------------------------------------------------

subtest 'output format: modules sorted alphabetically within each phase' => sub {
	my $g = empty_home();

	# Declare modules in reverse alphabetical order in the Makefile.PL.
	my $mf = make_mf(<<'END');
WriteMakefile(
	PREREQ_PM => {
		'Zeta::Module' => 0,
		'Alpha::First' => 0,
		'Mu::Middle'   => 0,
	},
);
END

	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 0,
	);

	diag "Output:\n$out" if $ENV{TEST_VERBOSE};

	# Extract the order of the three modules in the output.
	my @order;
	while ($out =~ /requires '(Alpha::First|Mu::Middle|Zeta::Module)'/g) {
		push @order, $1;
	}

	is_deeply \@order, [qw(Alpha::First Mu::Middle Zeta::Module)],
		'modules emitted in alphabetical order regardless of Makefile.PL order';
};

# -----------------------------------------------------------------------
# 15. Statelessness: independent generate() calls do not interfere
#
# Strategy: call generate() with two different Makefile.PLs (A and B),
# then call generate() for A again.  The first and third outputs must be
# identical, and A must differ from B.  This confirms no shared mutable
# state exists between calls.
# -----------------------------------------------------------------------

subtest 'statelessness: independent generate() calls do not interfere' => sub {
	my $g = empty_home();

	my $mf_a = make_mf($MF_SIMPLE);       # Moo + Try::Tiny
	my $mf_b = make_mf($MF_ALL_PHASES);   # completely different modules

	my $out_a1 = App::makefilepl2cpanfile::generate(
		makefile => "$mf_a", with_develop => 0
	);
	my $out_b = App::makefilepl2cpanfile::generate(
		makefile => "$mf_b", with_develop => 0
	);
	my $out_a2 = App::makefilepl2cpanfile::generate(
		makefile => "$mf_a", with_develop => 0
	);

	is   $out_a2, $out_a1, 'same Makefile.PL produces identical output on second call';
	isnt $out_b,  $out_a1, 'different Makefile.PLs produce different outputs';

	diag "A1:\n$out_a1\nB:\n$out_b" if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# 16. Statelessness: interleaved parse_prereqs() calls
#
# Strategy: call parse_prereqs() with content A, then with empty content,
# then with content A again.  The first and third results must be deeply
# equal, and the second (empty) must return an empty hashref.
# This checks that the function holds no mutable state between calls.
# -----------------------------------------------------------------------

subtest 'statelessness: interleaved parse_prereqs() calls' => sub {
	my $content_a = $MF_ALL_PHASES;

	my $result_a1    = App::makefilepl2cpanfile::parse_prereqs($content_a);
	my $result_empty = App::makefilepl2cpanfile::parse_prereqs('');
	my $result_a2    = App::makefilepl2cpanfile::parse_prereqs($content_a);

	is_deeply $result_a2, $result_a1,
		'parse_prereqs() returns same result for same content on repeated calls';

	is_deeply $result_empty, {},
		'parse_prereqs() returns empty hashref for empty content';
};

# -----------------------------------------------------------------------
# 17. Version constraint emission: versioned and unversioned deps
#
# Strategy: a version of 0 must produce no version constraint in the
# cpanfile output; a non-zero version must produce a quoted version
# argument.  Both parse_prereqs and generate are checked end-to-end.
# -----------------------------------------------------------------------

subtest 'pipeline: versioned and unversioned deps emitted correctly' => sub {
	my $g = empty_home();

	my $mf = make_mf(<<'END');
WriteMakefile(
	PREREQ_PM => {
		'Unversioned' => 0,
		'Versioned'   => '1.23',
	},
);
END

	my $content = path("$mf")->slurp_utf8;
	my $parsed  = App::makefilepl2cpanfile::parse_prereqs($content);
	is $parsed->{runtime}{requires}{'Unversioned'}{version}, 0,     'version 0 stored';
	is $parsed->{runtime}{requires}{'Versioned'}{version},   '1.23','version 1.23 stored';

	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 0,
	);

	like   $out, qr/requires 'Versioned', '1\.23'/,  'versioned dep has constraint';
	unlike $out, qr/requires 'Unversioned', '/,      'unversioned dep has no constraint';
	like   $out, qr/requires 'Unversioned';/,         'unversioned dep ends with semicolon directly';

	diag "Output:\n$out" if $ENV{TEST_VERBOSE};
};

done_testing;
