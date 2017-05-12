use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Date::Holidays::SK',
    license             => 'Artistic_2_0',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Date/Holidays/SK.pm',
    configure_requires  => { 'Module::Build' => 0.36 },
    requires => {
        'Date::Simple' => 0,
        'Date::Easter' => 0,
    },
    build_requires => {
        'Test::Most'      => 0,
    },
    add_to_cleanup      => [ 'Date-Holidays-SK-*' ],
    create_readme       => 1,
    meta_merge => {
        resources => {
            repository => 'http://github.com/jozef/Date-Holidays-SK',
            bugtracker => 'http://github.com/jozef/Date-Holidays-SK/issues',
        },
        keywords => [ qw/ date holiday SK / ],
    },
);

$builder->create_build_script();
