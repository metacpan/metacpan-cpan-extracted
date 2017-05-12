package TestApp::Controller::Root;
use strict;
use warnings;

use base qw/Catalyst::Controller/;

sub begin : Private {
    my ( $self, $c ) = @_;
    $c->res->body('1');
}

sub subtest : Global {
    my ( $self, $c ) = @_;
    my $subreq= $c->res->body().
                $c->subreq('/normal/4');
    $c->res->body($subreq);
}

sub normal : Global {
    my ( $self, $c, $arg ) = @_;
    $c->res->body($c->res->body().$arg);
}

sub subtest_params : Global {
    my ( $self, $c ) = @_;
    my $before = $c->req->params->{value};
    my $subreq = $c->subreq('/normal/2');
    my $after = $c->req->params->{value};
    $c->res->body($c->res->body().$after);
}

sub subtest_req : Global {
    my ( $self, $c ) = @_;
    my $subreq = $c->subreq('/normal/2');
    my $after = $c->req->uri->path;
    $c->res->body($after);
}

sub subtest_full_response : Global {
    my ( $self, $c ) = @_;
    my $subreq_res = $c->subreq_res('/typesetter');
    $c->res->body( $c->res->body() . $subreq_res->content_type );
}

sub subtest_with_params :Global {
  my($self, $c) = @_;
  $c->res->body(
    $c->subrequest('/plain_param', {},
      { content => 'foo' }));
}

sub plain_param :Global {
  my($self, $c) = @_;
  $c->res->body($c->req->params->{content});
}

sub typesetter : Global {
    my ( $self, $c, $arg ) = @_;
    $c->res->content_type( 'text/csv' );
    $c->res->body($c->res->body());
}

sub doublesubtest :Global {
    my ( $self, $c) = @_;
    $c->res->body(
      $c->subrequest('/normal/5').
      $c->subrequest('/normal/6')
    );
}

sub end : Private {
    my ( $self, $c ) = @_;
    $c->res->body($c->res->body().'3');
}

1;

