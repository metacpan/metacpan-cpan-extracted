use strict;
use warnings;
use Module::Build;
use 5.010;

my $builder = Module::Build->new(
    module_name       => 'Business::DPD',
    license           => 'perl',
    dist_author       => 'RevDev',
    dist_version_from => 'lib/Business/DPD.pm',
    build_requires    => {
        'Test::More'       => '0',
        'Test::Most'       => '0',
        'Test::NoWarnings' => '0.084',
        'Test::Exception'  => '0.27',
    },
    requires => {
        'perl'                  => '5.010',
        'PDF::Reuse'            => '0.35',
        'PDF::Reuse::Barcode'   => '0.05',
        'DateTime'              => '0.4304',
        'DBD::SQLite'           => '1.14',
        'DBIx::Class'           => '0.08010',
        'Text::Autoformat'      => '1.13',
        'List::MoreUtils'       => '0',
        'Path::Class'           => 0,
        'URI'                   => 0,
        'LWP::UserAgent'        => 0,
        'Web::Scraper'          => 0,
        'HTML::Entities'        => 0,
        'DateTime::Format::Strptime' => 0,
    },
    
    add_to_cleanup     => ['Business-DPD-*'],
    create_makefile_pl => 'passthrough',
    recursive_test_files => 1,
);
$builder->add_build_element('sqlite');
$builder->add_build_element('pdf');
$builder->add_build_element('TTF');
$builder->create_build_script();
