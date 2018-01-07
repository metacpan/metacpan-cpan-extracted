# DocKnot 1.02

Copyright 2013-2017 Russ Allbery <rra@cpan.org>.  This software is
distributed under a BSD-style license.  Please see the section
[License](#license) below for more information.

## Blurb

DocKnot is a system for generating consistent human-readable software
package documentation from metadata files and templates.  The metadata is
primarily JSON files, but can include files of documentation snippets.
The goal is to generate both web pages and distributed documentation files
(such as `README`) from the same source, using templates for consistency
across multiple packages.

## Description

After years of maintaining a variety of small free software packages, I
found the most tedious part of making a new release was updating the
documentation in multiple locations.  Copyright dates would change,
prerequisites and package descriptions would change, and I had to update
at least the package `README` file and its web pages separately.  The last
straw was when GitHub became popular and I wanted to provide a Markdown
version of `README` as well, avoiding the ugly text rendering on the
GitHub page for a package.

This package uses one metadata directory as its source information and
generates all the various bits of documentation for a package.  This
allows me to make any changes in one place and then just regenerate the
web page, included documentation, and other files to incorporate those
changes.  It also lets me make changes to the templates to improve shared
wording and push that out to every package I maintain during its next
release, without having to remember which changes I wanted to make.

DocKnot was designed and written for my personal needs, and I'm not sure
it will be useful for anyone else.  At the least, the template files are
rather specific to my preferences about how to write package
documentation, and the web page output is in my personal thread language
as opposed to HTML.  I'm not sure if I'll have the time to make it a more
general tool.  But you're certainly welcome to use it if you find it
useful, send pull requests to make it more general, or take ideas from it
for your own purposes.

Currently included in this package are just the App::DocKnot module (which
contains most of the logic), a small docknot driver program, and the
templates I use for my own software.  Over time, it may include more of my
web publishing framework, time permitting.

## Requirements

Perl 5.18 or later and Module::Build are required to build this module.
The following additional Perl modules are required to use it:

* File::BaseDir
* File::ShareDir
* JSON
* Perl6::Slurp
* Template (part of Template Toolkit)

IPC::System::Simple is required to run the test suite.  The following
additional Perl modules will be used by the test suite if present:

* Devel::Cover
* Test::MinimumVersion
* Test::Perl::Critic
* Test::Pod
* Test::Pod::Coverage
* Test::Spelling
* Test::Strict
* Test::Synopsis

All are available on CPAN.  Those tests will be skipped if the modules are
not available.

To enable tests that don't detect functionality problems but are used to
sanity-check the release, set the environment variable `RELEASE_TESTING`
to a true value.  To enable tests that may be sensitive to the local
environment or that produce a lot of false positives without uncovering
many problems, set the environment variable `AUTHOR_TESTING` to a true
value.

## Building and Installation

DocKnot uses Module::Build and can be installed using the same process as
any other Module::Build module:

```
    perl Build.PL
    ./Build
    ./Build test
    ./Build install
```

You will have to run the last command as root unless you're installing
into a local Perl module tree in your home directory.

## Support

The [DocKnot web page](https://www.eyrie.org/~eagle/software/docknot/)
will always have the current version of this package, the current
documentation, and pointers to any additional resources.

For bug tracking, use the [CPAN bug
tracker](https://rt.cpan.org/Dist/Display.html?Name=App-DocKnot).
However, please be aware that I tend to be extremely busy and work
projects often take priority.  I'll save your report and get to it as soon
as I can, but it may take me a couple of months.

## Source Repository

DocKnot is maintained using Git.  You can access the current source on
[GitHub](https://github.com/rra/docknot) or by cloning the repository at:

https://git.eyrie.org/git/devel/docknot.git

or [view the repository on the
web](https://git.eyrie.org/?p=devel/docknot.git).

The eyrie.org repository is the canonical one, maintained by the author,
but using GitHub is probably more convenient for most purposes.  Pull
requests are gratefully reviewed and normally accepted.  It's probably
better to use the CPAN bug tracker than GitHub issues, though, to keep all
Perl module issues in the same place.

## License

The DocKnot package as a whole is covered by the following copyright
statement and license:

> Copyright 2013-2017
>     Russ Allbery <rra@cpan.org>
>
> Permission is hereby granted, free of charge, to any person obtaining a
> copy of this software and associated documentation files (the "Software"),
> to deal in the Software without restriction, including without limitation
> the rights to use, copy, modify, merge, publish, distribute, sublicense,
> and/or sell copies of the Software, and to permit persons to whom the
> Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in
> all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
> THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
> FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
> DEALINGS IN THE SOFTWARE.

Some files in this distribution are individually released under different
licenses, all of which are compatible with the above general package
license but which may require preservation of additional notices.  All
required notices, and detailed information about the licensing of each
file, are recorded in the LICENSE file.

For any copyright range specified by files in this package as YYYY-ZZZZ,
the range specifies every single year in that closed interval.
