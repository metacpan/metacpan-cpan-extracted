use strict;
use warnings;
use Module::Build;
require 5.008001;

my $build = Module::Build->new(
    create_readme      => 0,
    create_makefile_pl => 'traditional',
    license            => 'artistic_2',
    module_name        => 'App::Mowyw',
    dist_author        => 'Moritz Lenz',
    dist_abstract      => 'Macro processor for creating static HTML pages',
    dist_version_from  => 'lib/App/Mowyw.pm',
    requires => {
        'perl'              => '5.8.1',
        'Carp'              => 0,
        'Data::Dumper'      => 0,
        'Scalar::Util'      => 0,
        'File::Temp'        => 0,
        'File::Compare'     => 0,
        'Storable'          => 0,
        'Exporter'          => 0,
        'Config::File'      => 0,
    },
    recommends         => {
        'DBI'               => 0,
        'Text::VimColor'    => 0,
        'XML::Simple'       => 0,
    },
    script_files        => [ qw(
        script/mowyw
    )],
    sign               => 0,
);
$build->create_build_script;

# vim: sw=4 ts=4 expandtab
