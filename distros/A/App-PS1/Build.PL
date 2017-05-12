use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::PS1',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/App/PS1.pm',
    requires          => {
        'perl'                  => 5.006,
        'Class::Accessor::Fast' => 0,
        'JSON::XS'              => 0,
        'Path::Tiny'            => 0,
        'version'               => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => 0,
    },
    recommends => {
        'Term::Size::Any'    => 0,
        'Term::Colour256'    => 0,
        'Test::Perl::Critic' => 0,
        'Test::Kwalitee'     => 0,
        'Test::Spelling'     => 0,
    },
    add_to_cleanup     => [ 'App-PS1-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'http://github.com/ivanwills/App-PS1',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-PS1',
        },
    },
);

$builder->create_build_script();
