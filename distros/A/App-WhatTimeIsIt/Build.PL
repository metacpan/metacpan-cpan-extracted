use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::WhatTimeIsIt',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/App/WhatTimeIsIt.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
    },
    requires => {
        'perl' => '5.008005',
        'Docopt' => 0.03,
        'Time::Local' => 0,
        'POSIX' => 0,
        'Config::CmdRC' => 0.06,
    },
    add_to_cleanup      => [ 'App-WhatTimeIsIt-*' ],
    script_files        => [ 'script/what_time_is_it' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/App-WhatTimeIsIt',
        bugtracker  => 'http://github.com/bayashi/App-WhatTimeIsIt/issues',
      }
    },
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    recursive_test_files => 1,
);

$builder->create_build_script();
