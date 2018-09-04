[![](https://travis-ci.org/dod38fr/config-model-tk-ui.svg?branch=master)](https://travis-ci.org/dod38fr/config-model-tk-ui)

## Tk GUI to edit config data through Config::Model ##

This module provides a Perl/Tk interface to:
* the configuration editor provided by [Config::Model](https://github.com/dod38fr/config-model). (i.e. [cme](https://github.com/dod38fr/config-model/wiki/Using-cme) )
* the configuration model editor provided by [Config::Model::Itself](https://github.com/dod38fr/config-model-itself) (i.e `cme meta edit`. For instance, see [How to add a new parameter to an existing model](https://github.com/dod38fr/config-model/wiki/How-to-add-a-new-parameter-to-an-existing-model))

For instance, with this module, the configuration editor provided by [Config::Model](https://github.com/dod38fr/config-model). ( [cme](https://github.com/dod38fr/config-model/wiki/Using-cme) ) and
[Config::Model::OpenSsh](https://github.com/dod38fr/config-model-openssh), you get a
[graphical configuration editor for sshd_config](https://github.com/dod38fr/config-model/wiki/Managing-ssh-configuration-with-cme).


## FEEDBACK and HELP wanted

To fit user needs, this project needs feedback from its users. Please
send your feedbacks, comments and ideas to the author, or
[create a bug report](https://github.com/dod38fr/config-model-tk-ui/issues).

This projects also needs help to improve its user interfaces:
* Look and feel of Perl/Tk interface can be improved
* A nice logo (a penguin with a wrench maybe ) would be welcomed
* Config::Model could use a web interface
* May be also an interface based on Gtk for a better look

## Installation

On debian/ubuntu:

    apt install cme libconfig-model-tkui-perl

Otherwise:

    cpanm App::Cme
    cpanm Config::Model::TkUI

## Build from git

See [build from git instructions](README.build-from-git).
