eventstreamr [![Build Status](https://api.travis-ci.org/plugorgau/eventstreamr-station.svg?branch=master)](https://travis-ci.org/plugorgau/eventstreamr) [![Coverage Status](https://coveralls.io/repos/plugorgau/eventstreamr-station/badge.svg?branch=master)](https://coveralls.io/r/plugorgau/eventstreamr-station?branch=master)
============

Single and multi room audio visual stream management.

Installation
============
Your best bet is to install using cpanm + local::lib. This will 
install everything under your user directory and will avoid polluting
your system perl libraries. It's also how PLUG + LCA use it.

Grab cpanm + local::lib
```bash
$ sudo apt-get install cpanminus liblocal-lib-perl
```

Configure local::lib if you haven't already done so:

```bash
$ perl -Mlocal::lib >> ~/.bashrc
$ eval $(perl -Mlocal::lib)
```

Install from CPAN

```bash
cpanm App::EventStreamr
```

Configuration
=============
You can run through the host configuration wizard with '--configure'.

```bash
$ eventstreamr --configure
Welcome to the EventStreamr config utility

It will clear the current config, is this ok? y/n [n]: y
Room - For record path and controller [test_room]: 
backend - DVswitch|GSTswitch [DVswitch]: 
Mixer - Video mixer interface y/n [y]: y
host - switching host [127.0.0.1]: 
port - switching port [1234]: 
$room + $date can be used as variables in the path and
will correctly be set and created at run time
recordpath -  [/tmp/$room/$date]: 
Ingest - audio/video ingest y/n [y]: 
Enable 'Oculus VR Inc. Camera DK2' for ingest [y]: n
Enable 'Chicony Electronics Co.  Ltd. ASUS USB2.0 Webcam' for ingest [y]: 
Enable 'C-Media Electronics, Inc. ' for ingest [y]: 

Config written successfully
```

Command Line
============
You can list out the devices available using '--devices'

```bash
$ eventstreamr --devices
ID (Type) - Name
video0 (V4L) - Oculus VR Inc. Camera DK2
video1 (V4L) - Chicony Electronics Co.  Ltd. ASUS USB2.0 Webcam
0d8c:0008 (ALSA) - C-Media Electronics, Inc. 
```

Concepts
========

A station can have one or more roles. Only one controller can manage stations.

Roles
=====
* controller - Web based frontend for managing stations
* ingest - alsa/dv/v4l capture for sending to mixer
* mixer - DVswitch/streaming live mixed video. With the intention for this to be easily replaced by gstswitch
* stream - stream mixed video
* record - stream mixed video
* sync - rsync files to a central server (requires keyless ssh to be configured)

Directories
===========
* baseimage - docs, notes, and tools for the base (OS) image
* station - station management scripts
* controller - controller stack


Station Script Requirements
===========================

See package.deps for list of packages required

Known Issues
============
A list of known issues that cause minor problems, but have 
workarounds.

[Daemon dies when alsa device isn't present on start](https://github.com/plugorgau/eventstreamr-station/issues/54)
  - Ensure all configured ALSA devices are plugged in on boot

[Correctly Restart on Date Change](https://github.com/plugorgau/eventstreamr-station/issues/18)
  - Reboot or Restart the EventStreamr Daemon (pressing update from the controller will restart it)



