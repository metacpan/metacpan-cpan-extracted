use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::Stash',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/App/Stash.pm',
    requires => {
        'File::HomeDir' => 0,
        'File::Path'    => 0,
        'Path::Class'   => 0,
        'JSON::Util'    => 0,
        'Class::Accessor::Chained::Fast' => 0,
    },
    build_requires => {
        'Test::More'        => 0,
        'Test::Differences' => 0,
        'Test::Exception'   => 0,
        'File::Temp'        => 0,
    },
    add_to_cleanup      => [ 'App-Stash-*' ],
    create_readme       => 1,
    sign                => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/jozef/App-Stash.git',
            bugtracker => 'http://github.com/jozef/App-Stash/issues',
        },
        keywords => [ qw/ application data storage persistant / ],
    },
);

$builder->create_build_script();
