package WookieServe::Controller::Root;

use Moose;

BEGIN {
    extends 'Catalyst::Controller';
    };

__PACKAGE__->config->{namespace} = '';

sub hairy_wookies : Global {
    my ($self, $c) = @_;
    $c->stash->{wanted} = 'hairy';
    return $self->get_wookies($c);
    }

sub scary_wookies : Global {
    my ($self, $c) = @_;
    $c->stash->{wanted} = 'scary';
    return $self->get_wookies($c);
    }

sub get_wookies {
    my ($self, $c) = @_;
    my $db = $c->model('Wookies');
    my $wookie = $db->resultset('Wookie')->first;
    return $c->res->body($wookie->name);
    }

1;
