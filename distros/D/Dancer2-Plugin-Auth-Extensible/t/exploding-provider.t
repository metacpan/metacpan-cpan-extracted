use strict;
use warnings;

use Test::More;
use lib 't/lib';

BEGIN {
    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'exploding';
}

{
    package TestApp;
    use Test::More;
    use Test::Deep;
    use Test::Fatal;
    use Dancer2;
    use Dancer2::Plugin::Auth::Extensible;
    set logger => 'capture';

    my $plugin = app->with_plugin('Auth::Extensible');
    my $trap   = dancer_app->logger_engine->trapper;
    my $logs;

    is exception {
        $plugin->authenticate_user( 'fred', 'password', 'config1' );
    }, undef, "authenticate_user lives";

    cmp_deeply $logs = $trap->read,
      superbagof(
        {
            formatted => ignore(),
            level     => 'debug',
            message =>
              re(qr/Attempting to authenticate fred against realm config1/),
        },
        {
            formatted => ignore(),
            level     => 'error',
            message =>
              re(qr/config1 provider threw error: KABOOM authenticate_user/),
        }
      ),
      "... and auth attempt plus kaboom found in logs."
      or diag explain $logs;

    is exception {
        $plugin->create_user( username => 'fred', password => 'config1' );
    }, undef, "create_user with set_user_password lives";

    cmp_deeply $logs = $trap->read,
      superbagof(
        {
            formatted => ignore(),
            level     => 'error',
            message =>
              re(qr/config1 provider threw error: KABOOM set_user_password/),
        }
      ),
      "... and set_password kaboom found in logs."
      or diag explain $logs;

    is exception {
        $plugin->get_user_details( 'fred' );
    }, undef, "get_user_details lives";

    cmp_deeply $logs = $trap->read,
      superbagof(
        {
            formatted => ignore(),
            level     => 'error',
            message =>
              re(qr/config1 provider threw error: KABOOM get_user_details/),
        }
      ),
      "... and get_user_details kaboom found in logs."
      or diag explain $logs;

}

done_testing;
