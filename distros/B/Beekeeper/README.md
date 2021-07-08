# Beekeeper

Beekeeper is a framework for building applications with a microservices architecture.

![](./doc/images/beekeeper.svg)

A pool of worker processes handle requests and communicate with each other through a common message bus.

Clients send requests through a different set of message buses, which are isolated for security reasons.

Requests and responses are shoveled between buses by a few router processes.


**Benefits of this architecture:**

- Scales horizontally very well. It is easy to add or remove workers, routers or brokers.

- High availability. The system remains responsive even when several components fail.

- Easy integration of browsers via WebSockets or clients written in other languages.


**Key characteristics:**

- The broker is an MQTT messaging server, like Mosquitto, HiveMQ or EMQ X.

- The messaging protocol is MQTT 5 (see the [specification](https://docs.oasis-open.org/mqtt/mqtt/v5.0/mqtt-v5.0.html)).

- The RPC protocol is JSON-RPC 2.0 (see the [specification](https://www.jsonrpc.org/specification)).

- There is no message persistence in the broker, it just passes on messages.

- There is no routing logic defined in the broker.

- Synchronous and asynchronous workers or clients can be integrated seamlessly.

- Efficient multicast and unicast push notifications.

- Inherent load balancing.


**What does this framework provides:**

- `Beekeeper::Worker`, to create service workers.

- `Beekeeper::Client`, to create service clients.

- `bkpr` command which spawns and controls worker processes.

- Command line tools for monitoring and controlling worker pools.

- An internal broker suitable for development or running tests. 

- Automatic message routing between frontend and backend buses.

- Centralized logging, which can be shoveled to an external monitoring application.

- Performance metrics gathering, which can be shoveled to an external monitoring application.


## Getting Started

### Creating workers

Workers provide a service accepting certain RPC calls from clients. The base class `Beekeeper::Worker` 
provides all the glue needed to accept requests and communicate trough the message bus with clients 
or another workers.

A worker class just declares on startup which methods it will accept, then implements them:

```
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
```

### Creating clients

Clients of the service need an interface to use it without knowledge of the underlying RPC mechanisms.
The class `Beekeeper::Client` provides methods to connect to the broker and make RPC calls.

This is the interface of the above service:

```
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
```
Then other workers or clients can just:
```
use MyApp::Client;

print MyApp::Client->uppercase("hello!");
```

### Configuring

Beekeeper applications use two config files to define how clients, workers and brokers connect to 
each other. These files are looked for in ENV `BEEKEEPER_CONFIG_DIR`, `~/.config/beekeeper` and 
then `/etc/beekeeper`. File format is relaxed JSON, which allows comments and trailing commas.

The file `pool.config.json` defines all worker pools running on a host, specifying which logical bus
should be used and which services it will run. For example:

```
[{
    "pool_id" : "myapp",
    "bus_id"  : "backend",
    "workers" : {
        "MyApp::Worker" : { "worker_count" : 4 },
    },
}]
```
The file `bus.config.json` defines all logical buses used by the application, specifying the connection
parameters to the brokers that will service them. For example:

```
[{
    "bus_id"   : "backend",
    "host"     : "localhost",
    "username" : "backend",
    "password" : "def456",
}]
```
Neither the worker code nor the client code have hardcoded references to the logical message bus or
the broker connection parameters, these communicate to each other using the definitions in these two files.


### Running

To start or stop a pool of workers you use the `bkpr` command. Given the above example config, this 
will start 4 processes running `MyApp::Worker` code:
```
bkpr --pool "myapp" start
```
When started it daemonizes itself and forks all worker processes, then continues monitoring those forked
processes and immediately respawns defunct ones.

The framework includes these command line tools to manage worker pools:

- `bkpr-top` allows to monitor in real time the performance of workers.

- `bkpr-log` allows to monitor in real time the log output of workers.

- `bkpr-restart` gracefully restarts worker pools.


## Performance

Beekeeper is pretty lightweight for being pure Perl, but the performance depends mostly on the broker
performance, particularly on the broker introduced latency. The following are conservative performance
estimations:

- A `call_remote` synchronous call to a remote method involves 4 MQTT messages and takes 0.7 ms.
  This limits a client to make a maximum of 1400 synchronous calls per second. The CPU load will be
  very low, as the client spends most of the time just waiting for the response.

- A `call_remote_async` asynchronous call to a remote method also involves 4 MQTT messages, but it
  can sustain a rate of 8000 calls per second because it does not block waiting for responses.

- Launching a remote task with `fire_remote` involves 1 MQTT message and takes 0.1 ms. This implies
  a maximum of 10000 calls per second.

- Sending a notification with `send_notification` involves 1 MQTT message and takes 0.1 ms. A worker
  can emit more than 10000 notifications per second, up to 15000 if these are smaller than 1 KiB.

- A worker processing remote calls can handle a maximum of 4000 requests per second. It will be I/O
  bound, the CPU load will be low for simple tasks, as the worker will spend a significant chunk of
  time waiting for messages.

- A worker can receive a maximum of 15000 notifications per second. It will be CPU bound.

- An empty worker uses 10 MiB of resident memory for the perl interpreter and the few required modules.
  After adding actual code to do useful work the memory usage will of course increase.

- A single router can handle around 5000 messages per second.

- Routers add 2 ms to frontend requests roundtrip.


## Examples

This distribution includes some examples that can be run out of the box using an internal `ToyBroker`
(so no install of a proper broker is needed):

[examples/basic](./examples/basic) is a barebones example of the usage of Beekeper.

[examples/flood](./examples/flood) allows to estimate the performance of a Beekeper setup.

[examples/scraper](./examples/scraper) demonstrates asynchronous workers and clients.

[examples/websocket](./examples/websocket) uses a service from a browser using WebSockets.

[examples/chat](./examples/chat) implements a real world setup with isolated buses and redundancy.


## See also

- [Notes about supported MQTT brokers](./doc/Brokers.md) configuration.

- [Diagram of message routing](https://raw.githubusercontent.com/jmico/beekeeper/master/doc/images/routing.svg)
  between clients, workers and buses.

- https://metacpan.org/release/Beekeeper


## Dependencies

This framework requires `Anyevent`, `JSON::XS`, `Term::ReadKey`, and `ps`.

To install these dependencies on a Debian system run:
```
apt install libanyevent-perl
apt install libjson-xs-perl
apt install libterm-readkey-perl
apt install procps
```

## License

Copyright 2015-2021 José Micó.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language itself.
