## WebSocket example

This example demonstrates the use of services from browsers using WebSockets.


To run this example start the worker pool:
```
cd beekeper/examples/websocket
source setup.sh
./run.sh
```
Then open `client.html` in a browser, or use the command line client:
```
./client.pl
```
The JSON-RPC traffic will be dumped on browser console. You can check the pool status with 
`bkpr-top` or watch the stream of exceptions that this example may generate with `bkpr-log -f`. 

Finally stop the worker pool with:
```
./run.sh stop
```
---

### Mosquitto setup

This example uses the internal ToyBroker to allow being run out of the box, but to use actual 
WebSockets from `client.html` a real broker like ![Mosquitto](https://mosquitto.org/) is required
(`client.pl` works fine with ToyBroker though).

To run this example on a fresh install of Mosquitto set `use_toybroker` to false in config file
`pool.config.json`. Then follow the instructions below to quickly setup a Mosquitto instance capable 
of running Beekeper applications with a minimal security. 

Please note that the entire idea is to have the backend and frontend buses serviced by different broker 
instances, running on isolated servers. This setup uses a single broker instance for simplicity, and works 
just because topics do not clash (see ![Brokers.md](../../doc/Brokers.md) for a proper configuration).

Create `/etc/mosquitto/conf.d/beekeeper.conf`
```
per_listener_settings true

# Backend
listener 1883 0.0.0.0
protocol mqtt
max_qos 1
persistence false
retain_available false
persistent_client_expiration 1h
max_queued_messages 10000
allow_anonymous false
acl_file /etc/mosquitto/conf.d/beekeeper.backend.acl
password_file /etc/mosquitto/conf.d/beekeeper.users

# Frontend tcp
listener 8001 0.0.0.0
protocol mqtt
max_qos 1
persistence false
retain_available false
persistent_client_expiration 1h
max_queued_messages 100
allow_anonymous false
acl_file /etc/mosquitto/conf.d/beekeeper.frontend.acl
password_file /etc/mosquitto/conf.d/beekeeper.users

# Frontend WebSocket
listener 8000 0.0.0.0
protocol websockets
max_qos 1
persistence false
retain_available false
persistent_client_expiration 1h
max_queued_messages 100
allow_anonymous false
acl_file /etc/mosquitto/conf.d/beekeeper.frontend.acl
password_file /etc/mosquitto/conf.d/beekeeper.users

```
Create `/etc/mosquitto/conf.d/beekeeper.backend.acl`
```
pattern  read   priv/%c

user backend

topic   readwrite   msg/#
topic   readwrite   req/#
topic   readwrite   res/#
topic   readwrite   log/#
topic   write       priv/#
```
Create `/etc/mosquitto/conf.d/beekeeper.frontend.acl`
```
pattern  read   priv/%c

user frontend

topic   read    msg/#
topic   write   req/#

user router

topic   write   msg/#
topic   read    req/#
topic   write   priv/#
```
Create broker users running the following commands:
```
mosquitto_passwd -c -b /etc/mosquitto/conf.d/beekeeper.users  frontend  abc123
mosquitto_passwd    -b /etc/mosquitto/conf.d/beekeeper.users  backend   def456
mosquitto_passwd    -b /etc/mosquitto/conf.d/beekeeper.users  router    ghi789
```
Then the Mosquitto broker instance can be started with:
```
mosquitto -c /etc/mosquitto/conf.d/beekeeper.conf
```
If the broker is running elsewhere than localhost edit `bus.config.json` and `config.js` accordingly.

---

This example requires the MQTT.js library Copyright 2015-2021 MQTT.js contributors 
under MIT License (<https://github.com/mqttjs/MQTT.js>).
