package testlib::SSL;

use strict;
use warnings;
use Test::More;

sub try_ssl_modules_or_skip
{
  eval "use Net::SSLeay 1.33 (); 1" or plan skip_all => "test requires Net::SSLeay 1.33";
  eval "use AnyEvent::TLS (); 1"    or plan skip_all => "test requires AnyEvent::TLS";
  
  plan skip_all => 'user requested skip of SSL tests via environment'
      if $ENV{ANYEVENT_WEBSOCKET_TEST_SKIP_SSL};

}

sub diag_about_issue22
{
  diag "";
  diag "";
  diag " == NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE ==";
  diag "";
  diag "  Recent versions of AnyEvent, in combination of Net::SSLeay";
  diag "  broke the SSL test for AnyEvent::WebSocket::Client.";
  diag "  Please see the GitHub issue tracker for up to date information:";
  diag "";
  diag "  https://github.com/plicease/AnyEvent-WebSocket-Client/issues/22";
  diag "";
  diag "  If SSL is not important for your use case, you may consider";
  diag "  installing AnyEvent::WebSocket::Client anyway.  It should work";
  diag "  fine over non-encrypted channels.  You can set the environment";
  diag "  variable ANYEVENT_WEBSOCKET_TEST_SKIP_SSL to skip the SSL tests.";
  diag "";
  diag "  Patches to fix this will be gladly accepted.";
  diag "";
  diag " == NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE ==";
  diag "";
  diag "";
}

1;
