package Simplyst::Controller::Simple;

use strict;
use warnings;
use base 'Catalyst::Controller';

sub from_plack :Path('/foo') :ActionClass('FromPSGI') {
   A::App->to_psgi_app
}

sub from_plack2 :Path('/bar') :ActionClass('FromPSGI') {
   A::App2->to_psgi_app
}

sub from_plack3 :Path('/msg') :ActionClass('FromPSGI') {
   A::App3->new(msg => 'yolo')->to_psgi_app
}

sub from_plack_deferred :Path('/deferred') :ActionClass('FromPSGI') {
   sub {
      my ($env) = @_;
      return sub {
         my $responder = shift;
         $responder->([ 200, ['Content-type' => 'text/plain'], ['Hello from a deferred response']]);
      }
   }
}

sub from_plack_stream :Path('/stream') :ActionClass('FromPSGI') {
   my $app = sub {
      my $env = shift;

      return sub {
         my $responder = shift;
         my $writer = $responder->(
            [ 200, [ 'Content-Type', 'application/json' ]]);

         $writer->write('/');
         $writer->write('w');
         $writer->write('o');
         $writer->write('o');
         $writer->write('!');
         $writer->close;
      }
   }
}

1;

BEGIN {
package A::App;

use Web::Simple;

sub dispatch_request {
   sub (/) { [ 200, [ 'Content-type' => 'text/plain' ], [ 'Hello world' ] ] },
   sub (/foo) { [ 200, [ 'Content-type' => 'text/plain' ], [ 'Hello foo' ] ] },
   sub (/foo/) { [200,  [ 'Content-type' => 'text/plain' ], [ 'Hello foo/' ] ] },
}

}

BEGIN {
package A::App2;

use Web::Simple;

sub dispatch_request {
   sub (/) { [ 200, [ 'Content-type' => 'text/plain' ], [ 'Hello world, from bar' ] ] },
   sub (/foo) { [ 200, [ 'Content-type' => 'text/plain' ], [ 'Hello foo, from bar' ] ] },
}

}

BEGIN {
package A::App3;

use Web::Simple;

has msg => (
   is => 'ro',
   required => 1,
);

sub dispatch_request {
   sub (/) { [ 200, [ 'Content-type' => 'text/plain' ], [ $_[0]->msg ] ] },
}

}
