# Chess-Plisco

Chess::Plisco is a representation of a chess position in Perl.  It also
contains a UCI compatible chess engine.  You can challenge the engine most
of the time at https://lichess.org/@/plisco-bot.

It only works with Perl versions that are compiled with support for 64
bit integers!

Since it is reasonably fast and offers a lot of functionality needed for
chess engines, it can be used for rapid prototyping of a chess engine.
Writing a basic implementation of the AlphaBeta algorithm with `Chess::Plisco`
will not require more than 30 lines of code.

The library also has a very high test coverage so that you can probably use it
as a reference implementation for your own experiments and tests.

- [Chess-Plisco](#chess-plisco)
	- [Installation](#installation)
		- [Windows](#windows)
		- [POSIX Systems (Un\*x, Linux, macos, ...)](#posix-systems-unx-linux-macos-)
			- [Installing a Release](#installing-a-release)
		- [Building/Using from Git Sources](#buildingusing-from-git-sources)
			- [Installing from Git Sources](#installing-from-git-sources)
			- [Using the Cloned Repository Directly](#using-the-cloned-repository-directly)
	- [Library](#library)
	- [Engine](#engine)
		- [Running the Engine](#running-the-engine)
		- [Graphical User Interfaces](#graphical-user-interfaces)
	- [Internals](#internals)
	- [Copryight](#copryight)


## Installation

### Windows

If you are just interested in running the integrated UCI compatible chess
engine, go to the [Releases](https://github.com/gflohr/Chess-Plisco/releases)
section, download the executable image `plisco.exe` and copy it wherever you
like.

If you want to do more with the software, you have to install at least a
Perl interpreter for Windows ([Strawberry Perl](https://strawberryperl.com/)
will usually be the first choice). If you want to hack on the sources, you have
to set up a development environment that is close enough to a Un*x system.
Just read on in this case.

### POSIX Systems (Un*x, Linux, macos, ...)

#### Installing a Release

You will need the program `cpanm`. Try the command `cpanm --version`. If that
does not print an error message but dumps some settings of your Perl
environment, you are all done. Otherwise, see
https://metacpan.org/pod/App::cpanminus for help on installing the program.

Note: The program `cpanm` builds and installs Perl packages. By default, it
runs the test suites that ship with the packages. That can be time consuming,
and sometimes tests fail, that are not really relevant. Therefore, you can
always add the option `--notest` to bypass this step if you need that.

Once you have `cpanm` working, installing the latest release of the library and the engine
is as easy as this:

```shell
cpanm Chess::Plisco
```

You can now use the library (if you are a Perl hacker), or run the engine
with the command `plisco`. The program `plisco` should normally be in your
`$PATH`.

### Building/Using from Git Sources

Clone the repository first.

The usual plethora of building and maybe installing Perl modules goes like
this:

```shell
perl Makefile.PL
make
make install # optional
```

Chances are that this will trigger warnings and errors.

```
Checking if your kit is complete...
Warning: the following files are missing in your kit:
        META.json
        META.yml
        README.pod
        t/release-cpan-changes.t
Please inform the author.
```

That is normal in this case, and it is harmless. This one is not:

```
Warning: prerequisite Some::Other::Module VERSION not found.
```

That means that you are missing a dependency.

#### Installing from Git Sources

If you want to install the software with all dependencies, you can simply
use this:

```shell
cpanm .
```

#### Using the Cloned Repository Directly

If you really want to use the sources from `git` directly, you will still need
the dependencies. You can install them like this:

```shell
cpanm --installdeps .
```

You can now start the engine like this:

```shell
perl -Ilib ./bin/plisco
```

You will notice it takes several seconds for the engine to start up. See
the section [Internals](#Internals) below if you want to know why.

## Library

See the [tutorial](lib/Chess/Plisco/Tutorial.pod) for a gentle introduction
to the library.  When installed, you can also try the command
`perldoc Chess::Plisco::Tutorial`.

Reference documentation is available for:

* [Chess::Plisco](lib/Chess/Plisco.pod) (`perldoc Chess::Plisco`)
* [Chess::Pllisco::Macro](lib/Chess/Plisco/Macro.pod) (`perldoc Chess::Plisco::Macro`).
* [Chess::Plisco::EPD](lib/Chess/Plisco/EPD.pod) (`perldoc Chess::Plisco::EPD`)
* [Chess::Plisco::EPD::Record](lib/Chess/Plisco/EPD/Record.pod) (`perldoc Chess::Plisco::EPD::Record`)
* [Chess::Plisco::Tablebase::Syzygy](lib/Chess/Plisco/Tablebase/Syzygy.pod) (`perldoc Chess::Plisco::Tablebase::Syzygy`).

## Engine

### Running the Engine

The chess engine is started with the command "plisco". You can also run it
from inside the repository like this:

```shell
$ perl -Ilib bin/plisco
```

The engine needs some time to come up because it compiles a number of lookup
tables.  If you run it from a git checkout, it will also need time to parse
its own source code and expand the macros contained.

See the section [Internals](#Internals) below, for details about this.

### Graphical User Interfaces

Like almost all chess engines, plisco does not come with a graphical user
interface.  Try using one of these:

* [Cute Chess](https://cutechess.com/) (Linux, MacOS, and Windows)
* [Banksia GUI](https://banksiagui.com/) (Linux, MacOS, and Windows)
* [Arena](http://www.playwitharena.de/) (Linux, Windows)

## Internals

Functions and methods (subroutines) are the most fundamental way of avoiding
copy and paste - also known as Don't Repeat Yourself DRY (the mother of all evil)-
in source code, but it often comes at a cost, which is called call overhead.

Often times, the code runs faster if you copy the same snippets over and over
again to the needed locations instead of invoking a subroutine with arguments.
This is called inlining. But it leads, of course, to really ugly code, which is
a nightmare to maintain.

But there are ways to achieve the same results in a more readable form. The
most prominent examples are the commands `m4` and the infamous C preprocessor
`cc -E` (or the equivalent `cpp`). Both are
preprocessors that basically do a pretty smart search and replace on your
source code. Many purists hate these tools but they are key, when you have to
improve performance.

C++ tried to calm down the haters with the `inline` keyword. It is pretty much
a politically correct C preprocessor without its quirks. That turned out to
be quite useful, and eventually, the `inline` keyword found its way back into
C++'s mother language C.

Another such trick is generic programming. Search the internet if you are
interested.

Perl actually allowed you to automatically preprocess your code with the C
preprocessor, but the corresponding option `-P` was dropped with Perl
5.18 because it had many practical issues. But you can, of course, use it
in your own setup. The same goes for `m4`. Both options did not really work
well with `Chess-Plisco`.

The solution was another Perl gimmick, so-called source code filters. These
filters are regular Perl modules that receive some source code as input and
are expected to produce output that can be processed by the Perl interpreter.
They are run before the Perl interpreter itself parses the code, and
this is what `Chess-Plisco` is using for inlining.

What happens, if you run the embedded engine from a cloned source code
repository?

```shell
perl -Ilib ./bin/plisco
```

That works. But it invokes the source code filter on-the-fly. The source
code filter parses the code with the notoriously slow module
[PPI](https://metacpan.org/pod/PPI) and replaces "macros" (see
[Chess::Plisco::Macro](https://metacpan.org/dist/Chess-Plisco/view/lib/Chess/Plisco/Macro.pod))
with the code that is actually executed. Inlining.

In order to speed up the installed module, there is a script `expand-macros`
in the top-level directory that runs a whole directory of Perl source files
through that source filter and expands them in place. This is one step in the
build workflow. Therefore, the published releases of `Chess-Plisco` do not
have this start-up penalty and compile relatively fast. There is still a
noticeable delay that comes from pre-computing relatively large lookup tables.

Releases of `Chess-Plisco` are created with the help of
[`Dist::Zilla`](https://dzil.org/), which makes the integration of the source
code filter really easy. It is probably feasible to integrate the filter on a
lower level after `perl Makefile.PL && make`, so that you will find expanded
sources inside `blib/lib`, but so far, there was no demand for it. For the time
being, you have to know that the library created after the conventional Perl
build plethor `perl Makefile.PL && make` will produce a module with a massive
start-up overhead.

## Copryight

Copyright (C) 2021-2026, Guido Flohr, guido.flohr@cantanea.com, all rights reserved.
