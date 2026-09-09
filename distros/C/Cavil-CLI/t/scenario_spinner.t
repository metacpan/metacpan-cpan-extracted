# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

use Mojo::Base -strict, -signatures;

use Test::More;
use Cavil::CLI::Client;
use Mojo::IOLoop;
use Mojolicious::Lite;

app->log->level('error');

# A deliberately slow response, so the in-flight window is long enough for the wait callback to fire. Sharing
# the user agent's loop with the singleton lets this delay timer run on the same loop the blocking request does.
get '/api/v1/whoami' => sub ($c) {
  $c->render_later;
  Mojo::IOLoop->timer(0.25 => sub { $c->render(json => {id => 1, user => 'tester'}) });
};

my $client = Cavil::CLI::Client->new(token => 'test-token');
$client->ua->ioloop(Mojo::IOLoop->singleton);
$client->url('http://127.0.0.1:' . $client->ua->server->app(app)->url->port);

subtest 'the wait callback fires while a request is in flight' => sub {
  my $ticks = 0;
  $client->on_wait(sub { $ticks++ });
  my $info = $client->whoami;
  is $info->{user}, 'tester', 'the delayed response still comes back';
  ok $ticks >= 1, "the spinner was driven during the wait (ticked $ticks times)";
};

done_testing;
