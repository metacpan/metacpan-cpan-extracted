use 5.012;

use strict;
use warnings;
use Module::Build;
use Config;

# require 64-bit integer support
if (! $Config{use64bitint}) {
    warn "64-bit integer support required for installation\n";
    exit(0);
}

my $builder = Module::Build->new(
    module_name        => 'Compress::BGZF',
    license            => 'GPL_3',
    dist_author        => q{Jeremy Volkening <jdv@base2bio.com>},
    configure_requires => {
        'Config'        => 0,
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Compress::Zlib'             => 0,
        'IO::Uncompress::RawInflate' => 0,
        'IO::Compress::RawDeflate'   => 0,
        'List::Util'                 => 0,
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/jvolkening/p5-Compress-BGZF'
        }
    },
    add_to_cleanup => [ 'Compress-BGZF-*' ],
    create_license => 1,
);
$builder->create_build_script;
