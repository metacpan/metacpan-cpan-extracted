use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DateTime::Duration::Fuzzy',
    license             => 'perl',
    dist_author         => q{Jan Oldrich Kruza <sixtease@cpan.org>},
    dist_version_from   => 'lib/DateTime/Duration/Fuzzy.pm',
    requires => {
        'DateTime' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'DateTime-Duration-Fuzzy-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
