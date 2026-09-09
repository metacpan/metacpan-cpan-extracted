# FuguVM

Install and manage OpenBSD virtual machines under QEMU, by hand or by agent.

The tool exists so a test suite can run against a real OpenBSD guest, on a Linux
or Darwin host and in CI.

`fuguvm` installs a guest without interaction, caches the installed disk, and
drives the lifecycle: boot, wait, ssh, snapshot, and shutdown.
`fuguvm image export` publishes an installed image as a file, and a `base_disk`
directive consumes that file on an other host. A project describes its guests in
one `.fuguvmrc` at its root.

FuguVM uses Perl (v5.36) over the [Fugu](https://github.com/FuguBSD/Fugu)
library. It adds no direct CPAN dependency of its own. The specification in
[spec/](spec/index.md) states the design.

## Quick start

```sh
make deps
bin/fuguvm up && bin/fuguvm wait
bin/fuguvm ssh -- uname -a
bin/fuguvm down
```

`make deps` installs the latest Fugu release, QEMU, and the SSH and HTTP modules
the optional features use. See [INSTALL.md](INSTALL.md) for full instructions.

`make deps` verifies every download. The Fugu release carries a signed `SHA256`
manifest, and `deps/KEYS.txt` declares the release key of the organization by
URL and digest. `scripts/deps` fetches that key, holds it to the digest, and
verifies the manifest with signify(1). `deps/SHA256.txt` records the digest of
each other download.

`make deps` also installs gitleaks, the tool of the secret gate. It installs the
`tool` environment before every other environment, so the gate tool is present
for each chain. The CI gate installs gitleaks with `make deps`, so one pin
serves the operator gate and the CI gate.

## Documentation

`man fuguvm` — or `mandoc man/fuguvm/fuguvm.1 | less` from a checkout — holds
the full command, option, and exit-code reference. Each module documents its API
in a `.pod` sidecar; start with `lib/App/FuguVM.pod`.

## Commands

```sh
make check          # lint + format + test + spec-check + ste-lint + gitleaks
make test           # prove -l t/{fuguvm,scripts,ci}/*.t
prove -l t/fuguvm/foo.t    # one test file
make format-fix     # auto-fix the Perl, Markdown, JSON and YAML formatting
make dist           # build the release tarball
```

`make check` runs the Markdown format gate, and prettier runs through bunx. The
operator installs bun and gitleaks, for example from Homebrew. No deps manifest
provides them.

The tests need the Fugu library on `@INC`; a local build of the sibling checkout
works too: `cpanm --local-lib=local ../Fugu/build/Fugu-*.tar.gz`.

## Releases

Push a `v<MAJOR>.<MINOR>.<PATCH>` tag, and the release workflow publishes the
tarball to GitHub Releases and to PAUSE. The rules are in
[spec/release.md](spec/release.md).

## Commit scopes

`cli`, `config`, `console`, `disk`, `guest`, `miniroot`, `mirror`, `proxy`,
`qmp`, `remote`, `state`, `spec`, `deps`, `ci`.

## License

ISC. See [LICENSE](LICENSE).
