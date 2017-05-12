use Module::Build;
use strict;
use warnings;

my %requires = (
                 'perl'                     => '5.00000',
                 'Exporter'                 => '0',
                 'Scalar::Util'             => '0',
                 'YAML::Syck'               => '0',
               );
my %build_mods = (
                 'Archive::Zip'             => '0',
                 'Date::Manip::Date'        => '0',
                 'Test::Inter'              => '0',
                 'Test::Pod'                => '1.0',
                 'Test::Pod::Coverage'      => '1.0',
               );


my $build = Module::Build->new(
        license            => 'perl',
        dist_version       => '1.00',
        dist_author        => 'Sullivan Beck <sbeck@cpan.org>',
        module_name        => 'Data::PrettyPrintObjects',
        dist_abstract      => 'a pretty printing module with better support for objects',
        requires           => \%requires,
        build_requires     => \%build_mods,
        sign               => 1,
);

$build->create_build_script;
