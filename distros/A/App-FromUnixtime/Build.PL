use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'App-FromUnixtime',
    module_name         => 'App::FromUnixtime',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/App/FromUnixtime.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Capture::Tiny' => 0,
    },
    requires => {
        'perl' => '5.008001',
        'strict' => 0,
        'warnings' => 0,
        'Getopt::Long' => 2.36,
        'IO::Interactive::Tiny' => 0,
        'Pod::Usage' => 0,
        'POSIX' => 0,
        'Config::CmdRC' => 0,
        'Exporter' => 0,
    },
    script_files        => [ 'script/from_unixtime' ],
    add_to_cleanup      => [ 'App-FromUnixtime-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/App-FromUnixtime',
        bugtracker  => 'http://github.com/bayashi/App-FromUnixtime/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
