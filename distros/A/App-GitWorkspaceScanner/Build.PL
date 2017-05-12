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
	module_name          => 'App::GitWorkspaceScanner',
	license              => 'Perl_5',
	dist_author          => q{Guillaume Aubert <aubertg@cpan.org>},
	dist_version_from    => 'lib/App/GitWorkspaceScanner.pm',
	build_requires       =>
	{
		'Test::FailWarnings'    => 0,
		'Test::More'            => 0,
	},
	requires             =>
	{
		'Carp'                  => 0,
		'Data::Dumper'          => 0,
		'File::Spec'            => 0,
		'Getopt::Long'          => 0,
		'Git::Repository'       => 0,
		'Log::Any'              => 0,
		'Log::Any::Adapter'     => 0,
		'Pod::Find'             => 0,
		'Pod::Usage'            => 0,
		'Pod::Usage'            => 0,
		'Readonly'              => 0,
		'Try::Tiny'             => 0,
		'perl'                  => 5.010,
	},
	add_to_cleanup       =>
	[
		'App-GitWorkspaceScanner-*',
	],
	create_makefile_pl   => 'traditional',
	configure_requires   =>
	{
		'Module::Build'         => 0,
	},
	script_files         =>
	[
		'bin/scan_git_repositories',
	],
	meta_merge           =>
	{
		resources               =>
		{
			repository  => 'https://github.com/guillaumeaubert/App-GitWorkspaceScanner',
			homepage    => 'https://metacpan.org/release/App-GitWorkspaceScanner',
			bugtracker  => 'https://github.com/guillaumeaubert/App-GitWorkspaceScanner/issues',
		},
	},
	recursive_test_files => 1,
);

$builder->create_build_script();
