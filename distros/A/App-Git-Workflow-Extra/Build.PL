use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App-Git-Workflow-Extra',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/App/Git/Workflow/Extra.pm',
    requires          => {
        'perl'                                         => '5.006',
        'App::Git::Workflow'                           => '0.8',
        'App::Git::Workflow::Command::BranchConflicts' => 0,
        'App::Git::Workflow::Command::Cat'             => 0,
        'App::Git::Workflow::Command::SinceRelease'    => 0,
        'App::Git::Workflow::Command::Take'            => 0,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => 0,
    },
    add_to_cleanup     => [ 'App-Git-Workflow-Extra-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/App-Git-Workflow-Extra.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Git-Workflow-Extra',
        },
    },
);

$builder->create_build_script();
