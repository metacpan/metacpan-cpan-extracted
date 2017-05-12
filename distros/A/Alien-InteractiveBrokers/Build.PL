use 5.006;
use strict;
use warnings;
use lib qw( inc lib );
use MY::Build;

MY::Build->new(
    'module_name'       => 'Alien::InteractiveBrokers',
    'license'           => 'perl',
    'dist_author'       => 'Jason McManus <infidel AT cpan.org>',
    'create_makefile_pl'=> 'passthrough',
    'requires'          => {
        'perl'                  => '5.6.0',
    },
    'build_requires'    => {
        'Archive::Extract'      => 0,
        'Test::More'            => 0,
        'HTTP::Tiny'            => 0,
    },
)->create_build_script();
