#!/usr/bin/perl

use v5.36;

use Test2::V0;
use Test::Future::IO;

use Conduit;

my $controller = Test::Future::IO->controller;

# PSGI returning sub {}
{
   my $server = Conduit->new(
      listensock => "LISTEN",
      psgi_app => sub ( $env ) {
         return sub ( $responder ) {
            $responder->([ 200, [ "Content-Type" => "text/plain" ], [ "body 1" ] ]);
         };
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
Content-Length: 6
Content-Type: text/plain

EOF
   $controller->expect_syswrite( "CLIENT", "body 1" );
   $controller->expect_sysread( "CLIENT", 8192 )
      ->will_done() # EOF
      ->will_also_later( sub () { $run_f->done("STOP") } );

   $run_f = $server->run;

   is( [ $run_f->get ], [ "STOP" ],
      '->run future yields STOP placeholder' );

   $controller->check_and_clear( 'PSGI CODE-returning GET' );
}

done_testing;
