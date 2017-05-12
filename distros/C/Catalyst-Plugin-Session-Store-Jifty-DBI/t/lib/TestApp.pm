package TestApp;

use strict;
use warnings;
use Catalyst::Runtime;
use Catalyst;

__PACKAGE__->config({
  name => __PACKAGE__,
  'Plugin::Session' => {
    expires => 3600,
    moniker => $ENV{TESTAPP_SESSION_STORE_JDBI_MONIKER},
    use_custom_serialization
      => $ENV{TESTAPP_SESSION_STORE_JDBI_SERIALIZATION},
  },
});

__PACKAGE__->setup(qw(
  Session
  Session::State::Cookie
  Session::Store::Jifty::DBI
));

1;
