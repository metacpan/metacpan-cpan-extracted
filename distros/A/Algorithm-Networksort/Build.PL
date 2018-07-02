use Module::Build;
use strict;
use warnings;

my $class = Module::Build->subclass(
	class => "Module::Build::Custom",
	code => <<'SUBCLASS' );

sub ACTION_test {
	my $self = shift;

	#
	# Some test files take a long time to run. To save
	# the testers some processing time, skip those tests
	# by default (this is determined within the individual
	# test files).  Use the --Testlong option to set the
	# AUTHOR_TESTING environment variable, which the
	# longer-running test files will check for.
	#
	my %args = $self->args;

	$ENV{AUTHOR_TESTING} = 1 if (exists $args{Testlong});
	$self->SUPER::ACTION_test;
}
SUBCLASS

#my $build = Module::Build->new(
my $build = $class->new(
	module_name => 'Algorithm::Networksort',

	dist_abstract => 'Create Sorting Networks',
	dist_author => ['John M. Gamble <jgamble@cpan.org>'],
	dist_version => '2.02',

	provides => {
		'Algorithm::Networksort' => {
			file => 'lib/Algorithm/Networksort.pm',
		},
		'Algorithm::Networksort::Best' => {
			file => 'lib/Algorithm/Networksort/Best.pm',
		},
	},

	requires => {
		perl=> '5.10.1',
		Moose => '2.16',
		'Moose::Exporter' => '2.16',
		'namespace::autoclean' => '0.16',
	},

	configure_requires => {
		'Module::Build' => '0.4',
	},

	build_requires => {
		'Test::More' => 0,
	},

	license => 'perl',
	create_license => 1,
	create_readme => 0,
	create_makefile_pl => 'traditional',
	dynamic_config => 0,

	meta_merge => {
		keywords => [qw(sort sorting-network
			batcher bitonic hibbard bose-nelson bubble
			odd-even balanced)],

		resources => {
			repository => 'git://github.com/jgamble/Algorithm-Networksort.git',
		},
	},

);

$build->create_build_script;
