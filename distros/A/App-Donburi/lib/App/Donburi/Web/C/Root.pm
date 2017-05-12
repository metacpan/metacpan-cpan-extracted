package App::Donburi::Web::C::Root;
use strict;
use warnings;
use parent 'App::Donburi::Web::C';

use App::Donburi::Util;

sub do_index {
    my $self = shift;

    return { channels => store(), logs => [reverse @{logger()->logs()}] };
}

sub do_post {
    my $self = shift;

    my $chan = $self->req->param('channel');
    send_chan($chan, 'NOTICE', $chan, $self->req->param('message'));

    return;
}

1;
