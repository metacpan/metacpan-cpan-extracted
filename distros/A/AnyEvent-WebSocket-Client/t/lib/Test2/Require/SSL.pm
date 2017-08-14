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

sub diag_about_issue22
{
  my $ctx = context();
  $ctx->diag("");
  $ctx->diag("");
  $ctx->diag(" == NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE ==");
  $ctx->diag("");
  $ctx->diag("  Recent versions of AnyEvent, in combination of Net::SSLeay");
  $ctx->diag("  broke the SSL test for AnyEvent::WebSocket::Client.");
  $ctx->diag("  Please see the GitHub issue tracker for up to date information:");
  $ctx->diag("");
  $ctx->diag("  https://github.com/plicease/AnyEvent-WebSocket-Client/issues/22");
  $ctx->diag("");
  $ctx->diag("  If SSL is not important for your use case, you may consider");
  $ctx->diag("  installing AnyEvent::WebSocket::Client anyway.  It should work");
  $ctx->diag("  fine over non-encrypted channels.  You can set the environment");
  $ctx->diag("  variable ANYEVENT_WEBSOCKET_TEST_SKIP_SSL to skip the SSL tests.");
  $ctx->diag("");
  $ctx->diag("  Patches to fix this will be gladly accepted.");
  $ctx->diag("");
  $ctx->diag(" == NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE ==");
  $ctx->diag("");
  $ctx->diag("");
  $ctx->release;
}

1;
