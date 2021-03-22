package Test2::Require::SSL;

use strict;
use warnings;
use Test2::API qw( context );
use base qw( Test2::Require );

sub skip
{
  eval "use Net::SSLeay 1.33 (); 1" or return "test requires Net::SSLeay 1.33";
  eval "use AnyEvent::TLS (); 1"    or return "test requires AnyEvent::TLS";

  return 'user requested skip of SSL tests via environment'
      if $ENV{ANYEVENT_WEBSOCKET_TEST_SKIP_SSL};

  return;
}

1;
