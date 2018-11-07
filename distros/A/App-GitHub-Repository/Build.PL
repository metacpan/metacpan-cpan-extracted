use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::GitHub::Repository',
    license             => 'artistic2',
    dist_author         => 'JJ Merelo <jjmerelo@gmail.com>',
    dist_version_from   => 'lib/App/GitHub/Repository.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'App-GitHub-Repository-*' ],
);

$builder->create_build_script();
