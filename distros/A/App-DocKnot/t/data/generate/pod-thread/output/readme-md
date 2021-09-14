# Pod::Thread

[![Build
status](https://github.com/rra/pod-thread/workflows/build/badge.svg)](https://github.com/rra/pod-thread/actions)
[![CPAN
version](https://img.shields.io/cpan/v/Pod-Thread)](https://metacpan.org/release/Pod-Thread)
[![License](https://img.shields.io/cpan/l/Pod-Thread)](https://github.com/rra/pod-thread/blob/master/LICENSE)

Copyright 2002, 2008-2009, 2013, 2021 Russ Allbery <rra@cpan.org>.  This
software is distributed under a BSD-style license.  Please see the section
[License](#license) below for more information.

## Blurb

Pod::Thread translates POD source into thread, a macro language processed
by spin.  It supports optionally adding a table of contents and a
navigation bar to the genenerated file.  This package also includes the
pod2thread driver script, invoked automatically by spin for POD files and
pointers to POD files.

## Description

This package contains a module to translate POD into thread, an HTML macro
language.  As such, it's not very useful without
[spin](https://www.eyrie.org/~eagle/software/web/), a separate program to
convert thread into HTML.  I wrote this module for my personal needs and
it may not be (and in fact probably isn't) suitable for more general use
as yet.

The eventual intention is to incorporate spin into
[DocKnot](https://www.eyrie.org/~eagle/software/docknot/), at which point
this module will provide the POD support for DocKnot as a static site
generator.  I have no estimate for when that work will be done.

The conversion done by this module is mostly straightforward.  The only
notable parts are the optional generation of a table of contents or a
navigation bar at the top of the generated file.

## Requirements

Perl 5.24 or later and Pod::Parser 3.06 or later.  As mentioned above,
it's also not particularly useful without spin.

## Building and Installation

Pod::Thread uses Module::Build and can be installed using the same process
as any other Module::Build module:

```
    perl Build.PL
    ./Build
    ./Build install
```

You will have to run the last command as root unless you're installing
into a local Perl module tree in your home directory.

## Testing

Pod::Thread comes with a test suite, which you can run after building
with:

```
    ./Build test
```

If a test fails, you can run a single test with verbose output via:

```
    ./Build test --test_files <path-to-test>
```

Perl6::Slurp is required by the test suite.  The following additional Perl
modules will be used by the test suite if present:

* Devel::Cover
* Perl::Critic::Freenode
* Test::MinimumVersion
* Test::Perl::Critic
* Test::Pod
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

The [Pod::Thread web
page](https://www.eyrie.org/~eagle/software/pod-thread/) will always have
the current version of this package, the current documentation, and
pointers to any additional resources.

For bug tracking, use the [issue tracker on
GitHub](https://github.com/rra/pod-thread/issues).  However, please be
aware that I tend to be extremely busy and work projects often take
priority.  I'll save your report and get to it as soon as I can, but it
may take me a couple of months.

## Source Repository

Pod::Thread is maintained using Git.  You can access the current source on
[GitHub](https://github.com/rra/pod-thread) or by cloning the repository
at:

https://git.eyrie.org/web/pod-thread.git

or [view the repository on the
web](https://git.eyrie.org/?p=web/pod-thread.git).

The eyrie.org repository is the canonical one, maintained by the author,
but using GitHub is probably more convenient for most purposes.  Pull
requests are gratefully reviewed and normally accepted.

## License

The Pod::Thread package as a whole is covered by the following copyright
statement and license:

> Copyright 2002, 2008-2009, 2013, 2021
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
