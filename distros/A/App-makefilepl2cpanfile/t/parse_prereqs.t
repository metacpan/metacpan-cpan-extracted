use strict;
use warnings;
use Test::Most;
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

done_testing;
