
use utf8;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Compression::Util',
    license           => 'artistic_2',
    dist_author       => q<Daniel Șuteu <trizen@cpan.org>>,
    dist_version_from => 'lib/Compression/Util.pm',
    release_status    => 'stable',

    sign              => 1,
    dynamic_config    => 0,
    extra_manify_args => {utf8 => 1},

    configure_requires => {
                           'Module::Build' => 0,
                          },
    build_requires => {
                       'Test::More' => 0,
                      },

    meta_merge => {
                   resources => {
                                 bugtracker => "https://github.com/trizen/Compression-Util/issues",
                                 homepage   => "https://github.com/trizen/Compression-Util",
                                 repository => "https://github.com/trizen/Compression-Util",
                                },
                  },

    requires => {
                 'perl'       => '5.36.0',
                 'Test::More' => 0,
                 'List::Util' => '1.45',
                 'Exporter'   => 0,
                 'Carp'       => 0,
                },
    add_to_cleanup     => ['Compression-Util-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
