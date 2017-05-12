use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    license              => 'perl',
    dynamic_config       => 0,

    build_requires       => {
        'Test::More' => '0.98',
        'Test::Requires' => 0,
        'Test::Exception' => 0,
    },
    configure_requires   => { 'Module::Build' => '0.38' },
    requires => {
        perl => '5.010001',
        'Moo' => '0',
        'Time::Piece' => '0',
        'UNIVERSAL::require' => '0',
        'List::MoreUtils' => '0',
        'Math::Random::MT' => '0',
        'Imager' => '0',
        'Furl' => '0',
        'Cache::LRU' => '0',
        'Net::DNS::Lite' => '0',
      },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => 'Acme-PrettyCure',
    module_name => 'Acme::PrettyCure',

    # script_files => [''],

    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,
   
    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();
