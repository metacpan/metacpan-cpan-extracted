# OpenHAP

**HomeKit Accessory Protocol for OpenBSD**

OpenHAP connects MQTT-connected Tasmota devices to Apple HomeKit. You can
control the devices with the iOS Home app.

Website and manuals: <https://www.openhap.org/>

## Features

- OpenHAP pairs with the iOS Home app through HAP and encrypts the session
- You declare Tasmota thermostats, heaters, switches, sensors, lightbulbs, and
  dimmers in `openhapd.conf(5)`
- OpenHAP uses MQTT to control the devices and to read their state
- The daemon runs as the `_openhap` user from `rc.d`, under pledge(2) and
  unveil(2)

## Quick Start

```sh
make deps
doas make install
doas cp /etc/examples/openhapd.conf /etc/openhapd.conf
doas vi /etc/openhapd.conf
doas rcctl enable mosquitto mdnsd openhapd
doas rcctl start mosquitto mdnsd openhapd
```

See [INSTALL.md](INSTALL.md) for the complete installation instructions.

## Documentation

- `openhapd(8)` - the daemon and its command-line options
- `openhapd.conf(5)` - the configuration file format
- `hapctl(8)` - the control utility

## Development

See [CLAUDE.md](CLAUDE.md) for the development commands, the coding style, and
the conventions.

## Architecture

```
iOS Home App
     │
     │ TCP/TLS (HAP)
     ▼
┌─────────────┐     ┌───────────┐     ┌─────────────┐
│  openhapd   │◄───►│ mosquitto │◄───►│   Tasmota   │
│  :51827     │     │  :1883    │     │   Devices   │
└─────────────┘     └───────────┘     └─────────────┘
```

## The protocol libraries

The HAP protocol itself lives in `Protocol::HAP`, under `lib/Protocol/`. The
library is host-neutral: it uses core Perl plus four declared crypto modules,
and it knows nothing about the daemon that hosts it. The engine takes its
timers, its writes, and its persistence as injected contracts, so it touches no
socket, no timer, and no file of its own. Two classes beside the engine do the
work that the contracts describe: a blocking client and a file store. `openhapd`
is the reference host.

The OpenBSD-style daemon plumbing comes from the
[Fugu](https://github.com/FuguBSD/Fugu) distribution, which `make deps` installs
from its latest release.

A CPAN release is planned; see `lib/Protocol/HAP.pod` for the library overview
and the host contracts.

## License

ISC License. See [LICENSE](LICENSE).
