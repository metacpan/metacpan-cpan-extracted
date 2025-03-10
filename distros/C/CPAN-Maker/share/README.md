# README

![badge](https://github.com/rlauer6/make-cpan-dist/actions/workflows/build.yml/badge.svg)

This project is yet another attempt to create a repeatable, __easy to
use__ script for creating CPAN distributions.

# Table of Contents

* [README](#readme)
* [Overview](#overview)
* [Quick Start](#quick-start)
* [More Details](#more-details)
* [Perl Dependencies](#perl-dependencies)
* [What Next?](#what-next)
* [Creating a CPAN Distribution](#creating-a-cpan-distribution)
  * [The Easy Way](#the-easy-way)
    * [Additional Build Specification Options](#additional-build-specification-options)
  * [The Harder Way](#the-harder-way)
  * [The Hardest Way](#the-hardest-way)
* [FAQ](#faq)
  * [Why is this easier than just building a `Makefile.PL` by using `ExtUtils::MakeMaker`?](#why-is-this-easier-than-just-building-a-makefilepl-by-using-extutilsmakemaker)
  * [Why is there a bash script AND a Perl script](#why-is-there-a-bash-script-and-a-perl-script)
  * [Why did you _autoconfiscate_ a project that has just 1 Perl script and 1 bash script](#why-did-you-autoconfiscate-a-project-that-has-just-1-perl-script-and-1-bash-script)
  * [Where do files in the `extra_files` section end up?](#where-do-files-in-the-extrafiles-section-end-up)
  * [How can I add some post installation operations?](#how-can-i-add-some-post-installation-operations)
* [Module Versions](#module-versions)
* [Finally](#finally)
* [Author](#author)

# Overview

Historically, because I have been using the Redhat Package Manager to
create RPMs of Perl modules I install as part of my
application stacks, I don't bother with the creation of CPAN
distributions.

In order to possibly share some of these modules and to use a more
modern Perl toolchain (`cpanm`) to vendor libraries, I've needed a
quick and easy CPAN distribution creation utility compatible with my
existing toolchain.  Hence this project.

You can read more about this utility
[here](src/main/perl/lib/README.md). Or after installing the project:

```
make-cpan-dist.pl -h
perldoc CPAN::Maker
```

[Back to Table of Contents](#table-of-contents)

# Quick Start

```
cpanm -v CPAN::Maker
make-cpan-dist.pl -h
```

If you want to install this by building the project make sure you have
the `autotools` toolchain installed (`autoconf` and `automake`). If
you are using a RedHat derived Linux distribution, install the
`autoconf` and `automake` packages using `yum`. If you are using a
Debian based system then you may have success using `apt` to install
the necessary dependencies. There are also some Perl module
dependencies that are checked when you run `./configure`.

The `build` script in the root directory attempts to build the
software for several different Linux distro flavors.

```
git clone https://github.com/rlauer6/make-cpan-dist
cd make-cpan-dist
./build
```

If you want to do this in pieces take a look at the [build
script](build).

The build script essentially does the following after installing
dependencies:

```
./bootstrap
./configure
make & make install
```

> HINT: If you want to install locally, set `--prefix` during the
> configure process or update the `build` script.

```
./configure --prefix=$HOME/local
make && make install
```

[Back to Table of Contents](#table-of-contents)

# More Details

The goal of the project is to take a set of Perl modules, scripts and
possibly (hopefully) tests and _automatically_ create a CPAN
distribution.  The _automatic_ part is key, as I'd like this to simply
be part of a CI/CD pipeline for various projects. The idea would be to
create and include in the project a build specification file for
creating CPAN distributions.

To be clear, __this utility will not do everything you can do by using
`ExtUtils::MakeMaker` and passing it all of the appropriate
arguments.__  It does enough though to be a very useful
tool for automating your builds and creating a CPAN tarball.

If you run into limitations or bugs I'd appreciate an issue being opened
to let me know why and possibly how I might add new features to make
it more applicable to a wider set of scenarios.  As the kids say,
_pull requests are welcome too_.

# Perl Dependencies

One of the challenging aspects of developing Perl applications is
packaging and deploying your code.  Part of that process involves
identifying all of the Perl modules you've installed from CPAN to use
in your application.  Once you've identified all of the artifacts
necessary to include in your package (so your application will run
somewhere other than your laptop) you need to package those up
somehow. At the very least you need to create a manifest that
can be used when your application is installed.

Identifying non-core Perl modules required by your application can be
done manually by:

* inspecting each Perl module and finding where you `use` or `require` a module.
* determining the version of that module that has been tested with your
application
* determining if that module version was core in the Perl version your
application will running on or it needs to be installed

> `perl` provides a utility (`corelist`) which will report the version
> of `perl` that a particlular module was added or removed from core.
> Make sure you have an updated version of `corelist` installed!

This project uses the `scandeps-static.pl` utility to resolve
dependencies. this utility is distributed with the
[Module::ScanDeps::Static](https://metacpan.org/pod/Module::ScanDeps::Static)
Perl module. It is a rewrite of `perl.req` found in RedHat systems.

I've found it to do a better job than `scandeps.pl` or any of the
other dependency resolvers you might stumble across.  That's not to
say that it is fool proof or even the best dependency checker for
Perl.  That is a subject of a long blog post I think I should write
some day. Oh wait I did...

[Perl Dependency Checking](http://blogs.perl.org/users/rlauer/2019/01/perl-dependency-checking.html)

If you don't want to use that utility but have another favorite Perl
module dependency resolver then you're free to use that by providing
it on the command line (-r) of the `bash` helper script
(`make-cpan-dist`) or in the build specification. The function you
specify should simply provide a list of Perl modules one per line and
output that to STDOUT.

You can replace the use of `scandeps-static.pl` with `scandeps.pl` by
specifying the `-s` option to the helper script.

Other competing dependency checkers include:

* `Devel::Modlist`
* `Perl::PrereqScanner`

...all of which will give about the same results as `scandeps.pl`

If you use any of those other checkers, wrap them in a script to make
sure they output the list in the correct format.

```
cat <<eof > dep_resolver
#!/bin/bash

perl -MDevel::Modlist=nocore \$1.pm 2>&1 | awk '{ print \$1}'
eof

chmod +x dep_resolver
make-cpan-dist -a 'Rob Lauer <rlauer6@comcast.net>' \
   -m MyFunc -R no -l . -d "my function" \
   -r dep_resolver
```

[Back to Table of Contents](#table-of-contents)

# What Next?

After successfully building and installing the project you will have
available two utilities that are used together to build a CPAN
distribution.

* `make-cpan-dist`
* `make-cpan-dist.pl`

When using a buildspec file you need only be concerned with
`make-cpan-dist.pl` and simply pass the buildspec file as a parameter.

```
make-cpan-dist.pl -b buildspec.yml
```

[Back to Table of Contents](#table-of-contents)

# Creating a CPAN Distribution

There are three possible ways to create a CPAN distribution using the
utiities contained in this project, each with varying degrees of
simplicity and flexibility.  As a reminder, the point of these
utilities is to provide a __simple__ solution right?  So the
_simplest_ thing you can do is run the utility against a
`buildspec.yml` file that describes the distribution you would like to
create.

[Back to Table of Contents](#table-of-contents)

## The Easy Way

Create a `buildspec.yml` file that looks something like this:

```
project:
  git: https://github.com/rlauer6/perl-Amazon-Credentials.git 
  description: "AWS credentials discoverer"
  author:
    name: Rob Lauer
    mailto: rlauer6@comcast.net
pm_module: Amazon::Credentials
path:
  pm_module: src/main/perl/lib
  tests: src/main/perl/t
  exe_files: src/main/perl/bin
```

You specify some project metadata in the `project:` section and
possibly a pointer to the project in a git repository that will be
cloned.

You must also provide the name of the Perl module to package
(`pm_module`) and include a `path:` section that will point to the
modules and artifacts to be packaged.

The `path` attributes specify the path to the module, the path to the
tests and the path to executable scripts which will be included in
the distribution.  All files with an extension of `.t` are assumed to
be included in the package if you have specified a test path.

If your project includes other Perl modules somewhere in the
Perl module path then they will be packaged as well.  Paths are relative
to the root of the project or your current working directory if you
are not specifying a git repository as the source of your
package.

If your project includes Perl scripts, you can add those to your
distribution by setting the path to those with the `exe_files` and
`scripts` subsection of `path`.  These will be packaged and installed
in the `bin` directory (INSTALLBIN).

So, assuming you have created an appropriate
`buildspec.yml` file, the easy way boils down to this:

```
make-cpan-dist.pl -b buildspec.yml
```

After executing that statement, you should have a tar ball in your
current working directory.

[Back to Table of Contents](#table-of-contents)

### Additional Build Specification Options

The build specification file can contain some additional options to
control what and how things get packaged.

* use the `recurse` option to add additional Perl modules from your
  project path. If you want to add additional Perl modules to the
  distribution, just make sure they are under the directory path of
  your core module and the `recurse` option is set to `yes`. _Actually
  this is the default.  If you don't want to recurse, set this to
  *no*._

   ```
   path:
     recurse: yes
   ```

* to use a different module dependency checker than the default
  (`scandeps-static.pl`) set the `resolver` option under the
  `dependencies` section. A value of `scandeps` will use `scandeps.pl`
  or set the name of an executable that will simply output
  a list of Perl module names.

  ```
  dependencies:
    resolver: scandeps
  ```

* to manually specify a list of dependencies, set the `requires` option
  under the `dependencies` section to the path to a file that contains
  a list of Perl modules. If the name of the file is `cpanfile` then
  it is assumed to be a `cpanfile` formatted list, otherwise the list
  should be a simple listing of module names optionally followed by a
  version (e.g. `List::Util 1.5`). By default core modules will be
  filtered from the list of modules.
  
  Include the option `core_modules` with a value of _yes_ if you do
  not want to filter out core modules.

  ```
  min_perl_version: 5.16.3
  dependencies:
    requires: requires
    core_modules: yes
  ```

  If you filter out core modules be aware that you may still require a
  specific version of a module that is core. Take `List::Util` for
  example.  This module has been in core since v5.7.3, however the
  functions `zip` and `mesh` were not added until March of 2021. If
  you were running on a system that installed only the core modules
  for v5.16.3 you would find that the version of `List::Util` is 1.27
  and does not include those functions.
  
  So, if you want to filter out core modules but need to include a
  core module with a specific version, place a + in front of the
  module name (e.g. `+List::Util 1.5`) in your `requires` file.

  You should also include the minimum version of `perl` that is going to
  be used to determine if a module is core.  The default is
  $PERL_VERSION (the version of perl in your environment) which may
  not be the same version as your target deployment environment!

[Back to Table of Contents](#table-of-contents)

## The Harder Way

A slighly harder way is to call the helper bash script directly with
specific options to create the distribution.

```
usage: make-cpan-dist Options

Utility to create a CPAN distribution. See 'man make-cpan-dist'

Options
-------
-a author      - author (ex: Anonymouse <anonymouse@example.org>)
-b buildspec   - use a buildspec file instead of options
-d description - description to be included CPAN
-D file        - use file as the dependency list
-e path        - path for extra .pl files to package
-h             - help
-f file        - file containing a list of extra files to include
-l path        - path to Perl modules
-m name        - module name
-o dir         - output directory (default: current directory)
-p             - preserve Makefile.PL
-P file        - file that contains a list of modules to be packaged
-r pgm         - script or program to list dependencies
-s             - use scandeps.pl to find dependncies
-R yes/no      - recurse directories for files to package (default: yes)
-t path        - path to test files
-v             - more verbose output
-V             - version from
-x             - do not cleanup files

NOCLEANUP=1, PRESERVE_MAKEFILE=1 can also be passed as environment variables.
```

Example:

Assuming your source tree looks something like this:

```
.
lib/
lib/Foo
lib/Foo/Bar.pm
t/
```

...then...

```
make-cpan-dist -l lib -t t -m Foo::Bar
```

So far, neither of these methods is particularly hard and can be used
interchangeably as part of your deployment pipeline.  The key to the
"easiness" part, at least for me, is the fact that the `bash` script
will try to resolve dependencies using the selected dependency resolver
and find the Perl module version for each of those
dependencies.  The __dependency resolver is not perfect__,
specifically it may get tripped up on some ways your clever Perl
module utilizes other resources.  In general though, _it's good
enough_.  You you can always ask the script to preserve (`-p`) the
`Makefile.PL` that is generated and start tweaking that yourself. You
could also open an issue and I'll try to tackle it. You could also
make a pull request. ;-)

[Back to Table of Contents](#table-of-contents)

## The Hardest Way

The hardest way to create a CPAN distribution using this utility is to
provide the dependency files for your module by creating them yourself
and then calling `make-cpan-dist.pl` directly to create a
`Makefile.PL` file that you can then modify.

The dependency files list the module name and their version (or 0).
For example:

```
Amazon::Signature4 1.02
```

At this point you have pretty much decided to roll your own
`Makefile.PL` so have fun with [`ExtUtils::MakeMaker`](https://metacpan.org/pod/ExtUtils::MakeMaker).

To summarize what the `bash` helper script does, all of which you can
of course do manually, the script will:

1. iterate over all of the `.pm` files in your source tree
   1. run a dependency checker and save the output
1. sort the list and get the unique dependencies
1. separate out the dependencies from the modules provided by your project
1. iterate over the sorted list of dependencies
   1. retrieve the version number of each module
   1. save the module and version number to the dependency file
1. repeat for each test (*.t) in the test directory
1. repeat for the each script in your script directory

The result of the above operation is a set of files:
* `requires`
* `test-requires`
* `provides`

These files are eventually used by the `make-cpan-dist.pl` script to
create your final `Makefile.PL`.

[Back to Table of Contents](#table-of-contents)

# FAQ

## Why is this easier than just building a `Makefile.PL` by using `ExtUtils::MakeMaker`?

Well, to be upfront about it, __maybe it's not__, especially for
smaller projects. Using the buildspec approach does make it
particulary easy though. And as your project grows modifying the
buildspec file is probably easier than remembering how
`ExtUtils::MakeMaker` works.  

Moreover, I feel this approach makes automation easier. I alway find
it best to take a bunch of steps I will seldom remember and package
them into self-contained utilities that can be forgotten about.  This
approach works for me, but as always YMMV. As I mentioned, I'm also
using this utility as a component of a CI/CD pipeline. Here's an
[example](cpan/Makefile.am) of using this utility with a [buildspec
file](cpan/buildspec.yml) in a `Makefile`.

For a real simple project whose file hierarchy looks like this:

```
ChangeLog
README.md
lib/Foo/Bar.pm
lib/Foo/Bar/Baz.pm
bin/foo.pl
t/00-foo.t
```

...your buildspec file might look like this:

```
project:
  description: "My awesome project"
  author:
    name: Your Name
    mailto: anonymouse@example.org
pm_module: Foo::Bar
extra-files:
  - README.md
  - ChangeLog
path:
  pm_module: lib
  tests: t
  exe_files: bin
```

..and your `Makefile` like this:

```
VERSION := $(shell perl -I lib -MFoo::Bar -e 'print "$$Foo::Bar::VERSION";')

PROJECT=Foo-Bar-$(VERSION).tar.gz

MODULES = \
   lib/Foo/Bar.pm \
   lib/Foo/Bar/Baz.pm

SCRIPTS = \
   bin/foo.pl

$(PROJECT): buildspec.yml $(MODULES) $(SCRIPTS)
	make-cpan-dist.pl -b $<

CLEANFILES = \
    $(PROJECT)

clean:
	for a in $(CLEANFILES); do \
	  rm -f "$(PROJECT)"; \
	done
```

...which could also be accomplished from the command line:

```
make-cpan-dist -l lib -S bin -t t -m Foo::Bar
```

By creating a `Makefile` recipe, whenever I update the buildspec or
any of the modules or scripts and run `make`, I'll automatically
create a new distribution.

[Back to Table of Contents](#table-of-contents)

## Why is there a bash script AND a Perl script

If you find yourself scratching your head and wondering if
indeed the `bash` script calls the Perl script and vice versa, you are
correct.

The Perl script has two purposes:

1. parse the buildspec into options that are sent to the bash script 
1. write a `Makefile.PL` based on the options sent to it by the bash
  script
  
The bash script finds your artifacts to be packaged, Perl module
dependencies and calls the Perl script to write the `Makefile.PL`. In
the beginning I think I created a bash script that did all of the
heavy lifting but later found I needed a more powerful environment for
enhancing the script.

[Back to Table of Contents](#table-of-contents)

## Why did you _autoconfiscate_ a project that has just 1 Perl script and 1 bash script

Before we go any further, I'll bet I need to answer that question.
So, in no particular order...

* Habit
* Automation malleability
* Familiarity with the toolchain
* Standardization of my development process
* Flexibility to add more automation with `make` as a project organically matures
* Ubiquity of the toolchain
* Potential portability (nothing is 100% portable, but we can try)

I also leverage _autoconfiscation_ templates to create things like man
pages from Perl scripts and of course the installation process is made
simpler when you can rely on some degree of portability and
standardization of your toolchain. Many disagree and hate `autoconf` -
I get it - but it's not a holy war.

Take a look at
[autoconf-template-perl](https://github.com/rlauer6/autoconf-template-perl)
if you are curious about how to _autoconfiscate_ a Perl project.

[Back to Table of Contents](#table-of-contents)

## Where do files in the `extra_files` section end up?

Files in the `extra-files` section of the `buildspec.yml` file or in
the `extra-files` file are packaged as part of the distribution
tarball but will not be installed _unless you add them to the `share:`
section beneath `extra-files`.  In that case they will be installed
relative to the distribution's share directory.

```
extra-files:
  - share:
    - ChangeLog
    - README.md
```

You can find out where the distribution's share directory is as shown
below.

```
perl -MFile::ShareDir=dist_dir -e 'print dist_dir("Foo"),"\n";'
```

[Back to Table of Contents](#table-of-contents)

## How can I add some post installation operations?

[ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker)
provides the capability to add an additional step to your build or
installation process by providing a `postamble`
section. `make-cpan-dist.pl` supports this by allowing you to add a
section to your `buildspec.yml` file which specifies the name of a
file containing the extra `make` instructions that will be executed
after the build and before the installation. A typical postamble file
might look like this:

```
 postamble ::
 
 .PHONY: FOO
 FOO:
    echo "Thanks for using FOO!"

install:: FOO
```

[Back to Table of Contents](#table-of-contents)

# Module Versions

It's sometimes convenient to keep a project's version in a file other
than main Perl module. You might do this for example if you have
several modules in the distribution and you want them all to reflect
the same version number. If you decid to keep your project's version
in a file other than the main module, you can specify the `-V` option
to the bash script or add `version_from:` in your buildspec.

```
package Foo::Bar::VERSION;

our $VERSION = '1.0.1';

1;
```

```
package Foo::Bar;'

require Foo:Bar::VERSION;

1;
```

...then

```
make-cpan-dist -l lib -t t -S bin -m Foo::Bar -V Foo::Bar::VERSION
```

[Back to Table of Contents](#table-of-contents)

# Finally

I hope you find this useful. If I can make it more useful, let me
know.

# Author

Rob Lauer <rlauer6@comcast.net>

[Back to Table of Contents](#table-of-contents)
