use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup     => [ 'App-VOJournal-*' ],
    build_requires => {
        'Test::More' => 0,
    },
    configure_requires => {
        'Module::Build' => 0,
    },
    create_makefile_pl => 'small',
    dist_abstract	=> 'Open a file in vimoutliner to write a journal',
    dist_author         => q{Mathias Weidner <mamawe@cpan.org>},
    dist_version_from   => 'lib/App/VOJournal.pm',
    license             => 'Artistic_2_0',
    meta_merge => {
        resources => {
            repository => 'https://github.com/matwei-perl/App-VOJournal',
            bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-VOJournal',
        }
    },
    module_name         => 'App::VOJournal',
    release_status      => 'stable',
    requires => {
        # Perl 5.10.1 includes "configure_requires" support
        #             (see: Module::Build::Compat)
        'perl'          => '5.10.1',
        'Getopt::Long'	=> 2.38,
		'version'		=> 0,
    },
    script_files	=> [
    	'bin/vojournal'
    ],
);

$builder->create_build_script();
