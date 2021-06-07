package Beekeeper;

use strict;
use warnings;

our $VERSION = '0.04';

1;

__END__

=pod

=encoding utf8

=head1 NAME
 
Beekeeper - Framework for building applications with a microservices architecture
 
=head1 VERSION
 
Version 0.04

=head1 SYNOPSIS

Create a service:

  package My::Service::Worker;
  
  use base 'Beekeeper::Worker';
  
  sub on_startup {
      my $self = shift;
      
      $self->accept_remote_calls( 'my.service.echo' => 'echo' );
      
      $self->accept_notifications( 'my.service.msg' => 'msg' );
  }
  
  sub echo {
      my ($self, $params) = @_;
      return $params;
  }
  
  sub msg {
      my ($self, $params) = @_;
      warn $params->{msg};
  }

Create an API for the service:

  package My::Service;
  
  use Beekeeper::Client;
  
  sub msg {
      my ($class, $message) = @_;
      my $cli = Beekeeper::Client->instance;
      
      $cli->send_notification(
          method => "my.service.msg",
          params => { msg => $message },
      );
  }
  
  sub echo {
      my ($class, %args) = @_;
      my $cli = Beekeeper::Client->instance;
      
      my $result = $cli->call_remote(
          method => "my.service.echo",
          params => \%args,
      );
  
      return $result;
  }

Use the service from a client:

  package main;
  use My::Service;
  
  My::Service->msg( "foo!" );
  
  My::Service->echo( foo => "bar" );


=head1 DESCRIPTION

Beekeeper is a framework for building applications with a microservices architecture.

=begin HTML

<p><img src="https://raw.githubusercontent.com/jmico/beekeeper/master/doc/images/beekeeper.svg"/></p>

=end HTML

A pool of worker processes handle requests and communicate with each other through a common message bus.

Clients send requests through a different set of message buses, which are isolated for security reasons.

Requests and responses are shoveled between buses by a few router processes.


B<Benefits of this architecture:>

- Scales horizontally very well. It is easy to add or remove workers, routers or brokers.

- High availability. The system remains responsive even when several components fail.

- Easy integration of browsers via WebSockets or clients written in other languages.


B<Key characteristics:>

- The broker is an MQTT messaging server, like Mosquitto, HiveMQ or EMQ X.

