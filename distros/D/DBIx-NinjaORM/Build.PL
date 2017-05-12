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
	module_name          => 'DBIx::NinjaORM',
	license              => 'Perl_5',
	dist_author          => q{Guillaume Aubert <aubertg@cpan.org>},
	dist_version_from    => 'lib/DBIx/NinjaORM.pm',
	build_requires       =>
	{
		'DBD::SQLite'          => 0,
		'DBI'                  => 0,
		'Test::Deep'           => 0,
		'Test::Exception'      => 0,
		'Test::FailWarnings'   => 0,
		'Test::More'           => 0.94, # subtest()
		'Test::Type'           => 0,
		'Test::Warn'           => 0,
	},
	requires             =>
	{
		'Carp'                 => 0,
		'Class::Load'          => 0,
		'DBIx::Inspector'      => 0,
		'Data::Dumper'         => 0,
		'Data::Validate::Type' => 0,
		'Digest::SHA1'         => 0,
		'Log::Any'             => 0,
		'MIME::Base64'         => 0,
		'Storable'             => 0,
		'Try::Tiny'            => 0,
		'perl'                 => 5.010,
	},
	add_to_cleanup       =>
	[
		'DBIx-NinjaORM-*',
	],
	create_makefile_pl   => 'traditional',
	configure_requires   =>
	{
		'Module::Build'        => 0,
	},
	meta_merge           =>
	{
		resources              =>
		{
			repository  => 'https://github.com/guillaumeaubert/DBIx-NinjaORM',
			homepage    => 'https://metacpan.org/release/DBIx-NinjaORM',
			bugtracker  => 'https://github.com/guillaumeaubert/DBIx-NinjaORM/issues',
		},
		no_index               =>
		{
			file        =>
			[
				't/lib/LocalTest.pm',
			],
			namespace   =>
			[
				'TestSubclass',
			]
		},
	},
	recursive_test_files => 1,
);

$builder->create_build_script();
