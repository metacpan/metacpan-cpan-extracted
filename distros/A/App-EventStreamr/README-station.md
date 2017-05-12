station control
===============

RESTful Interface
=================

Start an individual device

```
curl -X POST -H "Content-Type: application/json" -d '{"id":"2"}' http://localhost:3000/command/start
```

Stoping an individual device

```
curl -X POST -H "Content-Type: application/json" -d '{"id":"2"}' http://localhost:3000/command/stop
```

station.json
============

Config file can appear as below and take fixed array of devices:

```json
{ 
  "roles" : [{"role":"ingest"}],
  "nickname" : "",
  "room" : "",
  "mixer" : {"port":"1234", "host":"localhost"},
  "devices" : [ 
                {"type":"dv","id":"0x080046010368430a"},
                {"type":"alsa","id":"4"},
                {"type":"alsa","id":"0"}
              ],
  "run" : "0"
}
```
or set to pickup all attached devices:

```json
{ 
  "roles" : [{"role":"ingest"}],
  "nickname" : "",
  "room" : "",
  "mixer" : {"port":"1234", "host":"localhost"},
  "devices" : "all" 
  "run" : "0"
}
```
