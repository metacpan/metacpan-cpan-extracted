use strict;
use warnings;
use 5.008001;
use Alien::Base::ModuleBuild;
use Alien::CMake;

my $builder = Alien::Base::ModuleBuild->new(
	'meta-spec' => {
		version => '2',
		url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
	},
	module_name        => 'Alien::SFML',
	dist_abstract      => 'Build and install SFML 2.0 (RC)',
	license            => 'perl',
	configure_requires => {
		'Alien::Base'   => 0,
		'Alien::CMake'  => 0,
		'Module::Build' => 0.38,
	},
	requires => {
		'perl'        => '5.8.1',
		'Alien::Base' => 0,
	},
	dist_author      => 'Jake Bott <jake.anq@gmail.com>',
	alien_name       => 'sfml-audio sfml-network sfml-graphics sfml-window sfml-system',
	alien_repository => {
		protocol => 'local',
		pattern  => qr/SFML-sources\.tgz/,
	},
	alien_build_commands => [
		'pwd',
		Alien::CMake->config('prefix')
		  . '/bin/cmake -DCMAKE_INSTALL_PREFIX:PATH=%s CMakeLists.txt',
		'make',
	],
	alien_install_commands => ['make install'],
	extra_compiler_flags   => Alien::CMake->config('cflags'),
	extra_linker_flags     => Alien::CMake->config('libs'),
	alien_provides_libs    => '-lsfml-audio -lsfml-network -lsfml-graphics -lsfml-window -lsfml-system',
	resources              => {
		bugtracker => {
			web    => 'http://github.com/jakeanq/perl-alien-sfml/issues',
			mailto => 'jake.anq@gmail.com',
		},
		repository => {
			url  => 'git://github.com/jakeanq/perl-alien-sfml.git',
			web  => 'http://github.com/jakeanq/perl-alien-sfml',
			type => 'git',
		},
	},);
$builder->create_build_script;

=head1 COPYRIGHT

 ############################
 # Copyright 2013 Jake Bott #
 #=>----------------------<=#
 #   All Rights Reserved.   #
 #   Part of Alien::SFML.   #
 #=>----------------------<=#
 #   See the LICENCE file   #
 ############################

=cut
