use strict;
use Module::Build;

my %arguments = (
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'Class::DBI::Sweet',
    requires           => {
        'Class::DBI'    => 'v3.0.12',
        'Data::Page'    => 0,
        'DBI'           => 0,
        'List::Util'    => 0,
        'SQL::Abstract' => 1.55,
        'DBD::SQLite'   => 1.08
    },
    dist_abstract      => 'lib/Class/DBI/Sweet.pm',
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    test_files         => [ glob('t/*.t'), glob('t/*/*.t') ]
);

if ( $^O eq 'MSWin32' ) {
    $arguments{recommends}->{'Win32API::GUID'} = 0;
}
else {
    $arguments{recommends}->{'Data::UUID'} = 0;
}

Module::Build->new(%arguments)->create_build_script;
