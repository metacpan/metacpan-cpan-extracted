use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Class::Action',
    license             => 'perl',
    dist_author         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from   => 'lib/Class/Action.pm',
    requires => {
        'Test::More' => 0,
        'Test::Carp' => 0,
    },
    add_to_cleanup      => [ 'Class-Action-*' ],
);

$builder->create_build_script();
