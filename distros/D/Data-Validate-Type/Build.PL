use 5.006;
use strict;
use warnings;

use Module::Build;


my $class = Module::Build->subclass(
	code =>
	q|
		# Override 'test' to support running extended tests in the xt/
		# directory.
		sub ACTION_test
		{
			my ( $self ) = @_;

			$self->recursive_test_files(1);

			$self->test_files( 't', 'xt' )
				if $ENV{'RELEASE_TESTING'};

			return $self->SUPER::ACTION_test();
		}

		# Force running extended tests when testing the distribution.
		sub ACTION_disttest
		{
			my ( $self ) = @_;

			local $ENV{ RELEASE_TESTING } = 1;

			return $self->SUPER::ACTION_disttest();
		}
	|,
);

my $builder = $class->new(
	module_name          => 'Data::Validate::Type',
	license              => 'Perl_5',
	dist_author          => q{Guillaume Aubert <aubertg@cpan.org>},
	dist_version_from    => 'lib/Data/Validate/Type.pm',
	build_requires       =>
	{
		'Test::Exception'       => 0,
		'Test::FailWarnings'    => 0,
		'Test::More'            => 0.94, # Required for subtest().
	},
	requires             =>
	{
		'perl'                  => 5.006,
		'Carp'                  => 0,
		'Data::Dump'            => 0,
		'Exporter'              => 0,
		'Scalar::Util'          => 1.18, # Recent 'looks_like_number'.
	},
	add_to_cleanup       =>
	[
		'Data-Validate-Type-*',
	],
	create_makefile_pl   => 'traditional',
	recursive_test_files => 1,
	configure_requires   =>
	{
		'Module::Build'         => 0,
	},
	meta_merge           =>
	{
		resources               =>
		{
			repository  => 'https://github.com/guillaumeaubert/Data-Validate-Type',
			homepage    => 'https://metacpan.org/release/Data-Validate-Type',
			bugtracker  => 'https://github.com/guillaumeaubert/Data-Validate-Type/issues',
		},
		no_index                =>
		{
			file        =>
			[
				't/LocalTest.pm',
			],
			package =>
			[
				'LocalTest',
				'LocalTestParent',
			],
		},
	},
);

$builder->create_build_script();
