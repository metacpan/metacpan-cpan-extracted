# Build.PL
# Use to build the package App::tonematch
our $VERSION = '0.002';
    
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name=> 'App::tonematch',
    dist_name  => 'App-tonematch',
    dist_author=> [
	'W. Luis Mochan <mochan@fis.unam.mx>',
	],
    dist_version_from => 'lib/App/tonematch.pm',
    license    => 'perl',
    release_status => 'stable', #stable, testing or unstable
    requires   => { 
	"Tk" => 0,
	"Tk::MTDial" => 0,
    },
    test_requires => {
	"Test::More" => 0,
	"Pod::Coverage::TrustPod" => 0,
    },
    configure_requires => {
	'Module::Build'                      => '0.4004',
    },
    script_files => 'script/tonematch',
    add_to_cleanup  => [ 'App-tonematch-*', '*~'],
    create_makefile_pl => 'small',
    );
$builder->create_build_script();
