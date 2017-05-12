package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::ActionRole' }

__PACKAGE__->config(namespace => q{});

sub viewa : Local Does('FindViewByIsa') FindViewByIsa('ExampleView::A') {}

sub viewb : Local Does('FindViewByIsa') FindViewByIsa('ExampleView::B') {}

sub override : Local Does('FindViewByIsa') FindViewByIsa('ExampleView::A') {
    my ($self, $c) = @_;
    $c->stash->{current_view} = 'C';
}

sub index : Private {}

sub end : ActionClass('RenderView') {}

1;
