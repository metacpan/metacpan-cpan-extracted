package # Hide from PAUSE
  CookieTestApp;
use strict;
use warnings;

use base qw/Catalyst/;
use Catalyst qw/
  Session
  Session::Store::Dummy
  Session::State::Cookie
  /;

__PACKAGE__->config('Plugin::Session' => { cookie_secure => 2 });

__PACKAGE__->setup;

1;
