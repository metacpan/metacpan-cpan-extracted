# AnyEvent::Discord

Provides an AnyEvent interface to the Discord bot API.

I didn't think I'd be writing any new Perl modules in the year of 2021, but
sometimes you're extending old code to do something new, and find the existing
tools to not be what you're looking for.

This is an alternative module to AnyEvent::Discord::Client. That module is a
perfectly fine module, but it does a lot of things to make "making a bot"
easier, but doesn't translate well to an existing bot framework. This module
provides an eventing interface common to some of the other AnyEvent interfaces
to chat APIs.

This is still likely unfinished, but opening it up to get some more eyes on it.

## Usage

See [the documentation](doc/AnyEvent-Discord.md).

## Building outside of CPAN

AnyEvent::Discord using Dist::Zilla to manage the build and distribution steps.
Before starting, make sure Dist::Zilla is installed:

```
cpanm Dist::Zilla
```

To build for local development:

```
dzil authordeps --missing | cpanm
dzil listdeps | cpanm
dzil test
```
