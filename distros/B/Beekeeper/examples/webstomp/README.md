## WebStomp example

This example shows how to use services from browsers using WebSockets.


To run this example start the worker pool:
```
cd beekeper/examples/webstomp
source setup.sh
./run.sh
```
Then open `client.html` in a browser, or use the command line client:
```
./client.pl
```
When done, stop the worker pool with:
```
./run.sh stop
```
---

### ActiveMQ setup

This example uses the internal ToyBroker to allow being run out of the box, but to use `client.html` the WebSockets capabilities of ActiveMQ or RabbitMQ are required (`client.pl` works fine though).

To run this example on a fresh install of ActiveMQ just set `use_toybroker` to false in config file `pool.config.json`. Also ensure that `host` addresses in `bus.config.json` and `config.js` match ActiveMQ one.

Note that ActiveMQ does not support virtual hosts, so this example will not use two different brokers as it should (it works anyway because queue names do not clash).


### RabbitMQ setup

To run this example on a fresh install of RabbitMQ set `use_toybroker` to false in config file
`pool.config.json`. Also ensure that `host` addresses in `bus.config.json` and `config.js` match RabbitMQ one.

Then configure RabbitMQ (enable STOMP and create the required users and virtual hosts) with the following commands:

```
rabbitmq-plugins enable rabbitmq_stomp
rabbitmq-plugins enable rabbitmq_web_stomp

rabbitmqctl add_user frontend abc123
rabbitmqctl add_user backend def456

rabbitmqctl add_vhost /frontend
rabbitmqctl add_vhost /backend

rabbitmqctl set_permissions frontend -p /frontend ".*" ".*" ".*"
rabbitmqctl set_permissions backend  -p /backend  ".*" ".*" ".*"
rabbitmqctl set_permissions backend  -p /frontend ".*" ".*" ".*"

rabbitmqctl set_policy expiry -p /backend  ".*" '{"expires":60000}' --apply-to queues
rabbitmqctl set_policy expiry -p /frontend ".*" '{"expires":60000}' --apply-to queues

rabbitmqctl set_topic_permissions frontend -p /frontend amq.topic "" "^msg.frontend.*"
```
---

This example uses the STOMP.js library Copyright 2010-2013 [Jeff Mesnil](http://jmesnil.net/), Copyright 2012 [FuseSource, Inc.](http://fusesource.com), Copyright 2017 [Deepak Kumar](https://www.kreatio.com).
Currently maintained at <https://github.com/stomp-js/stomp-websocket>.
