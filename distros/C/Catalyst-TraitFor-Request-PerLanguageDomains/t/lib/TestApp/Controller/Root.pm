package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => q{});

sub index : Path { }

sub get_lang :Local {
     my ($self, $c) = @_;
     $c->res->body($c->req->language);
}

sub set_lang :Local {
     my ($self, $c, $lang) = @_;

     $c->session->{'language'} = $lang;
     $c->res->body($c->req->language);
}


sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

