# App::SlimPacker

Fatpack-style bundler with PPI-based minification for standalone Perl scripts.

`slimpack` turns a boot script plus its module tree into a single
self-contained, minified `#!/usr/bin/perl` script. By default it runs the whole
`fatpack` pipeline internally (via `App::FatPacker`'s methods):

1. **trace** the boot script (compile it, without running it) to discover
   which modules it loads,
2. **drop** core modules with a `Module::CoreList` filter,
3. **resolve** the surviving modules' `.packlist` files,
4. **copy** their sources into a temporary `fatlib/`,
5. **minify** each reachable `.pm` from `lib/` plus every `.pm` from `fatlib/`
   with `App::SlimPacker::Minify`, and emit the final script — shebang,
   module loader, minified modules, boot script.

Each step is also available as its own subcommand (see Usage). It is
project-agnostic: no search paths or class layouts are baked in.

## Layout

| File | Purpose |
| --- | --- |
| `lib/App/SlimPacker.pm` | Bundling helpers (`pack_string`, `inline_plugins`, `perl_switches`) |
| `lib/App/SlimPacker/Minify.pm` | The minifier (`process`, `minify_file`, `collect_bundle_globals`, ...) |
| `bin/slimpack` | CLI bundler that assembles the final script |
| `bin/minify` | Standalone minify-only front-end (same minification pass, no bundling) |
| `t/minify.t` | Tests for the minifier (whitespace rules, variable renaming) |
| `t/minify-module.t` | Tests for the `App::SlimPacker::Minify` API |
| `t/rewrite.t` | Tests for the `--rewrite` pass and bundle-wide renaming |
| `t/syntax.t` | Compiles every module and script |
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

The default command runs the whole pipeline above; each step is also exposed
as a subcommand with the same arguments as `fatpack`:

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
  --fatlib DIR         fatpacked module tree  (default fatlib; pack uses a temp one)
  --no-minify          bundle modules and boot program verbatim
  --rename-vars / --no-rename-vars  rename my variables (default on)
  --rename-subs / --no-rename-subs  rename sub/method names (default on)
  --rename-modules / --no-rename-modules  rename bundled package names
                        (default on)
  --rename-exports / --no-rename-exports  also rename names in import/export
                        lists and can() strings (default on)
  --rewrite, --no-rewrite  additionally shorten keywords/operators (opt-in,
                        experimental; see "The minifier" below)
  --compress, --no-compress  deflate module sources and the boot program
                        (default on; --no-compress embeds verbatim; see
                        "Smaller bundles")
  --binary, --no-binary  store the compressed sources as escaped binary
                        (default, smallest) or as base64 with --no-binary,
                        which keeps the bundle a plain text file
  --shebang LINE       shebang for the bundle (default: the boot script's own;
                        without one, #!/usr/bin/env perl)
  --no-inline-plugins  keep Module::Pluggable as a runtime dependency
  --bundle-lib-all     include every .pm under --lib, even if not referenced
                       from the boot program (default: only statically-reachable
                       lib modules are bundled; fatlib is always fully included)
  --include MODULE     also bundle MODULE and what it loads (repeatable;
                       * and ? are wildcards)
  --exclude MODULE     never bundle MODULE (repeatable; * and ? are wildcards)
```

Module discovery resolves the static dependency tree from `--lib` and fully
includes what `pack` collected into `fatlib`, so modules referenced by `-M` or
by `use base`/`use parent` are only bundled if their `.pm` files are in those
trees; like perl, counterparts already present on the target system work either
way. Pass `--bundle-lib-all` to include every `.pm` under `--lib` regardless.

Modules loaded in ways slimpack can't see, such as a plugin picked at runtime,
can be added with `--include`. Optional parts of a dependency the program never
uses can be left out with `--exclude`. Moo's Moose support is left out without
it: `Moo::HandleMoose` is only bundled when Moose is in the bundle anyway.

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
slimpack minify --no-rename-vars script.pl    # keep variable names
slimpack minify --no-rename-subs script.pl    # keep sub/method names
slimpack minify --rewrite script.pl           # also shorten keywords/operators (opt-in)
slimpack bundle --no-rename-modules boot.pl   # keep package/class names as-is
slimpack bundle --no-rename-exports boot.pl   # keep qw() import/export names
```

A standalone `minify` script with the same options is installed alongside
`slimpack`:

```sh
minify [ -o out.pl ] [ --rename-vars / --no-rename-vars ] [ --rename-subs / --no-rename-subs ] [ --rewrite / --no-rewrite ] script.pl ...
```

Each file is minified and printed, shebang preserved. `-o` needs exactly one
input file; otherwise results go to STDOUT.

### Module::Pluggable inlining

If the boot script contains `use Module::Pluggable(...)`, `slimpack` reads the
`search_path` from its arguments and inlines the matching plugin classes into
the `plugins()` call, so `Module::Pluggable` never needs to load at runtime.
This is on by default; disable with `--no-inline-plugins`. Boot scripts without
`Module::Pluggable` are unaffected.

## The minifier

`App::SlimPacker::Minify::process` does PPI-based minification:

* strips comments and POD, collapses blank lines and intra-line whitespace.
* renames `my` variables to short names (`a`, `b`, ... `aa`, ...), ALL_CAPS
  lexicals included. Never renamed: Perl special variables (`%ENV`, `@INC`,
  `%SIG`, `@ARGV`, `$VERSION`, `@ISA`, `$AUTOLOAD`, ...), control variables
  (`$^X`, `%^H`, `${^...}`), single-character names, and `local`/`our`
  declarations (they may be package globals read via `$PKG::name`).
  Interpolating strings and regexes are rewritten to match — `"$name"`,
  `_${name}`, heredocs, readlines, backticks, `m//`, `s///`, `qr//` — with
  braced `${name}` kept braced, delimiters paired/nested and `\Q...\E` still
  interpolating. Left alone: escaped dollars (`"\$name"`), non-interpolating
  `m'...'`, and regex code regions (`(?{ ... })`, `s///e` replacements).
  Disable with `--no-rename-vars` (API: `rename_vars => 0`; the legacy
  `--no-rename` spelling still works); `--no-minify` skips the whole pass.
* renames sub and method names (on by default): definitions, plain calls,
  `->method` chains, `&name`/`\&name` code-refs and qualified `Pkg::name(...)`
  calls shrink in step. Names Perl dispatches by string stay verbatim:
  keywords and builtins, magic methods (`new`, `DESTROY`, `AUTOLOAD`,
  `import`, `can`, `isa`, `tie` methods, `TO_JSON`, `STORABLE_*`), strings
  passed to `->can()` and friends, hash keys, label and `goto` targets.
  Methods reached only through `$obj->can('method')` plus a string stop
  matching after the rename; pack those with `--no-rename-subs` (API:
  `rename_subs => 0`).

An additional pass (`rewrite => 1` in the API, `--rewrite` / `--no-rewrite` on
the CLI, off by default) shortens code into provably equivalent forms:
`foreach` -> `for`; `m/.../` -> `/.../` right after `=~`/`!~`; trailing `;`
before `}`; `$x += 1;` -> `$x++;` (only mid-block, where the value is
discarded); `$x = $x OP $y;` -> `$x OP= $y;` for `. + - * / %`; and parens
around statement-terminal builtin calls (`print($x)` -> `print $x`). The pass
is a single self-contained method with one call site, so it can be switched
off or deleted wholesale if it ever misbehaves.

When `bundle`ing, renaming becomes bundle-aware — the whole dependency graph
is in one file, so one shared `name => short` map (from
`collect_bundle_globals()`) applies everywhere; single-file `minify` renames
each file independently and only the safe local forms. Bundle-wide:

* `--rewrite` also renames `our`-declared package globals consistently
  (`$hits` and `$App::Keeper::hits` become the same short name). `$VERSION`,
  `$AUTOLOAD`, `@ISA`, ALL_CAPS and single-character names are never renamed;
  a global is left alone if its name appears in a string or as a lexical
  anywhere in the bundle, and short names avoid every bundle lexical, string
  and reserved name.
* `--rename-exports` (on by default) shrinks the export/import protocol in
  step with the `sub` definitions: `use Pkg qw(...)`, `our @EXPORT_OK`,
  `can('method')` et al. Safe only because the bundler has seen every module
  and its strings.
* `--rename-modules` (on by default) renames the bundled packages' namespace
  components: `package App::Keeper::Config` becomes `package bk::bl::Config`,
  with `use` statements, qualified calls and interpolated globals following.
  The loader answers `%INC` requests with the same map; a package never
  declared in the bundle is never renamed.

## Smaller bundles

Three techniques keep `slimpack bundle` output compact:

- Module sources and the boot program are deflate-compressed (best level,
  core `Compress::Raw::Zlib`); the core-only loader inflates each module
  lazily when it is `require`d, then `eval`s the boot program.
  `--no-compress` embeds the minified sources verbatim instead.

  The compressed bytes are stored as escaped binary: only CR, LF, ctrl-Z,
  backslash, the quote and the `\x01` escape byte are escaped (~2% overhead),
  so the bundle runs everywhere, Windows text-mode reads included. The file
  itself is binary — move it byte-for-byte; don't re-save it from an editor or
  paste it. `--no-binary` stores base64 instead: ~25% bigger, but a plain text
  file that survives diff, mail and copy-paste. Neither form is readable; to
  inspect a bundle, use `--no-compress`.
* Verbatim (`--no-compress`) sources are emitted with the exported
  `App::SlimPacker::pack_string`: `'single-quoted'` or `q<delim>` literals
  (whichever is cheaper) that leave `$ @ % "` raw, where `B::perlstring` would
  escape every `$`, `"` and `\`. The `q` delimiter is the rarest character in
  the text among `^ ~ | ? , ! # & - + * / % :` (`;`, `=`, `<`, `>` are
  excluded: `q;...;` is a syntax error before perl 5.18, and
  `=>`, `>=`, `<<` would break the literal).
* The loader is a single-quoted heredoc template, so its own sigils are never
  escaped; the module table is spliced in at a `__SLPACK_ENTRIES__`
  placeholder.

A boot program's `__DATA__`/`__END__` section can't survive string-eval, so it
is split off and bundled as its own compressed entry; the loader installs an
in-memory handle over it as `*main::DATA` before the boot program runs (an
already-open `main::DATA` is left alone, with a warning). Reads, `seek`,
`tell` and `eof` work as before; `fileno(DATA)` is -1, and `tell` counts from
the start of the data, not the file.

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

| | `fatpack pack` | `slimpack` | `slimpack --no-binary` | `slimpack --no-compress` |
| --- | --- | --- | --- | --- |
| size | 110 KB | 25 KB | 32 KB | 55 KB |

Both bundles inline the modules the program loads (the `Moo` tree:
`Role::Tiny`, `Sub::Quote`, `Sub::Defer`, `Class::Method::Modifiers`, the
`Method::Generate::*` builders) and run standalone — no `Moo`, no `PERL5LIB`:

```sh
perl helloworld.fatpack.pl    # Hello, world!
perl helloworld.slimpack.pl   # Hello, world!
```

`fatpack` copies every module verbatim, comments and POD included; `slimpack`
minifies and compresses them (see "Smaller bundles"). `--no-compress` trades
size for readable sources. Measured on perl 5.40.1 with Moo 2.005005; exact
sizes vary with the module set.

## Running the tests

```sh
perl Makefile.PL
make test
```