use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name => 'Apache2::AuthCookieDBI',
    license     => 'lgpl',
    requires    => {
        'mod_perl2'           => 1.999022,
        'Apache2::AuthCookie' => 3.08,
        'DBI'                 => 1.40,
        'Apache2::Const'      => 0,
        'Apache2::RequestRec' => 0,
        'Apache2::ServerUtil' => 0,
        'Carp'                => 0,
        'Crypt::CBC'          => 2.13,
        'Date::Calc'          => 0,
        'Digest::MD5'         => 0,
        'FindBin'             => 0,
    },
    recommends => {
        'Digest::SHA' => 5.47,  # If you use DBI_CryptType sha256
    },
    build_requires     => { 
        'Test::More' => 0.4, 
        'Digest::SHA' => 5.47,
    },
    create_makefile_pl => 'traditional',
    add_to_cleanup     => [
        qw( *.tar.gz
            MANIFEST.bak
            ),
    ],
    meta_merge     => {
        resources =>
            { repository => 'https://github.com/matisse/Apache-AuthCookieDBI', },
    },

);

$build->create_build_script();

exit;
__END__

# 'ORIGINAL_AUTHOR'       => 'Jacob Davies (jacob@well.com)',
  
