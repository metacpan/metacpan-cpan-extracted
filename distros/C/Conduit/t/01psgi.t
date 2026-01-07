#!/usr/bin/perl

use v5.36;

use Test2::V0;
use Test::Future::IO;

use Conduit;

my $controller = Test::Future::IO->controller;

# PSGI returning 3-element value, ARRAY body
{
   my $server = Conduit->new(
      listensock => "LISTEN",
      psgi_app => sub ( $env ) {
         return [ 200, [ "Content-Type" => "text/plain" ], [ "body 1" ] ];
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

   $controller->check_and_clear( 'PSGI ARRAY-returning GET with ARRAY body' );
}

# PSGI returning 3-element value, IO body
{
   open my $bodyfh, "<", \"body 2";

   my $server = Conduit->new(
      listensock => "LISTEN",
      psgi_app => sub ( $env ) {
         return [ 200, [ "Content-Type" => "text/plain" ], $bodyfh ];
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
Transfer-Encoding: chunked
Content-Type: text/plain

EOF
   $controller->expect_syswrite( "CLIENT", "6\x0D\x0A" . "body 2" );
   $controller->expect_syswrite( "CLIENT", "0\x0D\x0A\x0D\x0A" );
   $controller->expect_sysread( "CLIENT", 8192 )
      ->will_done() # EOF
      ->will_also_later( sub () { $run_f->done("STOP") } );

   $run_f = $server->run;

   is( [ $run_f->get ], [ "STOP" ],
      '->run future yields STOP placeholder' );

   $controller->check_and_clear( 'PSGI ARRAY-returning GET with IO body' );
}

# PSGI POST receives request body
{
   my $received_body;

   my $server = Conduit->new(
      listensock => "LISTEN",
      psgi_app => sub ( $env ) {
         $received_body = do { local $/; $env->{"psgi.input"}->getline };

         return [ 200, [ "Content-Type" => "text/plain" ], [ "posted" ] ];
      },
   );

   my $run_f;

   $controller->expect_accept( "LISTEN" )
      ->will_done( "CLIENT" );
   $controller->expect_sysread( "CLIENT", 8192 )
      ->will_done( <<'EOF' =~ s/\n/\x0D\x0A/gr );
POST / HTTP/1.1
Content-Length: 20

The body goes here
EOF
   $controller->expect_accept( "LISTEN" )
      ->remains_pending;
   # TODO: This is fragile for buffer splitting
   $controller->expect_syswrite( "CLIENT", <<'EOF' =~ s/\n/\x0D\x0A/gr );
HTTP/1.1 200 OK
Content-Length: 6
Content-Type: text/plain

EOF
   $controller->expect_syswrite( "CLIENT", "posted" );
   $controller->expect_sysread( "CLIENT", 8192 )
      ->will_done() # EOF
      ->will_also_later( sub () { $run_f->done("STOP") } );

   $run_f = $server->run;

   is( [ $run_f->get ], [ "STOP" ],
      '->run future yields STOP placeholder' );

   is( $received_body, "The body goes here\x0D\x0A",
      'PSGI env received the request body' );

   $controller->check_and_clear( 'PSGI ARRAY-returning GET with ARRAY body' );
}

done_testing;
