use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::Git::Workflow::Command::Take',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/App/Git/Workflow/Command/Take.pm',
    requires          => {
        'perl'                        => 5.008,
        'App::Git::Workflow'          => '0.96009',
        'App::Git::Workflow::Command' => '0.96009',
        'Path::Tiny'                  => 0,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    add_to_cleanup     => [ 'App-Git-Workflow-Command-Take-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/App-Git-Workflow-Command-Take.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::Git::Workflow::Command::Take',
        },
    },
);

$builder->create_build_script();
