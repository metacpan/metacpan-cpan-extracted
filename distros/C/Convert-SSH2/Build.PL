use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Convert::SSH2',
    license             => 'perl',
    dist_author         => q{Mark Allen <mrallen1@yahoo.com>},
    dist_version_from   => 'lib/Convert/SSH2.pm',
    configure_requires => {
        'Module::Build' => '0.38',
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => '5.010',
        'Try::Tiny' => 0,
        'MIME::Base64' => 0,
        'Convert::ASN1' => 0,
        'Class::Load' => '0.13',
        'File::Slurp' => 0,
        'Moo' => '0.009013',
        'Math::BigInt' => 0,
    },
    add_to_cleanup      => [ 'Convert-SSH2-*' ],
    create_makefile_pl => 'traditional',
    meta_merge => {
        resources => {
            repository => 'https://github.com/mrallen1/Convert-SSH2.git',
        },
    },
    
);

$builder->create_build_script();
