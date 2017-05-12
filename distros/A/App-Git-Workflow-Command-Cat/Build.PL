use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::Git::Workflow::Command::Cat',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/App/Git/Workflow/Command/Cat.pm',
    requires          => {
        'perl'                        => 5.008,
        'App::Git::Workflow'          => '0.96011',
        'App::Git::Workflow::Command' => '0.96011',
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.016',
    },
    add_to_cleanup     => [ 'App-Git-Workflow-Command-Cat-*' ],
    create_license     => 1,
    meta_merge         => {
        resources => {
            repository => 'git://github.com/ivanwills/App-Git-Workflow-Command-Cat.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::Git::Workflow::Command::Cat',
        },
    },
);

$builder->create_build_script();
