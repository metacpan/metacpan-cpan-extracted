# $Id: Build.PL 2 2007-10-27 22:08:58Z kim $

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Page::Balanced',
    license             => 'perl',
    dist_author         => 'Kim Ahlström <kim.ahlstrom@gmail.com>',
    dist_version_from   => 'lib/Data/Page/Balanced.pm',
    requires => {
        'Test::More'                        => 0,
        'version'                           => 0,
        'Class::Accessor::Chained::Fast'    => 0,
        'Data::Page'                        => 2.00,
    },
    add_to_cleanup      => [ 'Data-Page-Balanced-*' ],
);

$builder->create_build_script();
