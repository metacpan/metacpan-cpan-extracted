#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use lib 'inc';
use Module::Build::My;

use Config;

my $module = 'App::PureProxy';

(my $dist = $module) =~ s/::/-/g;

my $build = Module::Build::My->new(
    module_name             => $module,
    dist_version_from       => 'script/pureproxy.pl',
    license                 => 'perl',
    requires                => {
        'perl'                  => 5.008,   # open $my
        'Plack::App::Proxy::Backend::HTTP::Tiny'        => 0,
        'Plack::Middleware::Proxy::Connect::IO'         => 0,
        'Plack::Middleware::Proxy::Requests'            => 0,
        $^O =~ /^(MSWin32|cygwin)$/ ? 'Thrall' : 'Starlight' => 0,
    },
    recommends              => {
        'Plack::Middleware::TrafficLog'                 => 0,
    },
    suggests                => {
        $Config{useithreads} ? ('Thrall' => 0) : (),
    },
    build_requires          => {
        'Test::More'            => 0,
    },
    script_files => 'script',
    auto_configure_requires => 0,
    create_makefile_pl      => 'traditional',
    create_readme           => 1,
    create_license          => 1,
    recursive_test_files    => 0,
    add_to_cleanup          => [
        '*.bak', '*.gz', '*.tgz', '*.ppd', '*.ppmx', '*.deb',
        'pm_to_blib', 'cover_db', 'Debian_CPANTS.txt',
        'compilet*', 'test-*',
        "$dist-*",
    ],
    meta_merge              => {
        resources               => {
            bugtracker => "http://github.com/dex4er/PureProxy/issues",
            repository => "http://github.com/dex4er/PureProxy",
        },
    },
);

$build->create_build_script;
