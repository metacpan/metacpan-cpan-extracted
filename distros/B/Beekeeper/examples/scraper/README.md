## Scraper example

This example demonstrates asynchronous workers and clients. 


To run this example start the worker pool:
```
cd beekeper/examples/scraper
source setup.sh
./run.sh
```
Then use the command line client:
```
./client.pl --async  https://cpan.org  https://google.com/xyz
```
Monitor the worker pool load:
```
bkpr-top
```
Logs can be inspected with `bkpr-log` or with:
```
tail /var/log/myapp-pool.log
tail /var/log/myapp-service-scraper.log
```
Finally stop the worker pool with:
```
./run.sh stop
```

Sample output:

```
./client.pl --async  https://cpan.org  https://google.com/xyz

https://google.com/xyz
404 Not Found

https://cpan.org
"The Comprehensive Perl Archive Network - www.cpan.org"
```

## Dependencies

This example requires `AnyEvent::HTTP`. To install it on a Debian system run:
```
apt install libanyevent-http-perl
```

### Mosquitto setup

This example uses the internal ToyBroker to allow being run out of the box.

To run this example on a fresh install of [Mosquitto](https://mosquitto.org/) set `use_toybroker` 
to false in config file `pool.config.json`. Then follow the instructions below to quickly setup a 
Mosquitto instance capable of running Beekeper applications with minimal security.

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
Create a broker user running the following command:
```
mosquitto_passwd -c -b /etc/mosquitto/backend.users  backend  def456
```
Then the Mosquitto broker instance can be started with:
```
mosquitto -c /etc/mosquitto/examples.conf
```
If the broker is running elsewhere than localhost edit `bus.config.json` accordingly.

> *Detailed Mosquitto install instructions can be found [here](../../doc/Brokers.md)*
