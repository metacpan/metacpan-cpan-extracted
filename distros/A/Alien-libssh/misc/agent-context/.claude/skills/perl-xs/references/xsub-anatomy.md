# Anatomy of an XSUB

An XSUB declaration is: return type on its own line, name and argument names, one
line per typed argument, then optional sections. xsubpp turns it into a C function
that reads Perl's argument stack, runs your code, and writes the return stack.

```
SV *
read(self, ...)
    Foo::Handle self
  CODE:
    int len = -1;
    if (items >= 2) len = SvIV(ST(1));
    RETVAL = …;
  OUTPUT:
    RETVAL
```

## The sections

| Section | When it runs | For |
|---|---|---|
| `PREINIT:` | before argument conversion | declarations, when the code must be C89 |
| `INIT:` | after conversion, before `CODE`/autocall | argument validation |
| `CODE:` | the body | anything |
| `PPCODE:` | the body, instead of `CODE` | pushing the return stack by hand |
| `OUTPUT:` | after the body | which variables get written back |
| `CLEANUP:` | last | freeing what the body allocated |

With no `CODE`/`PPCODE`, xsubpp writes the call itself: it invokes the C function of
the same name with the declared arguments and assigns `RETVAL`. That autocall is the
right shape for a thin one-to-one wrapper and nothing else.

`PREINIT` exists because C89 forbids declarations after statements. Where the
toolchain is C99 or later, declaring directly at the top of `CODE:` reads better and
keeps the declaration next to its use.

## RETVAL

`RETVAL` is declared automatically whenever the return type is not `void`, and
listing it under `OUTPUT:` is what makes it the return value. Naming it there is
required as soon as there is a `CODE:` block — the autocall form does it implicitly.

**For a return type of `SV *`, xsubpp emits `RETVAL = sv_2mortal(RETVAL);`.** So the
body hands back a fresh SV with a refcount of 1 (`newSVpv`, `newRV_noinc`, …) and
does not mortalise it. Doing it twice is a double free. Returning `&PL_sv_undef`
that way is safe: `sv_2mortal` returns immortals untouched.

`RETVAL` for other types goes through the typemap's OUTPUT template instead, which
is where an object gets blessed — see [typemap.md](typemap.md).

## Arguments

The typed lines convert through the typemap; `items` holds the count, `ST(n)` the
raw SVs, `ST(0)` being the invocant for a method.

```
SV *
read(self, ...)                    /* ... makes everything after self optional */
    Foo::Handle self
```

- A trailing `...` turns off the generated arity check and hands the body `items`
  plus `ST(1)`, `ST(2)`, … to read as it sees fit.
- Named optional arguments use `= default` in the signature (`int flags = 0`);
  xsubpp then checks arity itself and fills the default.
- Without either, xsubpp emits `croak_xs_usage(cv, "self, cmd")` on a wrong count,
  which is the error message the caller sees.

Reading an argument that was never passed is reading past the stack. `items` is the
only thing that says whether `ST(2)` exists.

`SvIV(undef)` is `0` and `SvPV` of undef is the empty string, both with at most a
warning. An optional numeric argument therefore cannot distinguish "absent" from
"passed as undef" unless the body checks `SvOK(ST(n))` explicitly.

## Returning

For a single value, set `RETVAL`. Beyond that:

- **`XSRETURN_UNDEF`** returns undef immediately and **skips `OUTPUT:`** — the way
  to say "no object". Whatever the body allocated before it must be freed on that
  path.
- **`XSRETURN_YES` / `XSRETURN_NO` / `XSRETURN_EMPTY`** are the same shortcut for
  true, false, and the empty list. A `void` XSUB compiles to `XSRETURN_EMPTY`.
- **A hashref or arrayref** is one SV like any other:
  ```c
  HV *h = newHV();
  hv_stores(h, "size", newSVuv(attr->size));   /* hv_stores takes ownership */
  RETVAL = newRV_noinc((SV *) h);              /* _noinc: the RV takes the count */
  ```
  `newRV_inc` instead leaks the HV — it takes its own reference on something already
  at 1 and nothing releases the original.
- **A list** needs `PPCODE:`, where the stack is yours:
  ```
  void
  pair(self)
      Foo self
    PPCODE:
      EXTEND(SP, 2);
      mPUSHs(newSVpv(self->name, 0));    /* mPUSHs: the SV is mortalised for you */
      mPUSHu(self->count);
      XSRETURN(2);
  ```
  `EXTEND(SP, n)` first, then push. `PUSHs` requires a mortal SV — `mPUSHs` and the
  `mPUSH*` family take a fresh one and mortalise it. There is no `OUTPUT:` section
  in a `PPCODE` XSUB.
- **Context-dependent returns** read `GIMME_V` (`G_VOID`, `G_SCALAR`, `G_LIST`).
  Worth it only when the two shapes are genuinely different data.

## Errors

`croak` is the C-level `die`; the Perl side catches it with `eval`. Under
`PERL_NO_GET_CONTEXT`, write it as `Perl_croak(aTHX_ "…")` in your own static
helpers, where `aTHX` is not implicit.

```c
Perl_croak(aTHX_ "%s: %s", "Foo::option", foolib_get_error(self->conn));
```

Prefix every message with the fully qualified method name. `${pname}` gives it to
typemap templates for free; in XSUB bodies it is worth writing out, because the C
stack frame is invisible from Perl and the message is all the caller gets.

A croak is a `longjmp`: anything allocated and not yet owned by a Perl SV at that
point leaks. Validate before allocating.

## ALIAS

Several Perl names for one XSUB, distinguished by the integer `ix`:

```
int
width(self)
    Foo self
  ALIAS:
    height = 1
  CODE:
    RETVAL = ix ? self->h : self->w;
  OUTPUT:
    RETVAL
```

Worth it for accessor families over one struct; not worth it when the bodies diverge
past a single branch.

## PROTOTYPES

`PROTOTYPES: DISABLE` once after the first `MODULE` line silences xsubpp's per-XSUB
warning and is what most distributions want — Perl prototypes affect parsing of
calls without parentheses, which is not something a method wants to change.
