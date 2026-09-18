---
name: perl-xs
description: "Use when writing or debugging XS — a .xs file, a typemap, ppport.h, xsubpp errors, C compile errors in generated code, segfaults or leaks at the Perl/C boundary, or wrapping a C library as a Perl distribution."
---

# XS — the Perl/C boundary

An `.xs` file is C with a preprocessor in front of it. `xsubpp` turns each XSUB
declaration into a C function reachable through Perl's calling convention; every
other line lands in the generated `.c` verbatim. So most of an XS file is plain C,
and the XS-specific part is three decisions:

1. **How does a C pointer live inside a Perl SV?** → `sv_magicext` with a per-type
   `MGVTBL`. See [references/objects-and-memory.md](references/objects-and-memory.md)
2. **How does that SV convert at the boundary?** → a per-type `typemap` entry.
   See [references/typemap.md](references/typemap.md)
3. **What does one XSUB look like inside?** → sections, `RETVAL`, the argument
   stack. See [references/xsub-anatomy.md](references/xsub-anatomy.md)

Compiling, `ppport.h` and testing for leaks:
[references/build-and-test.md](references/build-and-test.md)

## The files

| File | Role |
|---|---|
| `Foo.xs` | all implementation; several `MODULE`/`PACKAGE` sections may share one file |
| `typemap` | one entry per type crossing the boundary — INPUT and OUTPUT |
| `ppport.h` | generated compatibility shims; regenerate it, never hand-edit |
| `lib/Foo.pm` | `XSLoader::load`, `$VERSION`, POD — no logic |

A package implemented entirely in XS still gets a `.pm` file: it carries `$VERSION`
and the POD, while the package itself comes into being when xsubpp emits its
`MODULE = … PACKAGE = …` section. Each such `.pm` needs its own `our $VERSION`, and
they all move together on release.

The generated `Foo.c` is a build artifact. Keep it out of git.

## The preamble

```c
#define PERL_NO_GET_CONTEXT     /* take the interpreter as an argument */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_mg_findext         /* one NEED_ per ppport.h shim actually used */
#include "ppport.h"

#include <foolib/foolib.h>      /* the library being wrapped */
```

`PERL_NO_GET_CONTEXT` belongs in every XS file: without it each function that
touches the interpreter looks it up through thread-local storage. With it, the
interpreter travels as a parameter — which is why your own static helpers take
`pTHX_` and are called with `aTHX_`.

Each `NEED_foo` asks `ppport.h` to emit a static implementation of `foo` for Perls
that lack it, and must appear exactly once per compilation unit.

## MODULE, PACKAGE, PREFIX

```
MODULE = Foo    PACKAGE = Foo

PROTOTYPES: DISABLE
```

- Every XSUB after that line is installed into that package, until the next
  `MODULE`/`PACKAGE` line. One `.xs` file can serve a whole class family — a
  connection, the handles opened on it and its subsystems all live in one `Foo.xs`.
- `PROTOTYPES: DISABLE` goes once after the first `MODULE` line; xsubpp carries it
  into the later packages of the same file. Leaving it out earns a warning per XSUB.
- `PREFIX = foolib_` strips a C prefix from the Perl-visible name. It pays when
  wrapping a C API one-to-one, and only obscures things when the Perl API was
  designed separately.

## The object rule

A C pointer reaches Perl as **magic on a blessed SV**, under an `MGVTBL` that is
unique to its type:

```c
static int foo_conn_free(pTHX_ SV *sv, MAGIC *mg) {
    FOO_Conn *self = (FOO_Conn *)(void *)mg->mg_ptr;
    if (self->conn) { foolib_close(self->conn); foolib_free(self->conn); }
    Safefree(self);
    return 0;
}
static const MGVTBL Foo_magic = { .svt_free = foo_conn_free };
```

`svt_free` is the destructor, and it is a better one than a Perl method: it fires
when the SV is collected, it still fires during global destruction, and no subclass
can override it away. **An XS object needs no `DESTROY` sub** — not in the XS, not
in the `.pm`.

The vtable address is also the type check. `mg_findext(sv, PERL_MAGIC_ext,
&Foo_magic)` matches only magic carrying that exact vtable, so a hand-blessed
hashref croaks at the boundary instead of segfaulting through an `INT2PTR` cast on
a pointer that was never there. That is the reason to skip `T_PTROBJ`, which stores
the pointer with `sv_setref_pv` and offers neither a free hook nor a real type
check.

## Four ways it goes wrong

1. **An unescaped `"` in the typemap.** xsubpp reads INPUT/OUTPUT templates as Perl
   double-quoted strings, so a quote meant for the generated C must be written
   `\"`. The failure surfaces as a C syntax error in code you never wrote.
2. **The refcount taken on the wrong SV.** `ST(0)` is the reference; `SvRV(ST(0))`
   is the blessed referent carrying the magic. A child object that keeps its parent
   alive must increment the **referent** — incrementing `ST(0)` survives scope exit
   and segfaults on `undef $parent`, which is the case tests reach for last.
3. **`XSRETURN_UNDEF` bypasses the OUTPUT section.** It is the way to return undef
   instead of an object, and it means everything allocated up to that point leaks
   unless the branch frees it first.
4. **A NULL handle the C library tolerates.** After a close or free, many libraries
   accept a NULL handle and return a plausible wrong answer instead of crashing —
   `-1`, or an empty string. Every method needs an explicit open-check that croaks,
   or the bug stays invisible in testing.

## Build

An XS distribution is built by `ExtUtils::MakeMaker`; the flags for an external
library come from whatever resolves them (`Alien::*`, `pkg-config`, hardcoded):

```perl
WriteMakefile(
  LIBS   => [ '-lfoo' ],
  INC    => '-I/usr/include',
  OBJECT => 'Foo$(OBJ_EXT)',   # matches the .xs basename
);
```

Under Dist::Zilla with `[@Author::GETTY]`, that `Makefile.PL` is generated from two
lines in `dist.ini` (`xs_alien` names the Alien module, `xs_object` the `.xs`
basename), and `dzil build` is then the only supported path — a hand-written
`Makefile.PL` in the working directory resolves its flags differently from the
release and makes a green local `make test` mean nothing. Details in
`getty-perl-release-author-getty`; the library side in `perl-alien`.
