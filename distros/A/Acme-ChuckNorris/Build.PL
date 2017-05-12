use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Acme::ChuckNorris',
    license           => 'perl',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/Acme/ChuckNorris.pm',
    requires          => {
        'Test::More'     => 0,
        'Acme::EyeDrops' => 0,
    },
    add_to_cleanup => ['Acme-ChuckNorris-*'],
);

$builder->create_build_script();
