# The typemap

The typemap answers one question per type: given the C type in an XSUB signature,
what code converts a Perl SV into it (INPUT) and what code turns it back into an SV
(OUTPUT). Perl ships a large default typemap covering the built-in types; the
`typemap` file in a distribution root adds the types that distribution invents.

## Three sections, in this order

```
TYPEMAP
Foo                  T_FOO               # C type (or class name) → XS type

INPUT
T_FOO
	…C that assigns $var from $arg…

OUTPUT
T_FOO
	…C that fills $arg from $var…
```

The TYPEMAP section maps **the type as written in the XSUB signature** to a symbolic
XS type name. INPUT and OUTPUT hold the code templates for those names.

**Every line under INPUT and OUTPUT must be indented with a literal TAB.** Spaces
there are the classic silent parse failure.

## Template variables

| Variable | Expands to |
|---|---|
| `$var` | the C variable being filled (INPUT) or read (OUTPUT) |
| `$arg` | the SV on the argument stack — `ST(n)` |
| `$type` | the C type, with `*` mangled to `Ptr` |
| `${pname}` | the fully qualified Perl name of the XSUB, for error messages |
| `$ntype` | the type without the `Ptr` suffix |

## The escaping rule

xsubpp evaluates INPUT/OUTPUT templates as **Perl double-quoted strings**. Every `"`
that has to reach the generated C must be written `\"`; an unescaped one ends the
Perl string early and the failure surfaces as an unrelated C syntax error, often
pointing at a line that looks fine.

```
# Wrong:    sv_magicext(newSVrv($arg, "Foo"), ...);
# Correct:  sv_magicext(newSVrv($arg, \"Foo\"), ...);
```

The same holds for `$` and `@` that are meant literally in the C code — escape them.

## The pattern for an object type

INPUT finds the magic and croaks if it is not there; OUTPUT creates the blessed SV
and attaches the magic. Together they mean an XSUB body only ever assigns `RETVAL`
— **blessing is the typemap's job, never the XSUB's.**

```
INPUT
T_FOO
	{
	SV *_sv = $arg;
	MAGIC *_mg = SvROK(_sv) && SvMAGICAL(SvRV(_sv))
	    ? mg_findext(SvRV(_sv), PERL_MAGIC_ext, &Foo_magic) : NULL;
	if (_mg)
	    $var = (Foo)(void *)_mg->mg_ptr;
	else
	    Perl_croak(aTHX_ \"%s: not a valid Foo object\", \"${pname}\");
	}

OUTPUT
T_FOO
	sv_magicext(newSVrv($arg, \"Foo\"), NULL, PERL_MAGIC_ext,
	    &Foo_magic, (const char *)$var, 0);
```

The `$var` cast works because the XS signature uses a **pointer typedef**:

```c
typedef FOO_Conn   *Foo;             /* the class name as a C identifier */
typedef FOO_Handle *Foo__Handle;     /* :: → __ is xsubpp's C-identifier form */
```

so `Foo::Handle self` in the signature needs no `*`, and the generated C sees
`Foo__Handle self`.

## One entry per type, not one generic entry

A single generic `T_MAGICEXT` entry that writes `&${type}_magic` looks like the
obvious deduplication. It relies on xsubpp expanding `::` to `__` inside `${type}`,
**which only happens from xsubpp 3.60 on** — below that, `${type}` is still
`Foo::Handle`, which is not a C identifier, and the generated file will not compile.
A distribution supporting older toolchains spells the vtable pointer out per type
(and one that does not, states `REQUIRE: 3.60` at the top of the typemap).

## Standard entries worth knowing

| XS type | For |
|---|---|
| `T_IV` / `T_UV` / `T_NV` | plain integers and floats |
| `T_PV` | `char *` — the SV's string buffer, valid only for the call |
| `T_PTR` | an opaque pointer as a plain IV; no blessing, no safety |
| `T_PTROBJ` | pointer blessed via `sv_setref_pv` — no free hook, no vtable check |
| `T_SV` | the SV itself, unconverted |
| `T_ARRAY` | a list flattened onto the stack |
| `T_BOOL` | truth, via `SvTRUE` |

The default typemap of the running Perl is a readable file — when the exact
template matters, print its path and read it:

```bash
perl -MConfig -e 'print "$Config{privlib}/ExtUtils/typemap\n"'
```

## Diagnosing

- **C error in generated code, unrelated to what you wrote** → escaping in a
  template, or a space where a TAB belongs.
- **`Could not find a typemap for C type 'Foo *'`** → the TYPEMAP section does not
  list the type exactly as the signature spells it. `Foo *` and `Foo*` are the same
  to C and different here.
- **The croak fires for a genuine object** → INPUT is looking on the wrong SV.
  `mg_findext` wants the referent, `SvRV($arg)`, not the reference.

Keep the generated `.c` around when a template misbehaves: reading the emitted
conversion code is faster than reasoning about the template.
