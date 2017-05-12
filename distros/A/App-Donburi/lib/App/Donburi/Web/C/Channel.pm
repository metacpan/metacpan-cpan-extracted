package App::Donburi::Web::C::Channel;
use strict;
use warnings;
use parent 'App::Donburi::Web::C';

use App::Donburi::Util;

sub do_index {
    my $self = shift;

    return { channels => store() };
}

sub do_add {
    my $self = shift;

    my $store = store();
    my $chan  = $self->req->param('channel');
    unless ( !$chan || grep { $chan eq $_ } @$store ) {
        push @$store, $chan;
        send_srv("JOIN", $chan);
    }

    return $self->redirect('/channel/');
}

sub do_delete {
    my $self = shift;

    my $store = store();
    my $chan  = $self->req->param('channel');

    store([grep { $chan ne $_ } @$store]);
    send_srv("PART", $chan);

    return $self->redirect('/channel/');
}

1;
