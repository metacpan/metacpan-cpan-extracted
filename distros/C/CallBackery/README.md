CallBackery
===========

[![Build Status](https://travis-ci.org/oetiker/callbackery.svg?branch=master)](https://travis-ci.org/oetiker/callbackery)
[![Coverage Status](https://coveralls.io/repos/oetiker/callbackery/badge.svg?branch=master&service=github)](https://coveralls.io/github/oetiker/callbackery?branch=master)

CallBackery is a perl library for writing CRUD style single page web
applications with a desktopish look and feel.  For many applications, all
you have todo is write a few lines of perl code and all the rest is taken
care of by CallBackery.

To get you started, CallBackery comes with a sample application ... 

Quickstart
----------

Open a terminal and follow these instructions below. We have tested them on
ubuntu 14.04 but they should work on any recent linux system with at least
perl 5.10.1 installed.

First make sure you have gcc, perl curl and automake installed. The following commands
will work on debian and ubuntu. 

```console
sudo apt-get install curl automake perl gcc unzip
```

For redhat try

```console
sudo yum install curl automake perl-core openssl-devel gcc unzip
```

Now setup callbackery and all its requirements. You can set the `PREFIX` to
wherever you want callbackery to be installed.

```console
PREFIX=$HOME/opt/callbackery
export PERL_CPANM_HOME=$PREFIX
export PERL_CPANM_OPT="--local-lib $PREFIX"
export PERL5LIB=$PREFIX/lib/perl5
export PATH=$PREFIX/bin:$PATH
curl -L cpanmin.us \
  | perl - -n --no-lwp https://github.com/oetiker/callbackery/archive/master.tar.gz
```

Finally lets generate the CallBackery sample application.

```console
mkdir -p ~/src
cd ~/src
mojo generate callbackery_app CbDemo
cd cb_demo
```

Et voilà, you are looking at your first CallBackery app. To get the
sample application up and running, follow the instructions in the 
README you find in the `cb_demo` directory.


Enjoy

Tobi Oetiker <tobi@oetiker.ch>
