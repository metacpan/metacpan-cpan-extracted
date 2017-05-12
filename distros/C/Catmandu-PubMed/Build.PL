use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Catmandu::PubMed',
    license => 'perl',
    dist_author => [
        'Wouter Willaert <wouterw@inuits.eu>'
    ],
    dist_version_from => 'lib/Catmandu/PubMed.pm',
    build_requires => {
        'Software::License' => 0,
        'Test::Exception' => 0,
        'Test::More' => 0,
    },
    requires => {
        'perl' => '5.10.1',
        'Catmandu' => '0.0302',
        'Furl' => '0.41',
        'XML::LibXML::Simple' => '0.91',
        'Moo' => '1.000003',
    },
    add_to_cleanup => [qw(
        Catmandu-PubMed*
    )],
    create_makefile_pl => 'traditional',
    create_license => 1,
);

$builder->create_build_script;
