#!/usr/bin/perl

use v5.36;

use Test2::V0;
use Test::Future::IO;
use Test::Metrics::Any;

use Conduit;

my $controller = Test::Future::IO->controller;

# Now execute a request/response cycle; metrics should be incremented
{
   my $server = Conduit->new(
      listensock => "LISTEN",
      psgi_app => sub ( $env ) {
         return [ 200, [ "Content-Type" => "text/plain" ], [ "body" ] ];
      },
   );

   my $run_f;

   $controller->expect_accept( "LISTEN" )
      ->will_done( "CLIENT" );
   $controller->expect_sysread( "CLIENT", 8192 )
      ->will_done( <<'EOF' =~ s/\n/\x0D\x0A/gr );
GET / HTTP/1.1

EOF
   $controller->expect_accept( "LISTEN" )
      ->remains_pending;
   # TODO: This is fragile for buffer splitting
   $controller->expect_syswrite( "CLIENT", <<'EOF' =~ s/\n/\x0D\x0A/gr );
HTTP/1.1 200 OK
Content-Length: 4
Content-Type: text/plain

EOF
   $controller->expect_syswrite( "CLIENT", "body" );
   $controller->expect_sysread( "CLIENT", 8192 )
      ->will_done() # EOF
      ->will_also_later( sub () { $run_f->done("STOP") } );

   $run_f = $server->run;

   is( [ $run_f->get ], [ "STOP" ],
      '->run future yields STOP placeholder' );

   is_metrics( {
      "http_server_requests_in_flight"  => 0,
      "http_server_requests method:GET" => 1,
      "http_server_request_duration_total" => Test::Metrics::Any::positive,
      "http_server_responses method:GET code:200" => 1,
      "http_server_response_bytes_total" => Test::Metrics::Any::positive,
   }, 'Metrics are created for a request/response cycle' );
}

done_testing;
