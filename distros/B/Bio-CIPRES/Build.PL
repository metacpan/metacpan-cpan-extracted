use 5.012;

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Bio::CIPRES',
    license            => 'GPL_3',
    dist_author        => q{Jeremy Volkening <jdv@base2bio.com>},
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Net::Ping'  => 0,
    },
    requires => {
        'Config::Tiny' => 0,
        'List::Util'   => 0,
        'Scalar::Util' => 0,
        'LWP'          => 0,
        'LWP::Protocol::https' => 0,
        'URI'          => 0,
        'URI::Escape'  => 0,
        'XML::LibXML'  => 0,
        'Time::Piece'  => 0,
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/jvolkening/p5-Bio-CIPRES'
        }
    },
    add_to_cleanup => [
        'Bio-CIPRES-*',
        'cover_db',
    ],
    create_license => 1,
);
$builder->create_build_script;
