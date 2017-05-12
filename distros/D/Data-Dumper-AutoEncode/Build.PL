use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Dumper::AutoEncode',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Data/Dumper/AutoEncode.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Encode' => 0,
    },
    requires => {
        'perl' => '5.8.1',
        'parent' => 0,
        'Data::Dumper' => 0,
        'Data::Recursive::Encode' => 0.05,
        'Exporter' => 0,
    },
    recommends => {
        'IO::Interactive::Tiny' => 0,
    },
    script_files        => [ 'script/edumper' ],
    add_to_cleanup      => [ 'Data-Dumper-AutoEncode-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Data-Dumper-AutoEncode'
      }
    },
);

$builder->create_build_script();
