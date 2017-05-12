package Simplyst::Controller::Complex;

use strict;
use warnings;
use base 'Catalyst::Controller';

use Plack::Request;

sub from_plack :Local :ActionClass('FromPSGI') {
   A::App::Complex->new(whence => 'local')->to_psgi_app
}

sub globule :Global :ActionClass('FromPSGI') {
   A::App::Complex->new(whence => 'globule')->to_psgi_app
}

sub base : Chained('/') PathPart('chain1') CaptureArgs(1) {
   my ($self, $c, @args) = @_;
   $c->stash->{args} = [@args];
}
sub middle_chain : Chained('base') PathPart('middle') CaptureArgs(1) {
   my ($self, $c, @args) = @_;
   push @{$c->stash->{args}}, @args;

}
sub end_chain : Chained('middle_chain') PathPart('end') ActionClass('FromPSGI') {
   my ($self, $c, @args) = @_;

   my $a = join ', ', @{$c->stash->{args}};
   A::App::Complex->new(whence => "chain: $a")->to_psgi_app
}

sub post_content :Local :ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    my $app = sub {
        my ($env) = @_;
        my $request = Plack::Request->new( $env );
        my $content = $request->content;
        return ['200', ['Content-Type' => 'text/plain'], [$content]];
    };
    return $app;
}

sub post_content2 :Local :ActionClass('FromPSGI') {
   A::App::PostBody->new->to_psgi_app
}

1;

BEGIN {
package A::App::Complex;

use Web::Simple;

has whence => (
   is => 'ro',
   required => 1,
);

sub dispatch_request {
   sub (/foo) {
      [ 200,
         [ 'Content-type' => 'text/plain' ],
         [ 'Hello ' . $_[0]->whence . ' world' ]
      ]
   },
}

package A::App::PostBody;

use Web::Simple;

sub dispatch_request {
   sub (POST + %foo~) {
      [ 200,
         [ 'Content-type' => 'text/plain' ],
         [ $_[1]||'' ]
      ]
   },
}
}

