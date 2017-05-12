use Module::Build;
use strict;
use warnings;

my %requires = (
                 'perl'                     => '5.001',
                 'Algorithm::Permute'       => '0',
                 'IO::File'                 => '0',
                 'Storable'                 => '0',
                 'YAML::Syck'               => '0',
               );
my %build_mods = (
                 'Test::More'               => '0',
                 'Test::Pod'                => '0',
                 'Test::Pod::Coverage'      => '0',
               );


my $build = Module::Build->new(
        license            => 'perl',
        dist_version       => '3.12',
        dist_author        => 'Sullivan Beck <sbeck@cpan.org>',
        module_name        => 'Data::Nested',
        dist_abstract      => 'routines to work with a perl nested data structure',
        requires           => \%requires,
        build_requires     => {},
        build_recommends   => \%build_mods,
        sign               => 1,
);

$build->create_build_script;
