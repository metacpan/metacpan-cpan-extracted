use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    dist_abstract       => 'GitHub client, with some scraping functions',
    module_name         => 'App::GitHub::Repository',
    license             => 'artistic_2',
    dist_version        => 'v0.0.6',
    dist_author         => 'JJ Merelo <jjmerelo@gmail.com>',
    requires => {
                 'Test::More' => 0,
                 'version'    => 0,
                 'File::Slurper' => 0,
                 'JSON' => 0,
                 'Git' => 0,
                 'Module::Build' => 0,
                },
    test_requires => { 'Test::Perl::Critic' => 0, },
    add_to_cleanup      => [ 'App-GitHub-Repository-*' ],
);

$builder->create_build_script();
