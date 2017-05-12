use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'Data-DigestPath',
    module_name         => 'Data::DigestPath',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Data/DigestPath.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Digest::SHA1' => 0,
    },
    requires => {
        'perl' => '5.008001',
        'Digest::MD5' => 0,
        'Class::Accessor::Lite' => 0,
    },
    add_to_cleanup      => [ 'Data-DigestPath-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Data-DigestPath',
        bugtracker  => 'http://github.com/bayashi/Data-DigestPath/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
