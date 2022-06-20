---
title: Getting started
layout: default
---

# Getting started

Let's get started with [App::Easer][].

## Installation

[App::Easer][] is a regular [Perl][] module; here are a few hints for
[Installing Perl Modules][] in case of need.

Anyway, the goal of [App::Easer][] is to be confined into a single
[Perl][] file that can be easily embedded into an application, in case of
need. Think [App::FatPacker][]. For this reason, nothing prevents people
from getting the module's file directly, e.g. the very latest (and
possibly buggy, use at your own risk!) version in GitHub [here][latest].

After making sure the module's file (contents) can be "seen" by your
program, it suffices to `use` it. The suggestion is to import *at least*
the `run` function, although the `d` (*dump on standard error*) function
can come handy for debugging too.

```perl
use App::Easer qw< run d >;
```

Done! We're ready to move on.

## Basic templates

Basic templates to start with can be found in [templates][];


## Introductory tutorials

[Tutorial: a to-do application][] provides a step-by-step guide to build
a simple application, showing most of the common facilities provided by
[App::Easer][].

[Tutorial: splitting onto multiple modules][tut-splitting] grows over
the previous one to show how it is possible to easily split the
application into several modules, to allow for future expansions.


[App::Easer]: https://metacpan.org/pod/App::Easer
[Installing Perl Modules]: https://github.polettix.it/ETOOBUSY/2020/01/04/installing-perl-modules/
[Perl]: https://www.perl.org/
[App::FatPacker]: https://metacpan.org/pod/App::FatPacker
[latest]: https://raw.githubusercontent.com/polettix/App-Easer/main/lib/App/Easer.pm
[download]: templates/getting-started.pl
[Tutorial: a to-do application]: {{ '/docs/10-tutorial-base.html' | relative_url }}
[templates]: {{ '/templates' | relative_url }}
[tut-splitting]: {{ '/docs/15-tutorial-splitting.html' | relative_url }}
