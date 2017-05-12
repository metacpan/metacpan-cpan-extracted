package TestAppInheritedComponent::Controller::Root;

use strict;
use warnings;
use base qw/Catalyst::Controller/;
use Data::Dumper;

__PACKAGE__->config(namespace => '');

sub filter {
    my ($self, $params) = @_;

    my @parts = map { $_ . '=' . $params->{$_} } keys %$params;
    my $filter = '(' . join('&', @parts) . ')';

    return $filter;
}

sub search : Local {
    my ($self, $c) = @_;

    my $filter = $self->filter($c->request->params);
    my $mesg = $c->model('LDAP')->search($filter);

    $c->stash(entries => [ $mesg->entries ]);
    $c->forward('results');
}
sub results : Local {
    my ($self, $c) = @_;

    $c->response->content_type('text/plain');
    $c->response->body(Dumper($c->stash));
}

1;