- The messaging protocol is MQTT 5 (see the L<specification|https://docs.oasis-open.org/mqtt/mqtt/v5.0/mqtt-v5.0.html>).

- The RPC protocol is JSON-RPC 2.0 (see the L<specification|https://www.jsonrpc.org/specification>).

- There is no message persistence in the broker, it just passes on messages.

- There is no routing logic defined in the broker.

- Synchronous and asynchronous workers or clients can be integrated seamlessly.

- Efficient multicast and unicast push notifications.

- Inherent load balancing.


B<What does this framework provides:>

- L<Beekeeper::Worker>, to create service workers.

- L<Beekeeper::Client>, to create service clients.

- L<bkpr> command which spawns and controls worker processes.

- Command line tools for monitoring and controlling worker pools.

- An internal broker suitable for development or running tests. 

- Automatic message routing between frontend and backend buses.

- Centralized logging, which can be shoveled to an external monitoring application.

- Performance metrics gathering, which can be shoveled to an external monitoring application.


=head1 Getting Started

=head3 Creating workers

Workers provide a service accepting certain RPC calls from clients. The base class L<Beekeeper::Worker> 
provides all the glue needed to accept requests and communicate trough the message bus with clients 
or another workers.

A worker class just declares on startup which methods it will accept, then implements them:

  package MyApp::Worker;
  
  use base 'Beekeeper::Worker';
  
  sub on_startup {
      my $self = shift;
  
      $self->accept_remote_calls(
          'myapp.str.uc' => 'uppercase',
      );
  }
  
  sub uppercase {
      my ($self, $params) = @_;
  
      return uc $params->{'string'};
  }


=head3 Creating clients

Clients of the service need an interface to use it without knowledge of the underlying RPC mechanisms.
The class L<Beekeeper::Client> provides methods to connect to the broker and make RPC calls.

This is the interface of the above service:

  package MyApp::Client;
  
  use Beekeeper::Client;
  
  sub uppercase {
      my ($class, $str) = @_;
  
      my $client = Beekeeper::Client->instance;
  
      my $resp = $client->call_remote(
          method => 'myapp.str.uc',
          params => { string => $str },
      );
  
      return $resp->result;
  }

Then other workers or clients can just:

  use MyApp::Client;
  
  print MyApp::Client->uppercase("hello!");


=head3 Configuring

Beekeeper applications use two config files to define how clients, workers and brokers connect to 
each other. These files are looked for in ENV C<BEEKEEPER_CONFIG_DIR>, C<~/.config/beekeeper> and 
then C</etc/beekeeper>. File format is relaxed JSON, which allows comments and trailing commas.

The file C<pool.config.json> defines all worker pools running on a host, specifying which logical bus
should be used and which services it will run. For example:

  [{
      "pool_id" : "myapp",
      "bus_id"  : "backend",
      "workers" : {
          "MyApp::Worker" : { "workers_count" : 4 },
      },
  }]

The file C<bus.config.json> defines all logical buses used by the application, specifying the connection
parameters to the brokers that will service them. For example:

  [{
      "bus_id"   : "backend",
      "host"     : "localhost",
      "username" : "backend",
      "password" : "def456",
  }]

Neither the worker code nor the client code have hardcoded references to the logical message bus or
the broker connection parameters, these communicate to each other using the definitions in these two files.


=head3 Running

To start or stop a pool of workers you use the L<bkpr> command. Given the above example config, this 
will start 4 processes running C<MyApp::Worker> code:

  bkpr --pool "myapp" start

When started it daemonizes itself and forks all worker processes, then continues monitoring those forked
processes and immediately respawns defunct ones.

The framework includes these command line tools to manage worker pools:

- L<bkpr-top> allows to monitor in real time the performance of workers.

- L<bkpr-log> allows to monitor in real time the log output of workers.

- L<bkpr-restart> gracefully restarts worker pools.


=head1 Performance

Beekeeper is pretty lightweight for being pure Perl, but the performance depends mostly on *the broker*
performance, particularly on the broker introduced latency. These are ballpark performance estimations:

- A C<call_remote> synchronous call involves 4 MQTT messages. A broker adds around 3 ms of latency 
  processing these 4 messages, so this limits a single client to make a maximum of 350 synchronous 
  calls per second. The cpu load will be very low (less than 1%), as the client spends most of the
  time waiting for messages.

- A C<call_remote_async> asynchronous call to a remote method takes 0.3 ms. This implies a maximum of
  3500 asynchronous calls per second (just the call, then it must wait for responses).

- Launching a remote task with C<fire_remote> involves 1 MQTT message and takes 0.1 ms. This implies
  a maximum of 10000 calls per second.

- Sending a notification with C<send_notification> involves 1 MQTT message and takes 0.1 ms. A worker
  can emit more than 10000 notifications per second, even 15000 if these are smaller than 1 KB.

- A worker processing remote calls has around 1.5 ms of latency introduced by the 2 MQTT messages
  involved. So a single worker can handle a maximum of 650 requests per second. The cpu load will
  be low for simple tasks, as the worker will spend a significant chunk of time waiting for messages.

- A worker uses 10 MB of resident memory from perl and the few required modules. After adding actual
  code to do useful work the memory usage will of course increase. As a lot of workers will be required
  to handle a substantial number of requests, there will be some memory pressure. 

- A single router can handle around 3000 requests per second.

- Routers add 2 ms to frontend requests roundtrip.


=head1 Examples

This distribution includes some examples that can be run out of the box using an internal C<ToyBroker>
(so no install of a proper broker is needed):

C<examples/basic> is a barebones example of the usage of Beekeper.

C<examples/flood> allows to estimate the performance of a Beekeper setup.

C<examples/websocket> uses a service from a browser using WebSockets.

C<examples/chat> implements a real world setup with isolated buses and redundancy.


=head1 SEE ALSO

L<Notes about supported MQTT brokers|https://github.com/jmico/beekeeper/blob/master/doc/Brokers.md> configuration.

L<Diagram of message routing|https://raw.githubusercontent.com/jmico/beekeeper/master/doc/images/routing.svg> between clients, workers and buses.

L<Beekeeper::WorkerPool>, L<Beekeeper::Client>, L<Beekeeper::Worker>.

=head1 SOURCE REPOSITORY
 
The source code repository for Beekeeper can be found at L<https://github.com/jmico/beekeeper>

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
