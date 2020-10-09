use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::sersh',
    license           => 'perl',
    dist_author       => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from => 'sersh',

    build_requires => {'Test::Most' => 0,},
    requires       => {
        'Getopt::Long'            => 0,
        'Pod::Usage'              => 0,
        'AnyEvent'                => 0,
        'AnyEvent::SerialPort'    => 0,
        'AnyEvent::ReadLine::Gnu' => 0,
        'Path::Class'             => 0,
        'File::HomeDir'           => 0,
    },
    configure_requires => {'Module::Build' => '0.38'},
    script_files       => ['sersh',],
    add_to_cleanup     => ['App-sersh-*'],
    create_readme      => 1,
    meta_merge         => {
        resources => {
            repository => 'http://github.com/jozef/App-sersh/',
            bugtracker => 'http://github.com/jozef/App-sersh/issues',
        },
        keywords => [qw/ app serial port shell console /],
    },
);

$builder->create_build_script();
