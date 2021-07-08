## Flood example

This example allows to estimate the performance of a Beekeper setup, which depends 
heavily on the performance of the message broker and the network latency. 


To run this example start the worker pool:
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
Logs can be inspected with `bkpr-log` or with:
```
tail /var/log/myapp-pool.log
tail /var/log/myapp-service-flood.log
```
Finally stop the worker pool with:
```
./run.sh stop
```

Sample output running on a local Mosquitto 2.0.10:

```
# flood -b

1000 notifications   of   0 Kb  in  0.062 sec   16196 /sec   0.06 ms each
1000 notifications   of   1 Kb  in  0.075 sec   13308 /sec   0.08 ms each
1000 notifications   of   5 Kb  in  0.086 sec   11676 /sec   0.09 ms each
1000 notifications   of  10 Kb  in  0.094 sec   10623 /sec   0.09 ms each

1000 sync calls      of   0 Kb  in  0.651 sec    1536 /sec   0.65 ms each
1000 sync calls      of   1 Kb  in  0.695 sec    1440 /sec   0.69 ms each
1000 sync calls      of   5 Kb  in  0.799 sec    1251 /sec   0.80 ms each
1000 sync calls      of  10 Kb  in  0.982 sec    1019 /sec   0.98 ms each

1000 async calls     of   0 Kb  in  0.117 sec    8543 /sec   0.12 ms each
1000 async calls     of   1 Kb  in  0.126 sec    7915 /sec   0.13 ms each
1000 async calls     of   5 Kb  in  0.139 sec    7175 /sec   0.14 ms each
1000 async calls     of  10 Kb  in  0.162 sec    6177 /sec   0.16 ms each

1000 fire & forget   of   0 Kb  in  0.091 sec   11031 /sec   0.09 ms each
1000 fire & forget   of   1 Kb  in  0.102 sec    9840 /sec   0.10 ms each
1000 async calls     of   0 Kb  in  0.118 sec    8499 /sec   0.12 ms each
1000 async calls     of   1 Kb  in  0.126 sec    7915 /sec   0.13 ms each
```
Sample output running on a local HiveMQ 2021.1:

```
# flood -b

1000 notifications   of   0 Kb  in  0.065 sec   15441 /sec   0.06 ms each
1000 notifications   of   1 Kb  in  0.077 sec   13065 /sec   0.08 ms each
1000 notifications   of   5 Kb  in  0.086 sec   11680 /sec   0.09 ms each
1000 notifications   of  10 Kb  in  0.095 sec   10543 /sec   0.09 ms each

1000 sync calls      of   0 Kb  in  3.020 sec     331 /sec   3.02 ms each  <- !!
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

1000 sync calls      of   0 Kb  in  1.042 sec     960 /sec   1.04 ms each
1000 sync calls      of   1 Kb  in  1.063 sec     941 /sec   1.06 ms each
1000 sync calls      of   5 Kb  in  1.163 sec     860 /sec   1.16 ms each
1000 sync calls      of  10 Kb  in  1.233 sec     811 /sec   1.23 ms each

1000 async calls     of   0 Kb  in  0.100 sec    9982 /sec   0.10 ms each
1000 async calls     of   1 Kb  in  0.105 sec    9522 /sec   0.11 ms each
1000 async calls     of   5 Kb  in  0.116 sec    8604 /sec   0.12 ms each
1000 async calls     of  10 Kb  in  0.130 sec    7720 /sec   0.13 ms each

1000 fire & forget   of   0 Kb  in  0.074 sec   13473 /sec   0.07 ms each
1000 fire & forget   of   1 Kb  in  0.080 sec   12466 /sec   0.08 ms each
1000 fire & forget   of   5 Kb  in  0.101 sec    9890 /sec   0.10 ms each
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
set_tcp_nodelay true

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
