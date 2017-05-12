use Module::Build;
use strict;
use warnings;

my %requires = (
                 'perl'                     => '5.004',
                 'Sort::DataTypes'          => '0',
               );
my %build_mods = (
                 'Storable'                 => '0',
                 'Test::More'               => '0',
                 'Test::Pod'                => '0',
                 'Test::Pod::Coverage'      => '0',
               );


my $build = Module::Build->new(
        license            => 'perl',
        dist_version       => '1.02',
        dist_author        => 'Sullivan Beck <sbeck@cpan.org>',
        module_name        => 'Array::AsObject',
        dist_abstract      => 'full set of array and set operations',
        requires           => \%requires,
        build_requires     => {},
        build_recommends   => \%build_mods,
        sign               => 1,
);

$build->create_build_script;
