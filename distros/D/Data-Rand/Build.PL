use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Rand',
    license             => 'perl',
    dist_author         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from   => 'lib/Data/Rand.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Data-Rand-*' ],
);

$builder->create_build_script();
