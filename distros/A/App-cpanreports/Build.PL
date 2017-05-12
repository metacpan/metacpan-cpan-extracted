use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::cpanreports',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_abstract     => 'Download test reports for a CPAN distribution from CPAN Testers',
    dist_version_from => 'lib/App/cpanreports.pm',
    requires          => {
        'perl'             => '5.006',
        'HTML::Entities'   => 0,
        'Path::Tiny'       => 0,
        'WWW::Mechanize'   => 0,
        'YAML::XS'         => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => 0,
    },
    add_to_cleanup     => [ 'App-cpanreports-*' ],
    create_license     => 1,
    meta_merge         => {
        resources => {
            repository => 'git://github.com/ivanwills/App-cpan-reports.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::cpanreports',
        },
    },
);

$builder->create_build_script();
