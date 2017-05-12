use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::LogStats',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/App/LogStats.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Test::Output' => 0,
        'Test::Exception' => 0,
        'Exporter' => 0,
        'parent' => 0,
    },
    requires => {
        'perl' => '5.8.1',
        'Getopt::Long' => 2.38,
        'Pod::Usage' => 0,
        'IO::Interactive::Tiny' => 0,
        'Class::Accessor::Lite' => 0,
        'Text::ASCIITable' => 0.20,
    },
    add_to_cleanup      => [ 'App-LogStats-*' ],
    script_files        => [ 'bin/stats' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/App-LogStats'
      }
    },
    recursive_test_files => 1,
);

$builder->create_build_script();
