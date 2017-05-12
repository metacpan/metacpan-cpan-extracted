package Gauge::AnyEvent_Curl_Multi;
use strict;
use utf8;
use warnings qw(all);

use Any::Moose;
with qw(Gauge::Role);

use AnyEvent;
use AnyEvent::Curl::Multi;
use HTTP::Request::Common qw(GET);
use WWW::Curl::Easy;

sub run {
    my ($self) = @_;

    my $multi = AnyEvent::Curl::Multi->new;
    $multi->max_concurrency($self->parallel);
    $multi->reg_cb(
        response => sub {
            my ($client, $request, $response, $stats) = @_;
        }
    );
    $multi->reg_cb(
        error => sub {
            my ($client, $request, $errmsg, $stats) = @_;
        }
    );
    my @multi = map {
        sub {
            my $req = $multi->request(shift);

            # Disable compression
            $req->{easy_h}->setopt(CURLOPT_ENCODING, q(identity));

            # UA string
            $req->{easy_h}->setopt(CURLOPT_USERAGENT, qq(AnyEvent::Curl::Multi/$AnyEvent::Curl::Multi::VERSION));

            return $req;
        }->(GET($_))
    } @{$self->queue};
    $_->cv->recv for @multi;

    return;
}

1;
