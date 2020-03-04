CallBackery
===========

![Unit Tests](https://github.com/oetiker/callbackery/workflows/Unit%20Tests/badge.svg?branch=master)
[![Coverage Status](https://coveralls.io/repos/oetiker/callbackery/badge.svg?branch=master&service=github)](https://coveralls.io/github/oetiker/callbackery?branch=master)

CallBackery is a perl library for writing CRUD style single page web
applications with a desktopish look and feel.  For many applications, all
you have todo is write a few lines of perl code and all the rest is taken
care of by CallBackery.

To get you started, have a look at the CallBackery sample application. It is contained
in the Mojolicious::Command::Author::generate::automake_app package.

Quickstart
----------

Follow the instructions in <https://github.com/oposs/mojolicious-automake>

Finally lets generate the CallBackery sample application.

```console
mkdir -p ~/src
cd ~/src
mojo generate callbackery_app CbDemo
cd cb-demo
```

Et voilà, you are looking at your first CallBackery app. To get the
sample application up and running, follow the instructions in the
README you find in the `cb_demo` directory.

Developing / Contributing
-------------------------

- Fork this repo (Using the github UI: https://github.com/oetiker/callbackery -> "Fork" in the top-right corner)
- Clone your repo (In your fork, push "Clone or Download" and use the URL there for you `git clone` command)
- Make a branch (You will PR that branch, later)

Generate the demo app from your checkout
```console
cd ~/checkouts/callbackery
perl Makefile.pl
cd
mkdir -p src
cd src
perl -I../thirdparty/lib/perl5 -Ilib ~/checkouts/callbackery/thirdparty/bin/mojo generate callbackery_app CbDemo
```
Now, proceed with the README in `~/src/cb-demo`

To create a PR, commit your changes, push them to your github repo, and use the github UI to create the PR to `https://github.com/oetiker/callbackery`.
Chances for a merge are improved if you explain in some detail what your changes are and what they achieve.


Enjoy

Tobi Oetiker <tobi@oetiker.ch>
