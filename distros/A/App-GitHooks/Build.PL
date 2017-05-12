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
	module_name          => 'App::GitHooks',
	license              => 'Perl_5',
	dist_author          => q{Guillaume Aubert <aubertg@cpan.org>},
	dist_version_from    => 'lib/App/GitHooks.pm',
	build_requires       =>
	{
		'Capture::Tiny'         => 0,
		'File::Spec'            => 0,
		'Git::Repository'       => 0,
		'Scalar::Util'          => 0,
		'Test::Compile'         => 1.001000,
		'Test::Deep'            => 0,
		'Test::Exception'       => 0,
		'Test::FailWarnings'    => 0,
		'Test::Git'             => 0,
		'Test::Requires::Git'   => 1.005,
		'Test::More'            => 0,
		'Test::Type'            => 1.002000,
	},
	requires             =>
	{
		'autodie'               => 0,
		'perl'                  => 5.010,
		'Capture::Tiny'         => 0,
		'Carp'                  => 0,
		'Class::Load'           => 0,
		'Config::Tiny'          => 0,
		'Cwd'                   => 0,
		'Data::Dumper'          => 0,
		'Data::Section'         => 0,
		'Data::Validate::Type'  => 0,
		'File::Basename'        => 0,
		'File::Temp'            => 0,
		'Path::Tiny'            => 0,
		'File::Spec'            => 0,
		'Getopt::Long'          => 0,
		'Git::Repository'       => 0,
		'Module::Pluggable'     => 0,
		'Parallel::ForkManager' => 0,
		'Pod::Usage'            => 0,
		'Readonly'              => 0,
		'Storable'              => 0,
		'Term::ANSIColor'       => 0,
		'Term::Encoding'        => 0,
		'Term::ReadKey'         => 0,
		'Test::Exception'       => 0,
		'Test::Git'             => 0,
		'Test::Requires::Git'   => 1.005,
		'Test::More'            => 0,
		'Text::Wrap'            => 0,
		'Try::Tiny'             => 0,
	},
	add_to_cleanup       =>
	[
		'App-GitHooks-*',
	],
	create_makefile_pl   => 'traditional',
	configure_requires   =>
	{
		'Module::Build'         => 0,
	},
	script_files         =>
	[
		'bin/githooks',
	],
	meta_merge           =>
	{
		resources               =>
		{
			repository  => 'https://github.com/guillaumeaubert/App-GitHooks',
			homepage    => 'https://metacpan.org/release/App-GitHooks',
			bugtracker  => 'https://github.com/guillaumeaubert/App-GitHooks/issues',
		},
	},
	recursive_test_files => 1,
);

$builder->create_build_script();
