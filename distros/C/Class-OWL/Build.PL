use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Class::OWL',
    license             => 'perl',
    dist_author         => 'Chris Prather <cpan@prather.org>',
    dist_version_from   => 'lib/Class/OWL.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Class::MOP' => 0,
        'XML::CommonNS' => 0,
        'RDF::Helper' => 0,
        'Data::Dumper' => 0,
        'LWP::Simple' => 0

    },
    add_to_cleanup      => [ 'Class-OWL-*' ],
);

$builder->create_build_script();
