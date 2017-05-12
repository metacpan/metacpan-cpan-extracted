use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App-Git-Workflow-Command-SinceRelease',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_abstract     => 'Finds out how many commits a branch is since latest release',
    dist_version_from => 'lib/App/Git/Workflow/Command/SinceRelease.pm',
    requires          => {
        'perl'                         => '5.006',
        'App::Git::Workflow'           => '0.8',
        'App::Git::Workflow::Command'  => '0.8',
    },
    build_requires => {
        'Test::Git::Workflow::Command' => '0.8',
        'Test::More'                   => '0.88',
        'Test::Warnings'               => 0,
    },
    add_to_cleanup     => [ 'App-Git-Workflow-Command-SinceRelease-*' ],
    create_license     => 1,
    meta_merge         => {
        resources => {
            repository => 'git://github.com/ivanwills/App-Git-Workflow-Command-SinceRelease.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Git-Workflow-Command-SinceRelease',
        },
        abstract => 'Finds out how many commits a branch is since latest release',
    },
);

$builder->create_build_script();
