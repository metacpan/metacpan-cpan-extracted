# Why staticperl is a dead end for karr (and when to abort)

staticperl builds a static perl + your app into one binary. It handles the XS
side (YAML::XS, a JSON XS backend) cleanly. It **cannot** deliver a single
static binary for karr, because karr reaches libgit2 through FFI, not XS.

## The core conflict
`Git::Libgit2::FFI` does `FFI::Platypus->new(lib => [Alien::Libgit2->dynamic_libs])`
— libgit2 is `dlopen`ed at **runtime**, never linked at build time.

- **With `--static`** (the whole point — a real single static binary): a
  statically linked glibc binary cannot reliably `dlopen`. staticperl's own POD
  warns glibc "doesn't really support [static] in a very usable fashion". Result:
  FFI cannot open libgit2 at runtime → every git operation dies.
- **Without `--static`**: the binary is dynamic against glibc and FFI can
  `dlopen` — but you must still ship `libgit2.so` and its transitive `.so`s
  beside it. That is no longer one file, i.e. no advantage over `pp`, which at
  least has a runtime-extraction mechanism for bundled libs.

Either way there is no single-static-binary that can do git. staticperl also has
**no** support for embedding + extracting a `dlopen`-loaded C library (its
`--allow-dynamic` is about XS `.so` in `@INC`, not an FFI-loaded C lib). No
documented precedent for staticperl + FFI::Platypus + a dlopen C lib exists.

## Also: no static libgit2 available anyway
`Alien::Libgit2` builds via the CMake plugin, which defaults to a shared lib
(PIC on, no `BUILD_SHARED_LIBS=OFF`), so there is only `libgit2.so*`, no
`libgit2.a`. `Alien::Base->libs_static` (note: the method is `libs_static` /
`cflags_static`, **not** `static_libs`) has no static archive to return. Static
linking of libgit2 is off the table without rebuilding it from source as static
— itself a multi-hour rabbit hole (libssh2 + openssl + zlib + zstd as `.a` too).

## Abort signals — stop and switch to pp the moment any appears
- `staticperl mkapp` aborts fatally on a `.so` (FFI::Platypus's own extension,
  or libgit2) — the sign that dynamic loading is in play.
- You confirm git goes through FFI/`dlopen` (it does).
- A `--static` build throws a `dlopen`/glibc-NSS error at runtime on first git call.
- Rebuilding perl + all transitive C libs as static under musl does not finish
  in the time budget.

If you try it at all, timebox to ~1–2h with `staticperl mkapp` (not `mkperl` —
`mkapp` is the CLI form), `--incglob '/App/karr/**'` for the dynamic classes,
and fall back to `references/pp-recipe.md` on the first abort signal.

## Sources
- staticperl POD (`--static` glibc caveat, `--allow-dynamic`, `mkapp`): https://metacpan.org/dist/App-Staticperl/view/staticperl.pod
- dlopen unreliable in static glibc binaries: https://github.com/openssl/openssl/issues/14917
- Alien::Base (`libs_static` / `dynamic_libs`): https://metacpan.org/pod/Alien::Base
- Alien::Build CMake plugin (shared-lib default): https://metacpan.org/pod/Alien::Build::Plugin::Build::CMake
