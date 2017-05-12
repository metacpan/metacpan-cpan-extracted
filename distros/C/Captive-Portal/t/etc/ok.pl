use strict;
use warnings;
use subs qw(TRUE FALSE ON OFF YES NO);

# cfg hash
return {

    SESSIONS_DIR  => 't/sessions',
    MOCK_MAC      => 1,
    MOCK_AUTHEN   => 1,
    MOCK_FIREWALL => 1,
    RUN_USER      => scalar getpwuid($>),
    RUN_GROUP     => scalar getgrgid($)),
    ADMIN_SECRET  => 'my-secret',

    'IPTABLES' => {
        capture_if    => 'eth0',
        capture_ports => [ 80, ],
        redirect_port => 80,
        capture_net   => '10.10.0.0/16',
        throttle      => OFF,

        open_services => {},
        open_clients  => [],
        open_servers  => [],
        open_networks => [],
    },

    I18N_LANGUAGES     => [ 'en', ],
    I18N_FALLBACK_LANG => 'en',

    I18N_MSG_CATALOG   => {
        msg_001 => { en => 'last session state was:', },

        msg_002 => { en => 'username or password is missing', },

        msg_003 => { en => 'username or password is wrong', },

        msg_004 => { en => 'successfull logout', },

        msg_005 => { en => 'admin_secret is wrong', },

        msg_006 =>
          { en => 'Idle-session reestablished due to valid cookie.', },
    },
};

# vim: sw=2

