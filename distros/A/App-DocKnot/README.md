# DocKnot

[![Build
status](https://github.com/rra/docknot/workflows/build/badge.svg)](https://github.com/rra/docknot/actions)
[![CPAN
version](https://img.shields.io/cpan/v/App-DocKnot)](https://metacpan.org/release/App-DocKnot)
[![License](https://img.shields.io/cpan/l/App-DocKnot)](https://github.com/rra/docknot/blob/master/LICENSE)
[![Debian
package](https://img.shields.io/debian/v/docknot/unstable)](https://tracker.debian.org/pkg/docknot)

Copyright 1999-2021 Russ Allbery <rra@cpan.org>.  This software is
distributed under a BSD-style license.  Please see the section
[License](#license) below for more information.

## Blurb

DocKnot is a static web site generator built around a macro language
called thread, with special support for managing software releases.  In
addition to building a web site, it can generate distribution tarballs and
consistent human-readable software package documentation from a YAML
metadata file and templates.  The goal is to generate both web pages and
distributed documentation files (such as `README`) from the same source,
using templates for consistency across multiple packages.

## Description

In 1999, I wrote a program named `spin` that implemented an idiosyncratic
macro language called thread.  It slowly expanded into a static web site
generator and gained additional features to manage the journal entries,
book reviews, RSS feeds, and software releases.  DocKnot is the latest
incarnation.

In addition to its static web site generator, DocKnot can use one metadata
file as its source information and generate all the various bits of
documentation for a software package.  This allows me to make any changes
in one place and then regenerate the web page, included documentation, and
other files to incorporate those changes.  It also lets me make changes to
the templates to improve shared wording and push that out to every package
I maintain without having to remember track those changes in each package.

DocKnot is also slowly absorbing other tools that I use for software
distribution and web site maintenance, such as generating distribution
tarballs for software packages.

DocKnot was designed and written for my personal needs, and I'm not sure
it will be useful for anyone else.  At the least, the template files are
rather specific to my preferences about how to write package
documentation, and the thread macro language is highly specialized for my
personal web site.  I'm not sure if I'll have the time to make it a more
general tool.  But you're certainly welcome to use it if you find it
useful, send pull requests to make it more general, or take ideas from it
for your own purposes.

## Requirements

Perl 5.24 or later and Module::Build are required to build this module.
The following additional Perl modules are required to use it:

* Date::Language (part of TimeDate)
* Date::Parse (part of TimeDate)
* File::BaseDir
* File::ShareDir
* Git::Repository
* Image::Size
* IO::Compress::Xz (part of IO-Compress-Lzma)
* IO::Uncompress::Gunzip (part of IO-Compress)
* IPC::Run
* IPC::System::Simple
* JSON::MaybeXS
* Kwalify
* List::SomeUtils 0.07 or later
* Path::Tiny
* Perl6::Slurp
* Pod::Thread 3.00 or later
* Template (part of Template Toolkit)
* YAML::XS 0.81 or later

## Building and Installation

DocKnot uses Module::Build and can be installed using the same process as
any other Module::Build module:

```
    perl Build.PL
    ./Build
    ./Build install
```

You will have to run the last command as root unless you're installing
into a local Perl module tree in your home directory.

## Testing

DocKnot comes with a test suite, which you can run after building with:

```
    ./Build test
```

If a test fails, you can run a single test with verbose output via:

```
    ./Build test --test_files <path-to-test>
```

Capture::Tiny and File::Copy::Recursive are required to run the test
suite.  The following additional Perl modules will be used by the test
suite if present:

* Devel::Cover
* Perl::Critic::Freenode
* Test::CPAN::Changes (part of CPAN-Changes)
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

## Support

The [DocKnot web page](https://www.eyrie.org/~eagle/software/docknot/)
will always have the current version of this package, the current
documentation, and pointers to any additional resources.

For bug tracking, use the [issue tracker on
GitHub](https://github.com/rra/docknot/issues).  However, please be aware
that I tend to be extremely busy and work projects often take priority.
I'll save your report and get to it as soon as I can, but it may take me a
couple of months.

## Source Repository

DocKnot is maintained using Git.  You can access the current source on
[GitHub](https://github.com/rra/docknot) or by cloning the repository at:

https://git.eyrie.org/git/devel/docknot.git

or [view the repository on the
web](https://git.eyrie.org/?p=devel/docknot.git).

The eyrie.org repository is the canonical one, maintained by the author,
but using GitHub is probably more convenient for most purposes.  Pull
requests are gratefully reviewed and normally accepted.

## License

The DocKnot package as a whole is covered by the following copyright
statement and license:

> Copyright 1999-2021
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

Files covered by a license with an assigned SPDX License Identifier
include SPDX-License-Identifier tags to enable automated processing of
license information.  See https://spdx.org/licenses/ for more information.

For any copyright range specified by files in this package as YYYY-ZZZZ,
the range specifies every single year in that closed interval.
