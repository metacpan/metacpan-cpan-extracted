use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::fftrim',
    license             => 'artistic_2',
    dist_author         => q{Joel Roth <joelz@pobox.com >},
    dist_version_from   => 'lib/App/fftrim.pm',
	script_files		=> ['script/fftrim'],
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More' => '0',
    },
    requires => {
    },
    add_to_cleanup     => [ 'App-fftrim-*' ],
);

$builder->create_build_script();
