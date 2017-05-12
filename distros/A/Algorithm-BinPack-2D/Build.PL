# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Algorithm::BinPack::2D',
    dist_author =>
      'Tasuku SUENAGA a.k.a. gunyarakun <tasuku-s-cpanATATtitech.ac>',
    license => 'perl',

    requires => {
        perl => '5.008005',
    },
    configure_requires => {
        'Module::Build' => '0.38',
    },
    build_requires => {
        'Test::More'      => '0.98',
        'Test::Requires'  => '0',
        'Test::Exception' => '0',
    },

    no_index => { 'directory' => [ 'inc', 'author' ] },

    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,

    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();
