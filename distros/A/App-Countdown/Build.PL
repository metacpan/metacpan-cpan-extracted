use 5.008;
use strict;
use warnings FATAL => 'all';

use lib './inc';

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'App::Countdown',
    license             => 'MIT',
    dist_author         => q{Shlomi Fish <shlomif@cpan.org>},
    dist_version_from   => 'lib/App/Countdown.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp' => 0,
        'Getopt::Long' => '2.36',
        'IO::Handle' => 0,
        'perl' => '5.010',
        'POSIX' => 0,
        'strict' => 0,
        'Time::HiRes' => 0,
        'warnings' => 0,
    },
    add_to_cleanup     => [ 'App-Countdown-*' ],
    create_makefile_pl => 'traditional',
    script_files => ['bin/countdown',],
    meta_merge =>
    {
        resources =>
        {
            repository => "https://bitbucket.org/shlomif/perl-app-countdown",
            homepage => "http://www.shlomifish.org/open-source/projects/countdown/",
        },
        keywords =>
        [
            'app',
            'application',
            'console',
            'countdown',
            'modulino',
            'sleep',
            'terminal',
            'timer',
        ],
    },
);

$builder->create_build_script();
