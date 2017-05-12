use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::Report::Generator',
    license             => 'perl',
    dist_author         => q{Jens Rehsack <rehsack@cpan.org>},
    dist_version_from   => 'lib/App/Report/Generator.pm',
    build_requires => {
	'App::Cmd::Tester' => '0.300',
	'DBD::Sys' => '0.102',
	'File::ConfigDir' => 0.003,
	'File::Path' => 0,
	'File::Slurp' => 0,
	'JSON::Any' => 0,
	'Template' => '2.00',
	'Template::Plugin::DBI' => '2.65',
        'Test::More' => '0.90',
    },
    requires => {
	'App::Cmd' => '0.300',
	'Carp' => 0,
	'Config::Any' => 0,
	'File::Basename' => 0,
	'File::ConfigDir' => 0.001,
	'File::Find::Rule' => '0.30',
	'Report::Generator' => 0.002,
    },
    add_to_cleanup      => [ 'App-Report-Generator-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
