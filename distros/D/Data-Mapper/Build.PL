use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    license              => 'perl',
    dynamic_config       => 0,

    build_requires       => {
        'Test::More'     => '0.98',
        'Test::Fatal'    => '0',
        'Test::Requires' => '0',
    },
    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        perl              => "5.008001",
        parent            => '0',
        'SQL::Maker'      => '1.00',
        'DBIx::Inspector' => '0.06',
        'Class::Load'     => '0',
    },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => 'Data-Mapper',
    module_name => 'Data::Mapper',

    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,

    create_readme  => 1,
    create_license => 1,
);

$build->create_build_script();
