use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'App::Siesh',
    license     => 'perl',
    requires    => {
        'autodie'             => 0,
        'Config::Find'        => 0,
        'Config::Tiny'        => 0,
        'File::Temp'          => 0,
	'Getopt::Long'        => 0,
        'IO::File'            => 0,
        'IO::Handle'          => 0,
        'IO::Interactive'     => 0,
        'IO::Prompt'          => 0,
        'IO::Socket::SSL'     => 0,
        'IPC::System::Simple' => 0,
        'Net::ManageSieve'    => '0.08',
        'parent'              => 0,
        'Pod::Usage'          => 0,
        'Term::ShellUI'       => 0,
    },
    build_requires => {
        'Test::More'   => 0,
        'IO::String'   => 0,
        'Test::Output' => 0,
    },
    recommends => {
	## To make the wold a better place
	'Authen::SASL' => 0,
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    meta_merge =>
      { resources => { repository => 'http://github.com/mdom/app-siesh', }, },

);

$builder->create_build_script();
