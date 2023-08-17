## Chat example

> *Try a [live demo](https://beekeeper.net.ar/examples/chat.html) of this example*

This example implements a real world setup with isolated buses and redundancy:

![](../../doc/images/chat.svg)


## Running this example

To run this example start all worker pools:
```
cd beekeper/examples/chat
source setup.sh
./run.sh
```
Then open `chat.html` in a browser (the JSON-RPC traffic will be dumped on browser console). 

Or use the command line client:
```
./chat.pl
```
The system can be stressed generating traffic with:
```
./flood.pl -c 50 -r 500
```
Monitor the worker pool load:
```
bkpr-top
```
Logs can be inspected with `bkpr-log` or with:
```
tail /var/log/myapp-pool.log
tail /var/log/myapp-service-auth.log
tail /var/log/myapp-service-chat.log
tail /var/log/beekeeper-service-router.log
```
Finally stop worker pools with:
```
./run.sh stop
```
This is `bkpr-top` showing this example running:

![](../../doc/images/bkpr-top.png)

---

### Mosquitto setup

This example uses the internal ToyBroker to allow being run out of the box, but to use actual 
WebSockets from `chat.html` a real broker like [Mosquitto](https://mosquitto.org/) is required
(`chat.pl` works fine with ToyBroker though).

To run this example on a fresh install of Mosquitto set `use_toybroker` to false in config file
`pool.config.json`. Then follow the instructions below to quickly setup a Mosquitto instance 
capable of running Beekeper applications with minimal security. 

Please note that the entire idea is to have the backend and frontend buses serviced by different
broker instances, running on isolated servers. This setup uses a single broker instance for 
simplicity, and works  just because topics do not clash (see [Brokers.md](../../doc/Brokers.md) 
for a proper configuration).

Create `/etc/mosquitto/examples.conf`
```
per_listener_settings   true
max_queued_messages     10000
set_tcp_nodelay         true

## Backend

listener            1883  127.0.0.1
protocol            mqtt
max_qos             1
persistence         false
retain_available    false
allow_anonymous     false
acl_file            /etc/mosquitto/backend.acl
password_file       /etc/mosquitto/backend.users

## Frontend

listener            11883  0.0.0.0
protocol            mqtt
max_qos             1
persistence         false
retain_available    false
allow_anonymous     false
acl_file            /etc/mosquitto/frontend.acl
password_file       /etc/mosquitto/frontend.users

## Frontend WebSocket

listener            18080  0.0.0.0
protocol            websockets
max_qos             1
persistence         false
retain_available    false
allow_anonymous     false
acl_file            /etc/mosquitto/frontend.acl
password_file       /etc/mosquitto/frontend.users
```
Create `/etc/mosquitto/backend.acl`
```
pattern  read   priv/%c/#

user backend

topic   readwrite   msg/#
topic   readwrite   req/#
topic   readwrite   res/#
topic   readwrite   log/#
topic   write       priv/#
```
Create `/etc/mosquitto/frontend.acl`
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
mosquitto_passwd -c -b /etc/mosquitto/backend.users   backend   def456
mosquitto_passwd -c -b /etc/mosquitto/frontend.users  frontend  abc123
mosquitto_passwd    -b /etc/mosquitto/frontend.users  router    ghi789
```
Then the Mosquitto broker instance can be started with:
```
mosquitto -c /etc/mosquitto/examples.conf
```
If the broker is running elsewhere than localhost edit `bus.config.json` and `config.js` accordingly.

> *Detailed Mosquitto install instructions can be found [here](../../doc/Brokers.md)*

---

### Acknowledgements

This software uses the following libraries:

- MQTT.js - https://github.com/mqttjs/MQTT.js  
  Released under the terms of the MIT license

- pako - https://github.com/nodeca/pako  
  Released under the terms of the MIT license
