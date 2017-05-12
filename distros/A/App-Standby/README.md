This is the README file for App-Standby, an on-call manager.

## Description

App::Standby provides a handy on-call duty manager. It is
able to handle several groups of on-call personel and provides
an extensible plugin mechanism to connect it to virtually any
remote service which provides some kind of API.

Please also look at Monitoring::Spooler which is an external
notification queue for virtually any monitoring application
which support external notification scripts.

If you are using Zabbix Zabbix::Reporter may be also worth a
look, it's a handy dashboard for Zabbix.

## Installation

This package uses Dist::Zilla.

Use

dzil build

to create a release tarball which can be
unpacked and installed like any other EUMM
distribution.

perl Makefile.PL

make

make test

make install

## Documentation

Please see perldoc App::Standby. Setup and configuration is covered there.

