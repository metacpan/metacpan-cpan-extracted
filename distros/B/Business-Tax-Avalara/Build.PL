use 5.010;
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

my $builder = Module::Build->new(
	module_name          => 'Business::Tax::Avalara',
	license              => 'GPL_3',
	dist_author          =>
	[
		'Kate Kirby <kate@cpan.org>',
	],
	dist_version_from    => 'lib/Business/Tax/Avalara.pm',
	build_requires       =>
	{
		'Test::Deep'      => 0,
		'Test::Exception' => 0,
		'Test::More'      => 0,
	},
	requires             =>
	{
		'perl'                 => 5.010,
		'Try::Tiny'            => 0,
		'LWP::UserAgent'       => 0,
		'Carp'                 => 0,
		'Encode'               => 0,
		'Data::Dump'           => 0,
		'LWP::Protocol::https' => 0,
		'JSON::PP'             => 0,
	},
	add_to_cleanup       =>
	[
		'Business-Tax-Avalara*',
	],
	create_makefile_pl   => 'traditional',
	recursive_test_files => 1,
	configure_requires   =>
	{
		'Module::Build'   => 0,
	},
	meta_merge           =>
	{
		resources         =>
		{
			repository => 'https://github.com/katekirby/Business-Tax-Avalara.git',
			homepage   => 'https://metacpan.org/release/Business-Tax-Avalara',
			bugtracker => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-Tax-Avalara',
		},
	},
);

$builder->create_build_script();
