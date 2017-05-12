use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Cache::Memcached::Fast::CGI',
    license             => 'perl',
    dist_author         => q{=Hitsu Bunnu <hitsubunnu@gmail.com>},
    dist_version_from   => 'lib/Cache/Memcached/Fast/CGI.pm',
    build_requires => {
        'Test::More' => 0,
        'Cache::Memcached::Fast' => 0,
        'IO::Capture::Stdout' => 0,
    },
    add_to_cleanup      => [ 'Cache-Memcached-Fast-CGI-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
