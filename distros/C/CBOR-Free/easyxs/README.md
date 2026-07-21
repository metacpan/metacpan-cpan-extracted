# Easy XS

This library is a toolbox that assists with creation & maintenance
of Perl XS code.

# Usage

1. Make this repository a
[git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
of your own XS module.

2. Replace the standard XS includes (`EXTERN.h`, `perl.h`, and `XSUB.h`)
with just `#include "easyxs/easyxs.h"`.

… and that’s it! You now have a suite of tools that’ll make writing XS
easier and safer.

# Rationale

Perl’s C API makes lots of things _possible_ without making them
_easy_ (or _safe_).

This library attempts to provide shims around that API that make it easy
and safe (or, at least, safe-_er_!) to write XS code … maybe even *fun!* :-)

# Library Components

## Initialization

`init.h` includes the standard boilerplate code you normally stick at the
top of a `*.xs` file. It also includes a fix for the
[torrent of warnings that clang 12 throws](https://github.com/Perl/perl5/issues/18780)
in pre-5.36 perls. `easyxs.h` brings this in, but you can also include it
on its own.

`init.h` also includes a fairly up-to-date `ppport.h`.

## Calling Perl

### `void exs_call_method_void(SV* object, const char* methname, SV** args)`

Like the Perl API’s `call_method()` but handles argument-passing for you.
`args` points to a NULL-terminated array of `SV*`s. (It may also be NULL.)

The method is called in void context, so nothing is returned.

This does _not_ trap exceptions.

**IMPORTANT:** This **mortalizes** each `args` member. That means Perl
will reduce each of those SVs’ reference counts at some point “soon” after.
This is often desirable, but not always; to counteract it, do `SvREFCNT_inc()`
around whichever arguments you want to be unaffected by the mortalization.
(They’ll still be mortalized, but the eventual reference-count reduction will
just have zero net effect.)

### `SV* exs_call_method_scalar(SV* object, const char* methname, SV** args)`

Like `exs_call_method_void()` but calls the method in scalar context.
The result is returned.

# Usage Notes

If you use GitHub Actions or similar, ensure that you
`git submodule init && git submodule update` as part of your checkout.

# License & Copyright

Copyright 2022 by Gasper Software Consulting. All rights reserved.

This library is released under the terms of the
[MIT License](https://mitlicense.org/).
