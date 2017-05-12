use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'Benchmarks',
    module_name         => 'Benchmarks',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Benchmarks.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
    },
    requires => {
        'perl' => '5.008001',
        'Benchmark' => 1.07,
    },
    script_files        => [ 'script/penchmarks' ],
    add_to_cleanup      => [ 'Benchmarks-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Benchmarks',
        bugtracker  => 'http://github.com/bayashi/Benchmarks/issues',
        x_IRC       => {
            url => 'irc://chat.freenode.org/#bayadev',
            web => 'http://webchat.freenode.net/?channels=%23bayadev',
        },
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
