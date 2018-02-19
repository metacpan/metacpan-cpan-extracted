# API::MikroTik - Non-blocking interface to MikroTik API. [![Build Status](https://travis-ci.org/anparker/api-mikrotik.svg?branch=master)](https://travis-ci.org/anparker/api-mikrotik)

Blocking and non-blocking API interface with queries, command subscriptions
and Promises/A+ (courtesy of [Mojo::IOLoop](http://github.com/kraih/mojo/)).

```perl
  my $api = API::MikroTik->new();

  # Blocking
  my $list = $api->command(
      '/interface/print',
      {'.proplist' => '.id,name,type'},
      {type        => ['ipip-tunnel', 'gre-tunnel'], running => 'true'}
  );
  if (my $err = $api->error) { die "$err\n" }
  printf "%s: %s\n", $_->{name}, $_->{type} for @$list;


  # Non-blocking
  my $tag = $api->command(
      '/system/resource/print',
      {'.proplist' => 'board-name,version,uptime'} => sub {
          my ($api, $err, $list) = @_;
          ...;
      }
  );
  Mojo::IOLoop->start();

  # Subscribe
  $tag = $api->subscribe(
      '/interface/listen' => sub {
          my ($api, $err, $res) = @_;
          ...;
      }
  );
  Mojo::IOLoop->timer(3 => sub { $api->cancel($tag) });
  Mojo::IOLoop->start();

  # Errors handling
  $api->command(
      '/random/command' => sub {
          my ($api, $err, $list) = @_;

          if ($err) {
              warn "Error: $err, category: " . $list->[0]{category};
              return;
          }

          ...;
      }
  );
  Mojo::IOLoop->start();

  # Promises
  $api->cmd_p('/interface/print')
      ->then(sub { my $res = shift }, sub { my ($err, $attr) = @_ })
      ->finally(sub { Mojo::IOLoop->stop() });
  Mojo::IOLoop->start();
```
