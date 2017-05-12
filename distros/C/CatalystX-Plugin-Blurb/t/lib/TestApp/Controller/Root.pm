package TestApp::Controller::Root;
use parent "Catalyst::Controller";
use strict;
use warnings;

__PACKAGE__->config(namespace => "");

# your actions replace this one
sub main :Path { $_[1]->res->body('<h1>It works</h1>') }

sub one :Local {
    my ( $self, $c ) = @_;
    $c->blurb("OK");
    $c->res->body($c->blurb);
}

sub one_by_two :Local {
    my ( $self, $c ) = @_;
    $c->blurb("moo");
    $c->blurb("OK");

    my $body = "";
    for my $blurb ( $c->blurb ) {
        $body .= "$blurb\n";
    }
    $c->res->body($body);
}

sub two_by_one_flat :Local {
    my ( $self, $c ) = @_;
    $c->blurb("moo", "OK");

    my $body = "";
    for my $blurb ( $c->blurb ) {
        $body .= "$blurb\n";
    }
    $c->res->body($body);
}

sub two_by_one_ref :Local {
    my ( $self, $c ) = @_;
    $c->blurb(["moo", "OK"]);

    my $body = "";
    for my $blurb ( $c->blurb ) {
        $body .= "$blurb\n";
    }
    $c->res->body($body);
}

sub one_ref :Local {
    my ( $self, $c ) = @_;
    $c->blurb({ content => "OK" });
    $c->res->body($c->blurb);
}

sub two_by_two_ref :Local {
    my ( $self, $c ) = @_;
    $c->blurb({
               id => 1,
               content => "moo",
              },
              {
               id => 2,
               content => "OK"
              });

    my $body = "";
    for my $blurb ( $c->blurb ) {
        $body .= "$blurb\n";
    }
    $c->res->body($body);
}



1;
