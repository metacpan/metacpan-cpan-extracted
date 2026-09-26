use strict;
use warnings;
use Test::Most;
use File::Temp ();
use App::makefilepl2cpanfile;

# -----------------------------------------------------------------------
# Basic extraction — simple PREREQ_PM / TEST_REQUIRES / etc. form
# -----------------------------------------------------------------------

my $content = <<'END_MF';
WriteMakefile(
	PREREQ_PM => {
		'Moo'       => '2.000',
		'Try::Tiny' => 0,
	},
	TEST_REQUIRES => {
		'Test::More' => 0,
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '6.64',
	},
	BUILD_REQUIRES => {
		'Module::Build' => '0.42',
	},
);
END_MF

my $deps = App::makefilepl2cpanfile::parse_prereqs($content);

isa_ok $deps, 'HASH', 'parse_prereqs returns a hashref';

# The simple keys all map to the 'requires' relationship.
ok exists $deps->{runtime}{requires}{'Moo'},       'Moo is in runtime/requires';
is $deps->{runtime}{requires}{'Moo'}{version}, '2.000', 'Moo carries its version';

ok exists $deps->{runtime}{requires}{'Try::Tiny'}, 'Try::Tiny is in runtime/requires';
is $deps->{runtime}{requires}{'Try::Tiny'}{version}, 0, 'Try::Tiny version is 0';

ok exists $deps->{test}{requires}{'Test::More'},   'Test::More in test/requires';

ok exists $deps->{configure}{requires}{'ExtUtils::MakeMaker'}, 'EMM in configure/requires';
is $deps->{configure}{requires}{'ExtUtils::MakeMaker'}{version}, '6.64',
	'ExtUtils::MakeMaker version correct';

ok exists $deps->{build}{requires}{'Module::Build'}, 'Module::Build in build/requires';
is $deps->{build}{requires}{'Module::Build'}{version}, '0.42',
	'Module::Build version correct';

# 'develop' must not be injected by parse_prereqs — that is generate()'s job.
ok !exists $deps->{develop}, 'develop phase absent from parse_prereqs output';

# -----------------------------------------------------------------------
# Inline comment preservation
# -----------------------------------------------------------------------

my $commented = <<'END_MF';
WriteMakefile(
	PREREQ_PM => {
		'Foo::Bar' => 0,    # provides Foo::Bar::Baz used in bin/ scripts
		# 'Old::Module' => 0,   # disabled — replaced by Foo::Bar
	},
);
END_MF

my $dep2 = App::makefilepl2cpanfile::parse_prereqs($commented);
ok  exists $dep2->{runtime}{requires}{'Foo::Bar'},    'uncommented module extracted';
ok !exists $dep2->{runtime}{requires}{'Old::Module'}, 'fully-commented module not extracted';

like $dep2->{runtime}{requires}{'Foo::Bar'}{comment},
	qr/provides Foo::Bar::Baz/,
	'inline comment is captured verbatim';

# -----------------------------------------------------------------------
# Structured prereqs => { phase => { rel => { ... } } } form
# -----------------------------------------------------------------------

my $structured = <<'END_MF';
WriteMakefile(
	prereqs => {
		runtime => {
			requires => {
				'Scalar::Util' => 0,
			},
			recommends => {
				'Future' => '0.33',   # async support
			},
			suggests => {
				'Log::Any' => 0,
			},
		},
		test => {
			requires => {
				'Test::Exception' => 0,
			},
		},
	},
);
END_MF

my $dep3 = App::makefilepl2cpanfile::parse_prereqs($structured);

ok exists $dep3->{runtime}{requires}{'Scalar::Util'},  'requires from prereqs block';
ok exists $dep3->{runtime}{recommends}{'Future'},      'recommends extracted';
is $dep3->{runtime}{recommends}{'Future'}{version}, '0.33', 'recommends version correct';
like $dep3->{runtime}{recommends}{'Future'}{comment}, qr/async/, 'recommends comment captured';
ok exists $dep3->{runtime}{suggests}{'Log::Any'},      'suggests extracted';
ok exists $dep3->{test}{requires}{'Test::Exception'},  'test requires from prereqs block';

# -----------------------------------------------------------------------
# META_MERGE => { prereqs => { ... } } form
# -----------------------------------------------------------------------

my $meta_merge = <<'END_MF';
WriteMakefile(
	PREREQ_PM => { 'Moo' => 0 },
	META_MERGE => {
		prereqs => {
			runtime => {
				recommends => {
					'Moo::Role' => '2.000',
				},
			},
		},
	},
);
END_MF

my $dep4 = App::makefilepl2cpanfile::parse_prereqs($meta_merge);
ok exists $dep4->{runtime}{requires}{'Moo'},         'PREREQ_PM still parsed alongside META_MERGE';
ok exists $dep4->{runtime}{recommends}{'Moo::Role'}, 'META_MERGE prereqs recommends extracted';
is $dep4->{runtime}{recommends}{'Moo::Role'}{version}, '2.000',
	'META_MERGE recommends version correct';

# -----------------------------------------------------------------------
# Legacy META_MERGE => { recommends/suggests => { ... } } form (META spec 1.x)
# -----------------------------------------------------------------------

my $legacy = <<'END_MF';
WriteMakefile(
	PREREQ_PM => { 'Moo' => 0 },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		recommends => {
			# Optional backends
			'JSON::MaybeXS' => 0,		# JSON backend
			'XML::Simple' => '2.25',
		},
		'suggests' => {
			'YAML::XS' => '0.88',	# YAML backend
		},
		prereqs => {
			test => {
				recommends => {
					'Test::Deep' => 0,
				},
				suggests => {
					'Test::Differences' => 0,
				},
			},
		},
	},
);
END_MF

