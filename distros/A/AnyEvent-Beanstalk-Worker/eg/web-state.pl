#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

use lib 'eg';
use WebWorker;

my $w = WebWorker->new
  ( concurrency     => 1,  ## crank this up to 10000 for some real action
    max_stop_tries  => 1,
    initial_state   => 'fetch',
    beanstalk_watch => "urls" );

$w->beanstalk->use("urls")->recv;

$w->on(fetch => sub {
    my ($self, $job, $resp) = @_;

    say STDERR "fetching " . $job->data;
    $w->{ua}->get($job->data, sub { $self->emit(receive => $job, @_) });
});

$w->on(receive => sub {
    my ($self, $job, undef, $tx) = @_;

    if ( $tx->error ) {
        warn "Moved or some error: " . $tx->error;
        return $self->finish(delete => $job->id);
    }

    unless ($tx->res->headers->content_type =~ /html/i) {
        warn "Not HTML; skipping\n";
        return $self->finish(delete => $job->id);
    }

    say STDERR "parsing " . $job->data;
    eval {
        $tx->res->dom->at("html body")->find('a[href]')
          ->each(sub { $self->emit(add_url => shift->{href}) });
    };

    return $self->finish(delete => $job->id);
});

$w->on(add_url => sub {
    my ($self, $url) = @_;

    return unless $url =~ /^http/;

    $self->beanstalk
      ->put({ priority => 100,
              ttr      => 15,
              delay    => 1,
              data     => $url },
            sub { say STDERR "URL $url added" });
});

$w->start;

EV::run;
