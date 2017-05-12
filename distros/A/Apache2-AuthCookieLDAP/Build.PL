use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name => 'Apache2::AuthCookieLDAP',
    license     => 'perl',
    requires    => {
        'mod_perl2'           => 1.999022,
        'Apache2::AuthCookie' => 3.19,
        'Apache2::Connection' => 0,
        'Apache2::Const'      => 0,
        'Apache2::RequestRec' => 0,
        'Apache2::ServerUtil' => 0,
        'Crypt::CBC'          => 2.13,
        'Digest::MD5'         => 0,
        'Net::LDAP'           => 0.54,
    },
    create_makefile_pl => 'traditional'
)->create_build_script();

exit 0;

