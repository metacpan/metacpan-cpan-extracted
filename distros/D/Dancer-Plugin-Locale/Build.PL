use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Dancer::Plugin::Locale',
    license => 'perl',
    dist_author => [
        'Nicolas Steenlant <nicolas.steenlant@ugent.be>'
    ],
    dist_version_from => 'lib/Dancer/Plugin/Locale.pm',
    build_requires => {
        'Software::License' => 0,
        'Test::Exception' => 0,
        'Test::More' => 0,
    },
    requires => {
        'Dancer' => '1.3050',
        'Locale::TextDomain' => '1.23',
        'Locale::Util' => 0,
    },
    add_to_cleanup => [qw(
        Dancer-Plugin-Locale-*
    )],
    create_makefile_pl => 'traditional',
    create_license => 1,
);

$builder->create_build_script;

