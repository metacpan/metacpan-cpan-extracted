use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::ProcTrends',
    license             => 'perl',
    dist_author         => q{Satoshi Yagi <satoshi.yagi@yahoo.com>},
    dist_version_from   => 'lib/App/ProcTrends/Cron.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'              => 5.006,
        'CGI'               => 0,
        'Mojolicious::Lite' => 0,
        'RRDs'              => 0,
        'File::Slurp'       => 0,
        'RRDTool::OO'       => 0,
        'RRD::Simple'       => 0,
        'Log::Log4perl'     => 0,
    },
    add_to_cleanup      => [ 'App-ProcTrends-Cron-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
