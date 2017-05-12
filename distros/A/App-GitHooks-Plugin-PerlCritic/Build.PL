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
	module_name          => 'App::GitHooks::Plugin::PerlCritic',
	license              => 'Perl_5',
	dist_author          => q{Guillaume Aubert <aubertg@cpan.org>},
	dist_version_from    => 'lib/App/GitHooks/Plugin/PerlCritic.pm',
	build_requires       =>
	{
		'Capture::Tiny'        => 0,
		'Git::Repository'      => 0,
		'Test::Exception'      => 0,
		'Test::FailWarnings'   => 0,
		'Test::Requires::Git'  => 1.005,
		'Test::More'           => 0.94,
		'Test::Type'           => 0,
	},
	requires             =>
	{
		'App::GitHooks'        => 0,
		'Perl::Critic'         => 0,
		'Perl::Critic::Git'    => 0,
		'Try::Tiny'            => 0,
		'perl'                 => 5.010,
	},
	add_to_cleanup       =>
	[
		'App-GitHooks-Plugin-PerlCritic-*',
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
			repository  => 'https://github.com/guillaumeaubert/App-GitHooks-Plugin-PerlCritic',
			homepage    => 'https://metacpan.org/release/App-GitHooks-Plugin-PerlCritic',
			bugtracker  => 'https://github.com/guillaumeaubert/App-GitHooks-Plugin-PerlCritic/issues',
		},
	},
	recursive_test_files => 1,
);

$builder->create_build_script();
