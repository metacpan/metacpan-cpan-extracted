## Basic example

This is a working barebones example of the usage of Beekeper.


To run this example start a worker pool of `MyWorker` processes:
```
cd beekeper/examples/basic
source setup.sh
./run.sh
```
Then make a request to the worker pool, using `MyClient` client:
```
./client.pl
```
When done, stop the worker pool with:
```
./run.sh stop
```
---

### ActiveMQ setup

This example uses the internal ToyBroker to allow being run out of the box.

To run this example on a fresh install of ActiveMQ just set `use_toybroker` to false in config file `pool.config.json`. Also ensure that `host` addresses in `bus.config.json` and `config.js` match ActiveMQ one.


### RabbitMQ setup

To run this example on a fresh install of RabbitMQ set `use_toybroker` to false in config file
`pool.config.json`. Also ensure that `host` addresses in `bus.config.json` and `config.js` match RabbitMQ one.

Then configure RabbitMQ (enable STOMP, add an user `test` and a virtual host `/test`) with the following commands:

```
rabbitmq-plugins enable rabbitmq_stomp

rabbitmqctl add_user test abc123

rabbitmqctl add_vhost /test

rabbitmqctl set_permissions test -p /test ".*" ".*" ".*"

rabbitmqctl set_policy expiry -p /test ".*" '{"expires":60000}' --apply-to queues
```
