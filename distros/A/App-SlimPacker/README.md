# App::SlimPacker

Fatpack-style bundler with PPI-based minification for standalone Perl scripts.

`slimpack` turns a boot script plus its module tree into a single
self-contained, minified `#!/usr/bin/perl` script. By default it runs the whole
`fatpack` pipeline internally (via `App::FatPacker`'s methods):

1. **trace** the boot script to discover which modules it loads,
2. **drop** core modules with a `Module::CoreList` filter,
3. **resolve** the surviving modules' `.packlist` files,
4. **copy** their sources into a temporary `fatlib/`,
5. **minify** each reachable `.pm` from `lib/` plus every `.pm` from `fatlib/`
   with `App::SlimPacker::process()`, and emit the final script — shebang,
   `%INC` preamble, minified modules, boot script.

Each step is also available as its own subcommand (see Usage). It is
project-agnostic: no search paths or class layouts are baked in.

## Layout

| File | Purpose |
| --- | --- |
| `lib/App/SlimPacker.pm` | The minifier (`process`, `minify_file`, `name_gen`, `needs_space`) and bundling helpers |
| `bin/slimpack` | CLI bundler that assembles the final script |
| `bin/minify` | Standalone minify-only front-end (same minification pass, no bundling) |
| `t/minify.t` | Tests for the minifier (whitespace rules, variable renaming) |
| `t/deps.t` | Tests for dependency finding (`module_deps`, plugin inlining, `perl_switches`) |
| `t/bundle.t` | End-to-end tests for the `bundle` subcommand |
| `t/minify-cli.t` | Tests for minify-only mode (`slimpack minify`, `--minify`, `bin/minify`) |
| `t/cli.t` | Tests for subcommand dispatch (`pack`, `trace`, `packlists-for`, `tree`, `bundle`) |

## Installation

```sh
perl Makefile.PL
make
make test
make install        # installs bin/slimpack and bin/minify to your perl's bin dir
```

Requires `PPI` and `App::FatPacker` (neither is a core module); `Module::CoreList` ships with perl.

## Usage

By default `slimpack` runs the whole fatpack pipeline internally (calling
`App::FatPacker`'s methods, no shelling out): trace the boot script, drop core
modules via `Module::CoreList`, resolve their `.packlist` files, copy the
sources into a temporary `fatlib/`, then minify and emit the standalone script.
Each step is also exposed as a subcommand with the same arguments as `fatpack`:

```sh
slimpack [OPTIONS] [COMMAND] [ARGS]

# default 'pack' — full pipeline
slimpack [OPTIONS] script
slimpack [OPTIONS] -e/-E 'code' [-m/-M module ...]

# individual steps (fatpack-compatible args)
slimpack trace        [--to=FILE|--to-stderr] [--use=MODULE] script
slimpack packlists-for MODULE...
slimpack tree         [PACKLIST ...]
slimpack bundle       [OPTIONS] script          # minify+bundle only (--lib/--fatlib)

  script               boot script to bundle (ignored when -e/-E is given)
  -m module            use module with no imports  (like perl -m)
  -M module[=list]     use module, optional import list or version (like perl -M)
  -e CODE              code to bundle; may be repeated  (like perl -e)
  -E CODE              same, but enables all features  (like perl -E)
  -o, --output FILE    write the bundled script to FILE and chmod +x
                       (default a.out; use '-' for stdout)
  --lib DIR            project .pm sources  (default lib)
  --fatlib DIR         fatpacked core-module tree  (default fatlib; pack uses a temp one)
  --no-minify          bundle modules and boot program verbatim
  --no-rename          minify but leave variable names untouched
  --rewrite            additionally shorten keywords/operators (opt-in,
                       experimental; see "The minifier" below)
  --no-compress        embed module sources verbatim (compression with core
                       deflate + base64 is ON by default; see "Smaller bundles")
  --no-inline-plugins  keep Module::Pluggable as a runtime dependency
  --bundle-lib-all     include every .pm under --lib, even if not referenced
                       from the boot program (default: only statically-reachable
                       lib modules are bundled; fatlib is always fully included)
```

Module discovery resolves the static dependency tree from `--lib` and fully
includes what `pack` collected into `fatlib`, so modules referenced by `-M` or
by `use base`/`use parent` are only bundled if their `.pm` files are in those
trees; like perl, counterparts already present on the target system work either
way. Pass `--bundle-lib-all` to include every `.pm` under `--lib` regardless.

Examples:

```sh
# from this repo root, bundling a host project's boot script (full pipeline)
perl -Ilib bin/slimpack -o myapp bin/boot

# a one-liner program, pp/perl style
slimpack -o myapp -M List::Util=sum -e 'print sum(1..100)'
slimpack -o myapp -E 'say reverse qw(b a c)'
slimpack -o myapp -M strict bin/myapp          # -M also applies to scripts
```

### Minify only

`slimpack` can run just the minification pass, without tracing or bundling —
useful for stamping comments/POD/whitespace out of existing scripts:

```sh
slimpack minify script.pl            # minified script to STDOUT
slimpack --minify script.pl          # same, as a flag
slimpack minify -o out.pl script.pl  # write to a file
slimpack minify --no-rename script.pl
slimpack minify --rewrite script.pl  # also shorten keywords/operators (opt-in)
```

A standalone `minify` script with the same options is installed alongside
`slimpack`:

```sh
minify [ -o out.pl ] [ --no-rename ] [ --rewrite ] script.pl ...
```

Each file is read, run through `App::SlimPacker::process()`, and printed; the
`#!` shebang line is preserved so the output stays runnable. `-o` needs exactly
one input file; otherwise results go to STDOUT.

### Module::Pluggable inlining

If the boot script contains `use Module::Pluggable(...)`, `slimpack` reads the
`search_path` from its arguments and inlines the matching plugin classes into
the `plugins()` call, so `Module::Pluggable` never needs to load at runtime.
This is on by default; disable with `--no-inline-plugins`. Boot scripts without
`Module::Pluggable` are unaffected.

## The minifier

`App::SlimPacker::process` does PPI-based minification:

* strips comments and POD,
* collapses blank lines and intra-line whitespace,
* renames `my` variables to short names (`a`, `b`, ... `aa`, ...) to
  shrink the source — skipping names used inside strings, regexes, heredocs,
  `<...>` readlines and backticks, plus `%KEEP` names, ALL_CAPS names and
  single-character names. `local`/`our` declarations are left untouched
  (they may be package globals read via `$PKG::name`). Pass `rename => 0`
  to disable renaming via the API, or `--no-rename` on the CLI; pass
  `--no-minify` to skip the whole pass.

An additional, experimental pass (`rewrite => 1` in the API, `--rewrite` on the
CLI, off by default) shortens code into provably equivalent forms:
`foreach` -> `for`; `m/.../` -> `/.../` right after `=~`/`!~`; trailing `;`
before `}`; `$x += 1;` -> `$x++;` (only mid-block, where the value is
discarded); `$x = $x OP $y;` -> `$x OP= $y;` for `. + - * / %`; and parens
around statement-terminal builtin calls (`print($x)` -> `print $x`). The pass
is a single self-contained method with one call site, so it can be switched
off or deleted wholesale if it ever misbehaves.

Because variable renaming can silently break code, the test suite pinpoints
every edge case. Bundlers typically run `slimpack` with `rename` disabled for
`fatlib/` (core modules must not be touched) and enabled for `lib/`.

## Smaller bundles

Three techniques keep `slimpack bundle` output compact:

- Each bundled module source, and the boot program itself, is
  deflate-compressed (best level) with the core `Compress::Raw::Zlib` module,
  `MIME::Base64`-encoded, and embedded as a literal. The embedded loader (also
  core-only: `Compress::Raw::Zlib::Inflate` + `MIME::Base64::decode_base64`)
  decompresses a module lazily exactly when it is `require`d, and `eval`s the
  boot program right after the loader. This is on by default; pass
  `--no-compress` to embed the minified sources and boot program verbatim
  instead.
* Embedded module sources are emitted with the exported
  `App::SlimPacker::pack_string` instead of B::perlstring's always-double-quoted
  form. `pack_string` never perlstrings: it returns `'single-quoted'` literals
  with the content's backslashes escaped in place (`\\`), so `$ @ % "` stay raw
  — a `q<delim>` literal when that is cheaper (2 + quote-count vs 3 + delimiter
  occurrences, `q` preferred on ties). The delimiter is the rarest occurrence in
  the text among `^ ~ | ? , ; ! # & - + * / % :`, escaping its occurrences; `=`
  and `<` `>` are excluded (they break `q=...=`/`q<...>` when the text contains
  `>=`/`=>`/`<<` etc.). Even modules with `\\` sequences embed without any sigil
  escaping, whereas perlstring would have escaped every `$`, `"` and `\`.
* The tracer/injector prologue is a single-quoted heredoc template: its own
  sigils are never escaped, and the module table is spliced in at a
  `__SLPACK_ENTRIES__` placeholder. The old string-built prologue had to be
  written with `\$` everywhere; the template saves tens of bytes.

A boot program containing a `__DATA__`/`__END__` section cannot be string-eval'd
(a data section survives only in real files), so `slimpack` keeps that boot
program verbatim and warns that it was left uncompressed — modules are still
compressed. This also means a bundle's `__DATA__` stays at a line start in the
output so `<DATA>` keeps reading the bundled data.

## Fatpack vs SlimPacker

Both tools pack a program plus its module tree into one self-contained script.
The example below was run in a scratch directory on perl 5.40.1 / Debian; both
tools produced a working "Hello, world!" — only the sizes differ.

Save this as `helloworld.pl`:

```perl
package MyGreeter;
use Moo;

has name => (is => 'ro', default => sub { 'world' });

sub greet {
    my $self = shift;
    return "Hello, " . $self->name . "!\n";
}

package main;
print MyGreeter->new->greet;
```

Pack it with both tools:

```sh
fatpack pack helloworld.pl > helloworld.fatpack.pl
slimpack -o helloworld.slimpack.pl helloworld.pl
```

| | `fatpack pack` | `slimpack` |
| --- | --- | --- |
| size | 294 KB | 59 KB |
| lines | 9,929 | 27 |

Both bundles inline the modules the program loads (the `Moo` tree:
`Role::Tiny`, `Sub::Quote`, `Sub::Defer`, `Class::Method::Modifiers`, the
`Method::Generate::*` builders) and run standalone — no `Moo`, no `PERL5LIB`:

```sh
perl helloworld.fatpack.pl    # Hello, world!
perl helloworld.slimpack.pl   # Hello, world!
```

`fatpack` copies every module verbatim, comments and POD included; `slimpack`
sends them through the PPI minifier and collapses the output onto a handful of
long lines. Measured on perl 5.40.1; exact sizes vary with the module set.

## Running the tests

```sh
perl Makefile.PL
make test
```