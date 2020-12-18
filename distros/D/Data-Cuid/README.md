[![Actions Status](https://github.com/zakame/Data-Cuid/workflows/Test%20on%20latest%20supported%20Perls/badge.svg)](https://github.com/zakame/Data-Cuid/actions) [![Coverage Status](https://img.shields.io/coveralls/zakame/Data-Cuid/master.svg?style=flat)](https://coveralls.io/r/zakame/Data-Cuid?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Data-Cuid.svg)](https://metacpan.org/release/Data-Cuid) [![Build Status](https://img.shields.io/appveyor/ci/zakame/Data-Cuid/master.svg?logo=appveyor)](https://ci.appveyor.com/project/zakame/Data-Cuid/branch/master)
# NAME

Data::Cuid - collision-resistant IDs

# SYNOPSIS

    use Data::Cuid qw(cuid slug);

    my $id   = cuid();          # cjg0i57uu0000ng9lwvds8vb3
    my $slug = slug();          # uv1nlmi

# DESCRIPTION

`Data::Cuid` is a port of the cuid JavaScript library for Perl.

Collision-resistant IDs (also known as _cuids_) are optimized for
horizontal scaling and binary search lookup performance, especially for
web or mobile applications with a need to generate tens or hundreds of
new entities per second across multiple hosts.

`Data::Cuid` does not export any functions by default.

# FUNCTIONS

## cuid

    my $cuid = cuid();

Produce a cuid as described in [the original JavaScript
implementation](https://github.com/ericelliott/cuid#broken-down).  This
cuid is safe to use as HTML element IDs, and unique server-side record
lookups.

## slug

    my $slug = slug();

Produce a shorter ID in nearly the same fashion as ["cuid"](#cuid).  This slug
is good for things like URL slug disambiguation (i.e., `example.com/some-post-title-<slug>`) but is absolutely not recommended
for database unique IDs.

# SEE ALSO

[Cuid](http://usecuid.org/)

# LICENSE

The MIT License (MIT)

Copyright (C) Zak B. Elep.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# AUTHOR

Zak B. Elep <zakame@cpan.org>

Original cuid JavaScript library maintained by [Eric
Elliott](https://ericelliottjs.com)
