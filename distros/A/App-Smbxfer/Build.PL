use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::Smbxfer',
    license             => 'perl',
    dist_author         => 'Karl Erisman <karl.erisman@gmail.com>',
    dist_version_from   => 'lib/App/Smbxfer.pm',
    requires => {
        'Exporter' => 0,
        'Getopt::Long' => 0,
        'IO::Prompt' => 0,
        'Filesys::SmbClient' => 0,
        'Test::More' => 0,
        'Test::Differences' => 0,
        'File::Find' => 0,
        'File::Temp' => 0,
    },
    add_to_cleanup      => [ 'App-Smbxfer-*' ],
);

$builder->create_build_script();
