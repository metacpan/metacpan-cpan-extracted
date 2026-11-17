---
name: alien-libssh-core
description: Use when working on the Alien::libssh distribution — its alienfile, the bundled libssh tarball, the static share build and its OpenSSL/zlib link line, or what the XS consumer Net::LibSSH depends on.
metadata:
  type: project
---

# Alien::libssh — core

Force-loaded into every `alien-libssh-*` agent before its first turn; do not
restate it in an agent body. Generic Alien::Build mechanics (probe/share, the
`PkgConfig` plugin, `Test::Alien`, `install_prop` vs `runtime_prop`) live in
skill `perl-alien`; the consumer-side Perl/C boundary in `perl-xs`. This file
holds only what is true about *this* distribution.

## What the distribution is

One job: make libssh available to Perl, over two paths.

- **system** — `plugin 'PkgConfig' => (pkg_name => 'libssh', minimum_version
  => '0.9.0')`. 0.9.0 is where the known-hosts API `Net::LibSSH` calls
  (`ssh_session_is_known_server`) appears; `t/01-alien.t` asserts the same floor.
- **share** — CMake build of `share/libssh-0.12.2.tar.xz`, no network
  (`Fetch::Local` + a `file://` `start_url` built with `Path::Tiny->cwd`).
  Offline install is a promise this distribution makes; never add a network
  `start_url`, never a second tarball.

`lib/Alien/libssh.pm` is deliberately logic-free: `use parent 'Alien::Base'`,
`$VERSION`, POD. Everything that decides anything is in `alienfile`.

`PkgConfig` does probe *and* gather for both paths — on share it reads the
`libssh.pc` the CMake install drops into the prefix. A hand-rolled `sys` gather
covers only the system path and leaves a share install with empty `cflags`.

## The share build is static, and the .pc lies about it

Three facts an implementer keeps re-discovering:

1. **Out-of-source is mandatory.** libssh's
   `MacroEnsureOutOfSourceBuild.cmake` refuses to configure inside the source
   tree; `meta->prop->{out_of_source} = 1` makes `Build::CMake` honour that.
   The `build` list is *one* cmake command (an array ref) followed by
   `%{make}` and `%{make} install` — a flat list is N separate commands.
2. **`-DBUILD_SHARED_LIBS=OFF`.** A shared `libssh.so` in the Alien prefix is
   invisible to the runtime linker, so an XS consumer compiles and then dies on
   `libssh.so.4: cannot open shared object file`. Static avoids the rpath game.
3. **The generated `libssh.pc` has no `Libs.private`.** Static linking therefore
   needs libssh's own dependencies appended: `-lcrypto -lz` (OpenSSL is the
   crypto backend, `WITH_ZLIB` defaults on). The `after 'gather'` hook in
   `alienfile` adds them to `libs` and `libs_static` — it must run *after*
   PkgConfig's gather, or the bare line wins. Missing it looks like
   `undefined symbol: EVP_PKEY_CTX_new` at `use` time in the consumer.

CMake switches beyond the plugin's defaults: `CMAKE_BUILD_TYPE=Release`,
`WITH_EXAMPLES=OFF`, `WITH_PCAP=OFF`, `WITH_GSSAPI=OFF`. Share-build
prerequisites on the host: cmake, a C compiler, pkg-config, OpenSSL headers,
zlib headers.

## Consumer

`Net::LibSSH` (`~/dev/p5-net-libssh`, XS) links at build time via
`Alien::libssh->cflags` / `->libs` and pins `Alien::libssh` in both `runtime`
and `configure`. `t/01-alien.t` mirrors that: `alien_ok` + `xs_ok` calling
`ssh_new`/`ssh_free`. Test XS, not FFI — the consumer is XS.

Work that belongs to `Net::LibSSH` becomes a ticket on that repo's karr board,
never an edit from here. Changing the bundled libssh version is its own release
and `Net::LibSSH` gets told.

## Upgrading the bundled libssh

1. `git rm` the old tarball, add the new one under `share/` — one tarball in
   the tree.
2. `alienfile`: the `start_url` filename.
3. `Changes`: under `{{$NEXT}}`, which libssh and why.
4. Version strings in `README.md`, `CLAUDE.md` and this skill move together.
5. Run the forced share build (below) before calling it done.

## Verification — both paths, every time

```bash
dzil test                                  # whatever the probe decides here
env ALIEN_INSTALL_TYPE=share  dzil test    # forced bundled build (~1 min)
env ALIEN_INSTALL_TYPE=system dzil test    # forced probe; fails loudly with no system lib
```

`prove -l t` is not a test for an Alien — nothing has been built. An unforced
`dzil test` proves one path at most. Build logs and the gathered `alien.json`
land in `_alien/`; read that file first when a consumer sees flags it did not
expect.

## Repo mechanics

- **`.claude/` is git-ignored except for a whitelist.** The root `.gitignore` ignores
  `.claude/*` and re-admits `settings.json`, `agents/`, `skills/`, `rules/` — a *new*
  directory under `.claude/` therefore stays invisible to git until it is whitelisted
  there. Verify with `git status --short` after creating one; the same applies to
  `.claude/worktrees/`, which is ignored explicitly.
- **Two kinds of skill live under `.claude/skills/`.** The ones `skilletor` installs
  (`skilletor status` lists them under *project scope*) carry a `.gitignore` holding `*`
  in their own directory — they are build artifacts, the next `skilletor sync` overwrites
  them, and editing one is forbidden. A repo-owned skill (tracked by git, no entry in
  `.claude/skilletor.json`) belongs to this repository: `alien-libssh-core` is the only
  one here, and it is the file to extend when the rules grow too long.
