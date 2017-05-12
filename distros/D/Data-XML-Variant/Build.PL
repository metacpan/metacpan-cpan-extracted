use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Data::XML::Variant',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Data/XML/Variant.pm',
    requires          => {
        aliased          => 0.10,
        'HTML::Entities' => 1.29,
        'Test::More'     => 0,
        'Test::XML'      => 0.07,
    },
    add_to_cleanup     => ['Data-XML-Variant-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
