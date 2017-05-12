[![](https://travis-ci.org/dod38fr/config-model-systemd.svg?branch=master)](https://travis-ci.org/dod38fr/config-model-systemd)


# config-model-systemd

check and edit systemd configuration files

## Description

This project provides a configuration editor for the 
configuration file of Systemd, i.e. all files in `~/.config/systemd/user/` or
all files in `/etc/systemd/system/`

## Usage

### invoke editor

The following command loads **user** systemd files and launch a graphical
editor:

    cme edit systemd-user

Likewise, the following command loads **system** systemd configuration
files and launch a graphical editor:

    sudo cme edit systemd

### Just check systemd configuration

You can also use cme to run sanity checks on the configuration file:

    cme check systemd-user
    cme check systemd

### More detailed usage

See [Managing Systemd configuration with cme](https://github.com/dod38fr/config-model/wiki/Managing-systemd-configuration-with-cme)
wiki page.

## Versioning scheme

This module is versioned with 3 fields:

* major number
* supported Systemd version
* minor version for the usual changes. This number is reset to one each time a new version of Systemd is supported.

For instance: version `0.231.1` is the first release that supports Systemd version 231

## Installation

### Debian, Ubuntu

Run:

    apt install cme libconfig-model-systemd-perl

### Others

You can also install this project from CPAN:

    cpanm install App::Cme
    cpanm install Config::Model::Systemd

### From GitHub

You may also follow these [instructions](README-build-from-git.md) to install and build from git.

## Problems ?

Please report any issue on https://github.com/dod38fr/config-model-systemd/issues

## Re-generate systemd model files

The files in `lib/Config/Model/models/Systemd/Section` and
`lib/Config/Model/models/Systemd/Common` are generated from Systemd
documentation in xml format.

To regenerate the model files, you must retrieve systemd sources. For instance, you
can retrieve Debian source package:

    apt-get source systemd

Then, from `config-model-systemd` directory, run:

    perl contrib/parse-man.pl -from <path to systemd source>

## More information

* [Managing Systemd configuration with cme](https://github.com/dod38fr/config-model/wiki/Managing-systemd-configuration-with-cme)
* [Using cme](https://github.com/dod38fr/config-model/wiki/Using-cme)
