# CONTRIBUTING

This project is free software for the express purpose of collaboration.
We welcome all input, bug reports, feature requests, general comments,
and patches.

## Communication

If you're not sure about anything, please [open an issue on Github
issues](http://github.com/cpan-testers/cpantesters-api/issues) and ask, or ask
the [CPAN Testers Discuss mailing
list](http://lists.perl.org/list/cpan-testers-discuss.html), or
e-mail the project leader <preaction@cpan.org> or [talk to us on IRC on
irc.perl.org channel #cpantesters-discuss](https://chat.mibbit.com/?channel=%23cpantesters-discuss&server=irc.perl.org)!

## Standard of Conduct

To ensure a welcoming, safe, collaborative environment, this project
will enforce a standard of conduct:

* The topic of this project is the project itself. Please stay on-topic.
* Stick to the facts
* Avoid demeaning remarks and sarcasm

Unacceptable behavior will receive a single, public warning. Repeated
unacceptable behavior will result in removal from the project.

Remember, all the people who contribute to this project are volunteers.

## About this Project

The [CPAN Testers project](http://cpantesters.org) is an effort to
ensure the stability and reliability of Perl and CPAN by running the
test suites of uploaded CPAN distributions on various Perl versions,
OSes, and hardware; collecting the results in a database; and alerting
distribution authors when there is a test failure.

### Project Goals

The CPAN Testers API is a JSON API on to the data stored in the CPAN
Testers database. The goal of this subproject is to be an
easily-consumable API so that users can build their own tools around
CPAN Testers data. This subproject is also a communication hub for the
disparate parts of the CPAN Testers data pipeline, and allows users to
tap into that communication to receive immediate data updates.

### Repository Layout

This project follows CPAN conventions with some additions, explained
below.

#### `lib/`

Modules are located in the `lib/` directory. Most of the functionality
of the project should be in a module. If the functionality should be
available to users from a script, the script should call the module.

##### `lib/CPAN/Testers/API.pm`

This is the main application class. This project uses [the Mojolicious
web framework](http://mojolicious.org). The main startup routines are
located in this file: reading the API spec (see below), locating the
template directory (see below), and setting up additional routes and
helpers.

##### `lib/CPAN/Testers/API/Controller/`

This is where API controllers are kept. Each controller handles
a section of the API, and API routes are linked from the API
specification in `share/api.json` (see below) to a controller name and
method using the `x-mojo-to` key in the API spec.

#### `bin/`

Command-line scripts go in the `bin/` directory. Most of the real
functionality of these should be in a library, but these scripts must
call the library function and document the command-line interface.

#### `t/`

All the tests are located in the `t/` directory. See "Getting Started"
below for how to build the project and run its tests.

#### `xt/`

Any extra tests that are not to be bundled with the CPAN module and run
by consumers is located here. These tests are run at release time and
may test things that are expensive or esoteric.

#### `share/`

Any files that are not runnable code but must still be available to the
code are stored in `share/`. This includes default config files, default
content, informational files, read-only databases, and other such. This
project uses [File::Share](http://metacpan.com/pod/File::Share) to
locate these files at run-time.

##### `share/api.json`

This is the [OpenAPI specification](http://openapis.org) for the CPAN
Testers API. This JSON document documents each API endpoint, the input
it can receive, the output it will send, and any error conditions that
might occur. This API documentation is then displayed [using
SwaggerUI](http://swagger.io/swagger-ui) (via
[Alien::SwaggerUI](http://metacpan.org/pod/Alien::SwaggerUI)) at
<http://api.cpantesters.org>.

Every new API endpoint must be started and documented here. This
document is used by
[Mojolicious::Plugin::OpenAPI](http://metacpan.org/pod/Mojolicious::Plugin::OpenAPI)
to generate the Mojolicious routes and validate the input and output
automatically. Each route should have an `x-mojo-to` key to link it to
a `controller` (class) and `action` (method).

##### `share/templates`

This is where Mojolicious templates should go. The templates are located
after install using [File::Share](http://metacpan.org/pod/File::Share).

##### `share/public`

This is where extra, ancillary files should go (like CSS, JavaScript,
and images). These files are located after install using
[File::Share](http://metacpan.org/pod/File::Share).

#### `Rexfile`

This file contains all the [Rex](http://rexify.org) tasks to deploy this
project to CPAN Testers servers (or development VMs). This `Rexfile`
coordinates with [the CPAN Testers deploy
project](http://github.com/cpan-testers/cpantesters-deploy) (which
prepares a machine for a specific role) to allow deploying the
application with minimal privileges.

#### `etc/`

This directory contains additional things that aren't examples (which
would go in `eg/`), but also must not be part of the CPAN distribution
(which would go in `share/`).

##### `etc/runit/`

These are [runit](smarden.org/runit/) service files used by CPAN Testers
to run the API daemon and the [Mercury](http://preaction.me/mercury)
daemon (a websocket message broker).

## What to Contribute

### Comments

The issue tracker is used for both bug reports and to-do list. Anything
on the issue tracker, open or closed, is available for discussion.

### Fixes

For fixes, simply fork and send a pull request. Fixes to anything,
documentation, code, tests, are equally welcome, appreciated, and
addressed!

If you are fixing a bug in the code, please add a regression test to
ensure it stays fixed in the future.

### Features

All contributions are welcome if they fit the scope of this project. If
you're not sure if your feature fits, open an issue and ask. If it doesn't
fit, we will try to find a way to enable you to add your feature in a
related project (if it means changes in this project).

When contributing a feature, please add some basic functionality tests
to ensure the feature is working properly. These tests do not need to be
comprehensive or paranoid, but must at least demonstrate that the
feature is working as documented.

## Getting Started Building and Running Tests

This project uses Dist::Zilla for its releases, but you aren't required
to use it for contributing.

These instructions do require you have
[App::cpanminus (cpanm)](https://metacpan.org/pod/App::cpanminus) installed.
`cpanm` is a CPAN client to install Perl modules and programs. You can
install `cpanm` by doing:

```
curl -L https://cpanmin.us | perl - App::cpanminus
```

Or, if you (not incorrectly) do not trust that, by using the existing
`cpan` client that comes with Perl:

```
cpan App::cpanminus
```

You may need to be root or Administrator to install cpanminus.

This project also requires Perl version 5.24. If your Perl is not recent
enough, you can install a new version of Perl in a local directory by
using [perlbrew](http://perlbrew.pl) (the easiest option) or
[plenv](https://github.com/tokuhirom/plenv).

### Using `cpanm` to install prereqs

The [`cpanm`](https://metacpan.org/pod/App::cpanminus) command is the
easiest way to install this project's dependencies. In the root of the
project, just run `cpanm --installdeps .` and the dependencies will be
installed.

### Using `carton` to install prereqs in an isolated directory

If you with to isolate the prerequisites of this project so they do not
interfere with other projects, you can use the
[Carton](http://metacpan.org/pod/Carton) tool. Install Carton normally
from CPAN using `cpanm Carton`, then use the `carton` command to install
this module's prereqs in the `local/` directory:

```
carton install
```

Once the prereqs are installed, you can use `carton exec prove -lr t`
to run all the tests with the right prereqs. Putting `carton exec` in
front of the command makes sure Perl uses the right library
directories.

### Using `prove` to run tests

Perl comes with a utility called `prove` which runs tests and gives
a report on failures. To run the test suite with `prove`, do:

```
prove -lr t
```

This will run all the tests in the `t` directory, recursively, while
adding the current `lib/` directory to the library path.

You can run individual test files more quickly by passing them as
arguments to prove:

```
prove -l t/my-test.t
```

### Using Dist::Zilla to install prereqs and run tests

Once you have installed Dist::Zilla via `cpanm Dist::Zilla`, you can get
this distributions's dependencies by doing:

```
dzil listdeps --author --missing | cpanm
```

Once all that is done, testing is as easy as:

```
dzil test
```

## Before you Submit Your Contribution

### Copyright and License

All contributions are copyright their respective owners, so make sure you
agree with the project license (found in the LICENSE file) before
contributing.

The list of Contributors is calculated automatically from the Git commit
log. If you do not wish to be listed as a contributor, or if you wish to
be listed as a contributor with a different e-mail address, tell me so
in the ticket or e-mail me at doug@preaction.me.

### Code Formatting and Style

Please try to maintain the existing code formatting and style.

* 4-space indents
* Opening brace on the same line as the opening keyword
    * Exceptions made for lengthy conditionals
* Closing brace on the same column as the opening keyword

### Documentation

Documentation is incredibly important, and contributions will not be
accepted until documentated.

* Methods must be documented inline, above the code of the method
* Method documentation must include name, sample usage, and description
  of inputs and outputs
* Attributes must be documented inline, above the attribute declaration
* Attribute documentation must include name, sample value, and
  description
* User-executable scripts must be documented with a short synopsis,
  a longer description, and all the arguments and options explained
* Tests must be documented with the purpose of the test and any useful
  information for understanding the test.

### New Prerequisites

Though this project has a `cpanfile`, a `Makefile.PL`, and maybe even
a `Build.PL`, these files are auto-generated and should not be edited.
To add new prereqs, you must add them to the `dist.ini` file in the
following sections:

* `[Prereqs]` - Runtime requirements
* `[Prereqs / TestRequires]` - Test-only requirements
* `[Prereqs / Recommends]` - Runtime recommendations, for optional
  modules
* `[Prereqs / TestRecomments]` - Test-only recommendations, for optional
  modules

If the section doesn't already exist, you can add it to the bottom of
the `dist.ini` file.

The `Recommends` and `TestRecommends` will be automatically installed by
Travis CI to test those parts of the code.

OS-specific prerequisites can be added using the
[Dist::Zilla::Plugin::OSPrereqs](http://metacpan.org/pod/Dist::Zilla::Plugin::OSPrereqs)
module.

