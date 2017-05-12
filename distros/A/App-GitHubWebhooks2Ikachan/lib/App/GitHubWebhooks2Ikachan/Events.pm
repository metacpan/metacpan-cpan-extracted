package App::GitHubWebhooks2Ikachan::Events;
use strict;
use warnings;
use utf8;
use Class::Accessor::Lite(
    new => 1,
    ro  => [qw/dat req/],
);

sub dispatch {
    my ($self, $event_name) = @_;

    my $subscribe_all     = 0;
    my $subscribed_events = {};
    my $subscribe = $self->req->param('subscribe');
    if (!$subscribe) {
        $subscribe_all = 1;
    }
    else {
        for my $subscribed_event (split(/,/, $subscribe)) {
            $subscribed_events->{$subscribed_event} = 1;
        }
    }

    my $klass = __PACKAGE__ . '::' . join('', map({ ucfirst ($_) } split(/_/, $event_name)));
    eval "require $klass"; ## no critic
    if ($@) {
        return; # Not supported event
    }

    if ($subscribe_all || $subscribed_events->{$event_name}) {
        return $klass->call($self);
    }

    return; # Not subscribed event
}

1;