my $dep5 = App::makefilepl2cpanfile::parse_prereqs($legacy);
ok exists $dep5->{runtime}{recommends}{'JSON::MaybeXS'},
	'legacy top-level recommends extracted as runtime/recommends';
is $dep5->{runtime}{recommends}{'JSON::MaybeXS'}{comment}, 'JSON backend',
	'legacy recommends comment captured';
is $dep5->{runtime}{recommends}{'XML::Simple'}{version}, '2.25',
	'legacy recommends version captured';
ok exists $dep5->{test}{recommends}{'Test::Deep'},
	'phase-scoped recommends inside prereqs still goes to its phase';
ok !exists $dep5->{runtime}{recommends}{'Test::Deep'},
	'phase-scoped recommends is not duplicated into runtime';
is $dep5->{runtime}{suggests}{'YAML::XS'}{version}, '0.88',
	'legacy top-level suggests extracted as runtime/suggests';
is $dep5->{runtime}{suggests}{'YAML::XS'}{comment}, 'YAML backend',
	'legacy suggests comment captured';
ok exists $dep5->{test}{suggests}{'Test::Differences'},
	'phase-scoped suggests inside prereqs still goes to its phase';
ok !exists $dep5->{runtime}{suggests}{'Test::Differences'},
	'phase-scoped suggests is not duplicated into runtime';
ok exists $dep5->{runtime}{requires}{'Moo'}, 'PREREQ_PM unaffected';

my $gen_dir = File::Temp::tempdir(CLEANUP => 1);
my $gen_mf  = "$gen_dir/Makefile.PL";
open my $fh, '>', $gen_mf or die "$gen_mf: $!";
print {$fh} $legacy;
close $fh;
my $out = App::makefilepl2cpanfile::generate(makefile => $gen_mf, with_develop => 0);
like $out, qr/^recommends 'JSON::MaybeXS';\s+# JSON backend$/m,
	'generate emits legacy recommends at top level';
like $out, qr/^recommends 'XML::Simple', '2\.25';$/m,
	'generate emits legacy recommends version';
like $out, qr/^suggests 'YAML::XS', '0\.88';\s+# YAML backend$/m,
	'generate emits legacy suggests at top level';

# -----------------------------------------------------------------------
# Several entries on one line (regression: only the first was kept)
# -----------------------------------------------------------------------

my $dep6 = App::makefilepl2cpanfile::parse_prereqs(
	"PREREQ_PM => { 'DBI' => 1.60, 'Moo' => '2.0', 'Carp' => 0,   # core\n\t'Next::Line' => 0 },"
);
is_deeply $dep6->{runtime}{requires}, {
	'DBI'        => { version => '1.60', comment => undef },
	'Moo'        => { version => '2.0',  comment => undef },
	'Carp'       => { version => 0,      comment => 'core' },
	'Next::Line' => { version => 0,      comment => undef },
}, 'every entry on a line is kept; the comment belongs to the last one';

# -----------------------------------------------------------------------
# Module names must be ASCII (CPAN requires it; blocks look-alikes)
# -----------------------------------------------------------------------

my $dep7 = App::makefilepl2cpanfile::parse_prereqs(
	"PREREQ_PM => {\n\t'Caf\x{e9}' => 0,\n\t'T\x{435}st::More' => 0,\n\t'\x{c9}lan' => 0,\n\t'Plain' => 0,\n},"
);
is_deeply [ keys %{ $dep7->{runtime}{requires} } ], ['Plain'],
	'names with non-ASCII letters (including Cyrillic look-alikes) are rejected';

# -----------------------------------------------------------------------
# META spec 1.x top-level keys, conflicts, and version ranges
# -----------------------------------------------------------------------

my $dep8 = App::makefilepl2cpanfile::parse_prereqs(<<'END_MF');
WriteMakefile(
	META_MERGE => {
		requires           => { 'Legacy::Run'   => '1.0' },
		build_requires     => { 'Legacy::Build' => 0 },
		configure_requires => { 'Legacy::Conf'  => 0 },
		conflicts          => { 'Legacy::Bad'   => '< 2.0' },
		prereqs => { test => { conflicts => { 'Test::Bad' => '== 1.5' } } },
	},
	PREREQ_PM => { 'Ranged' => '>= 1.2, < 2.0' },
);
END_MF
is $dep8->{runtime}{requires}{'Legacy::Run'}{version}, '1.0', 'top-level requires -> runtime requires';
ok exists $dep8->{build}{requires}{'Legacy::Build'},          'top-level build_requires -> build requires';
ok exists $dep8->{configure}{requires}{'Legacy::Conf'},       'top-level configure_requires -> configure requires';
is $dep8->{runtime}{conflicts}{'Legacy::Bad'}{version}, '< 2.0', 'top-level conflicts -> runtime conflicts';
is $dep8->{test}{conflicts}{'Test::Bad'}{version}, '== 1.5',   'conflicts inside prereqs stays in its phase';
ok !exists $dep8->{runtime}{conflicts}{'Test::Bad'},          'and is not duplicated into runtime';
is $dep8->{runtime}{requires}{'Ranged'}{version}, '>= 1.2, < 2.0', 'version range kept exactly';

# -----------------------------------------------------------------------
# The comment on a line belongs to the last entry that is kept
# -----------------------------------------------------------------------

my $dep9 = App::makefilepl2cpanfile::parse_prereqs(
	"PREREQ_PM => {\n\t'Good' => 0, 'Bad Name' => 0,   # note\n},"
);
is_deeply $dep9->{runtime}{requires}, { 'Good' => { version => 0, comment => 'note' } },
	'an invalid last entry does not take the comment with it';

done_testing;
