use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup      => [ 'App-Iptables2Dot-*' ],
    build_requires	=> {
    	'File::Spec'	=> 0,
	'Probe::Perl'	=> 0,
	'Test::More'	=> 0,
    },
    configure_requires  => { 'Module::Build' => 0.38 },
    create_makefile_pl	=> 'small',
    dist_abstract	=> 'Analyze iptables with GraphViz',
    dist_author         => 'Mathias Weidner <mamawe@cpan.org>',
    dist_version_from   => 'lib/App/Iptables2Dot.pm',
    license             => 'perl',
    meta_merge => {
        resources => {
            repository => 'https://github.com/matwei-perl/App-Iptables2Dot',
            bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-Iptables2Dot',
        }
    },
    module_name         => 'App::Iptables2Dot',
    requires => {
	# Perls prior to 5.6 don't support the three-argument form of open.
	# Perl 5.10.1 includes "configure_requires" support
	#             (see: Module::Build::Compat)
	'perl'		=> '5.10.1',
        'version'	=> 0,
	'Carp'		=> 0,
    },
    script_files	=> [ 'bin/iptables2dot' ],
);

$builder->create_build_script();
