use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DBIx::Class::TimeStamp::HiRes',
    license             => 'perl',
    dist_author         => 'John Judd <funkyshu@dark-linux.com>',
    dist_version_from   => 'lib/DBIx/Class/TimeStamp/HiRes.pm',
    build_requires => {
        'Test::More'         => '0.98',
        'Test::Perl::Critic' => '1.02',
        'version'            => '0.88',
    },
    requires => {
        'DateTime::HiRes'        => 0,
        'DBIx::Class::TimeStamp' => 0,
        'version'                => '0.77',
    },
    add_to_cleanup      => [ 'DBIx-Class-TimeStamp-HiRes-*' ],
);

$builder->create_build_script();
