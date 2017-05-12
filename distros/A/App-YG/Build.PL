use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::YG',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/App/YG.pm',
    build_requires      => {
        'Test::More' => 0.88,
        'Test::Warn' => 0,
        'parent' => 0,
        'Exporter' => 0,
    },
    requires => {
        'perl' => '5.8.1',
        'Carp' => 0,
        'Getopt::Long' => 2.38,
        'Pod::Usage'   => 0,
        'IO::Interactive' => 0,
        'Class::Accessor::Lite' => 0,
        'Term::ANSIColor' => 0,
    },
    recommends => {
        'Digest::SHA1' => 0,
    },
    add_to_cleanup      => [ 'App-YG-*' ],
    script_files        => [ 'bin/yg' ],
    recursive_test_files => 1,
);

$builder->create_build_script();
