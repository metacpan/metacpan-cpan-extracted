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
	module_name          => 'Audit::DBI::TT2',
	dist_abstract        => 'A Template Toolkit plugin to display audit events recorded by Audit::DBI',
	license              => 'Perl_5',
	dist_author          => q{Guillaume Aubert <aubertg@cpan.org>},
	dist_version_from    => 'lib/Audit/DBI/TT2.pm',
	build_requires       =>
	{
		'DBD::SQLite'          => 0,
		'DBI'                  => 0,
		'Scalar::Util'         => 0,
		'Test::Exception'      => 0,
		'Test::FailWarnings'   => 0,
		'Test::More'           => 0.94,
	},
	requires             =>
	{
		'Audit::DBI'           => 1.008001,
		'Data::Dump'           => 0,
		'HTML::Entities'       => 0,
		'POSIX'                => 0,
		'Template::Plugin'     => 0,
		'Template::Stash'      => 0,
		'perl'                 => 5.006,
	},
	add_to_cleanup       =>
	[
		'Audit-DBI-TT2-*',
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
			repository  => 'https://github.com/guillaumeaubert/Audit-DBI-TT2',
			homepage    => 'https://metacpan.org/release/Audit-DBI-TT2',
			bugtracker  => 'https://github.com/guillaumeaubert/Audit-DBI-TT2/issues',
		},
	},
	recursive_test_files => 1,
);

$builder->create_build_script();
