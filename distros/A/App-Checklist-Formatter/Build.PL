use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup      => [ 'App-Checklist-Formatter-*' ],
    build_requires	=> {
    	'File::Spec'	=> 0,
	'Probe::Perl'	=> 0,
	'Test::More'	=> 0,
    },
    create_makefile_pl	=> 'passthrough',
    dist_abstract	=> 'Format checklists',
    dist_author         => 'Mathias Weidner <mamawe@cpan.org>',
    dist_version_from   => 'bin/checklist-formatter',
    license             => 'perl',
    meta_merge => {
        resources => {
            repository => 'https://github.com/matwei-perl/App-Checklist-Formatter',
        }
    },
    module_name         => 'App::Checklist::Formatter',
    requires => {
	# Perls prior to 5.6 don't support the three-argument form of open.
	'perl'		=> '5.6.0',
        'version'	=> 0,
	'Carp'		=> 0,
	'Class::Std'	=> 0,
    },
    script_files	=> [ 'bin/checklist-formatter' ],
);

$builder->create_build_script();
