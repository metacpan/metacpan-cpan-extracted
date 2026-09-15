use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::whichpm',
    license           => 'perl',
    dist_author       => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from => 'lib/App/whichpm.pm',
    
    build_requires => {
        'Test::More'             => 0,
    },
    requires => {
        'Getopt::Long'           => 0,
        'Module::Metadata'       => 0,
        'Module::Path'           => 0,
        'Pod::Usage'             => 0,
    },
    configure_requires  => { 'Module::Build' => '0.38' },
    script_files => [
        'script/whichpm',
    ],
    add_to_cleanup => [ 'App-whichpm-*' ],
    create_readme  => 1,
    meta_merge => {
        resources => {
            repository => 'http://github.com/jozef/App-whichpm/',
            bugtracker => 'http://github.com/jozef/App-whichpm/issues',
        },
        keywords => [ qw/ app which perl module / ],
    },
);

$builder->create_build_script();
