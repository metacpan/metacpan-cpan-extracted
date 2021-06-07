## Flood example

This example allows to estimate the performance of a Beekeper setup, which depends 
mostly of the performance of the message broker and the network latency. 


To run this example start a worker pool of `TestWorker` processes:
```
cd beekeper/examples/flood
source setup.sh
./run.sh
```
Then flood the worker pool with requests:
```
./flood.pl -b
```
Monitor the worker pool load:
```
bkpr-top
```
Finally stop the worker pool with:
```
./run.sh stop
```

Sample output running on a local Mosquitto 2.0.10:

```
# flood -b

1000 notifications   of   0 Kb  in  0.062 sec   16034 /sec   0.06 ms each
1000 notifications   of   1 Kb  in  0.075 sec   13308 /sec   0.08 ms each
1000 notifications   of   5 Kb  in  0.090 sec   11152 /sec   0.09 ms each
1000 notifications   of  10 Kb  in  0.095 sec   10545 /sec   0.09 ms each

1000 sync calls      of   0 Kb  in 11.413 sec      88 /sec  11.41 ms each  <- !!
1000 sync calls      of   1 Kb  in 11.151 sec      90 /sec  11.15 ms each
1000 sync calls      of   5 Kb  in  2.677 sec     374 /sec   2.68 ms each
1000 sync calls      of  10 Kb  in  2.675 sec     374 /sec   2.67 ms each

1000 async calls     of   0 Kb  in  0.254 sec    3930 /sec   0.25 ms each
1000 async calls     of   1 Kb  in  0.263 sec    3806 /sec   0.26 ms each
1000 async calls     of   5 Kb  in  0.263 sec    3807 /sec   0.26 ms each
1000 async calls     of  10 Kb  in  0.278 sec    3594 /sec   0.28 ms each

1000 fire & forget   of   0 Kb  in  0.098 sec   10185 /sec   0.10 ms each
1000 fire & forget   of   1 Kb  in  0.105 sec    9557 /sec   0.10 ms each
1000 fire & forget   of   5 Kb  in  0.122 sec    8223 /sec   0.12 ms each
1000 fire & forget   of  10 Kb  in  0.139 sec    7182 /sec   0.14 ms each
```
Sample output running on a local HiveMQ 2021.1:

```
# flood -b

1000 notifications   of   0 Kb  in  0.065 sec   15441 /sec   0.06 ms each
1000 notifications   of   1 Kb  in  0.077 sec   13065 /sec   0.08 ms each
1000 notifications   of   5 Kb  in  0.086 sec   11680 /sec   0.09 ms each
1000 notifications   of  10 Kb  in  0.095 sec   10543 /sec   0.09 ms each

1000 sync calls      of   0 Kb  in  3.020 sec     331 /sec   3.02 ms each
1000 sync calls      of   1 Kb  in  3.139 sec     319 /sec   3.14 ms each
1000 sync calls      of   5 Kb  in  3.311 sec     302 /sec   3.31 ms each
1000 sync calls      of  10 Kb  in  3.511 sec     285 /sec   3.51 ms each

1000 async calls     of   0 Kb  in  0.610 sec    1640 /sec   0.61 ms each  <- !!
1000 async calls     of   1 Kb  in  0.554 sec    1806 /sec   0.55 ms each
1000 async calls     of   5 Kb  in  0.558 sec    1793 /sec   0.56 ms each
1000 async calls     of  10 Kb  in  0.685 sec    1460 /sec   0.69 ms each

1000 fire & forget   of   0 Kb  in  0.090 sec   11147 /sec   0.09 ms each
1000 fire & forget   of   1 Kb  in  0.095 sec   10563 /sec   0.09 ms each
1000 fire & forget   of   5 Kb  in  0.107 sec    9325 /sec   0.11 ms each
1000 fire & forget   of  10 Kb  in  0.127 sec    7892 /sec   0.13 ms each
```
Sample output running a ToyBroker:

```
# flood -b

1000 notifications   of   0 Kb  in  0.049 sec   20242 /sec   0.05 ms each
1000 notifications   of   1 Kb  in  0.064 sec   15735 /sec   0.06 ms each
1000 notifications   of   5 Kb  in  0.073 sec   13750 /sec   0.07 ms each
1000 notifications   of  10 Kb  in  0.082 sec   12160 /sec   0.08 ms each

1000 sync calls      of   0 Kb  in  2.645 sec     378 /sec   2.64 ms each
1000 sync calls      of   1 Kb  in  2.735 sec     366 /sec   2.73 ms each
1000 sync calls      of   5 Kb  in  2.783 sec     359 /sec   2.78 ms each
1000 sync calls      of  10 Kb  in  2.952 sec     339 /sec   2.95 ms each

1000 async calls     of   0 Kb  in  0.335 sec    2982 /sec   0.34 ms each
1000 async calls     of   1 Kb  in  0.365 sec    2738 /sec   0.37 ms each
1000 async calls     of   5 Kb  in  0.392 sec    2548 /sec   0.39 ms each
1000 async calls     of  10 Kb  in  0.427 sec    2343 /sec   0.43 ms each

1000 fire & forget   of   0 Kb  in  0.078 sec   12889 /sec   0.08 ms each
1000 fire & forget   of   1 Kb  in  0.088 sec   11306 /sec   0.09 ms each
1000 fire & forget   of   5 Kb  in  0.102 sec    9798 /sec   0.10 ms each
1000 fire & forget   of  10 Kb  in  0.116 sec    8654 /sec   0.12 ms each
```
---

### Mosquitto setup

This example uses the internal ToyBroker to allow being run out of the box.

To run this example on a fresh install of ![Mosquitto](https://mosquitto.org/) set `use_toybroker` 
to false in config file `pool.config.json`. Then follow the instructions below to quickly setup a 
Mosquitto instance capable of running Beekeper applications with a minimal security.

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
Create a broker user running the following command:
```
mosquitto_passwd -c -b /etc/mosquitto/conf.d/beekeeper.users  backend   def456
```
Then the Mosquitto broker instance can be started with:
```
mosquitto -c /etc/mosquitto/conf.d/beekeeper.conf
```
If the broker is running elsewhere than localhost edit `bus.config.json` accordingly.
