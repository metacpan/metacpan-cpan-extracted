use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::War',
    license           => 'perl',
    dist_author       => 'John Trammell <johntrammell@gmail.com>',
    dist_version_from => 'lib/App/War.pm',
    requires => {
        'perl'         => 0,
        'strict'       => 0,
        'warnings'     => 0,
        'Getopt::Long' => 0,
        'Graph'        => 0.84,
        'List::Util'   => 0,
        'Pod::Usage'   => 0,
    },
    build_requires => {
        'Test::More'            => 0,
        'Test::Script'          => 1.06,
        'Test::Warn'            => 0.11,
        'Module::Build::Compat' => 0,
    },
    recursive_test_files => 1,
    script_files         => 'script',
    add_to_cleanup       => [qw/ Debian* App-War-* *.bak /],
);

$builder->create_build_script;

