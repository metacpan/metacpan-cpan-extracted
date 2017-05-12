# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.
# http://ecclestoad.co.uk

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    add_to_cleanup     => ['Class-DBI-DFV-*'],
    create_makefile_pl => 'passthrough',
    dist_author        => 'Edmund von der Burg <evdb@ecclestoad.co.uk>',
    dist_version_from  => 'lib/Class/DBI/DFV.pm',
    license            => 'perl',
    module_name        => 'Class::DBI::DFV',
    requires           => {
        'Class::DBI'          => '3.0.1',
        'Test::More'          => 0,
        'Data::FormValidator' => '4.02',
        'Data::Dumper'        => 0,
        'DBD::SQLite'         => 0,
    },
    test_files => [ glob('t/*.t') ],
);

$build->create_build_script;
