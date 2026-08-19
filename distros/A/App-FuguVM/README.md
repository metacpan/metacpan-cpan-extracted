# FuguVM

Install and manage OpenBSD virtual machines under QEMU.

`fuguvm` installs an OpenBSD guest without interaction, caches the installed
disk, and drives the lifecycle: boot, wait, ssh, snapshot, and shutdown. A
project describes its guests in one `.fuguvmrc` at its root. The tool exists so
a test suite can run against a real OpenBSD guest, on a Linux or Darwin host and
in CI.

FuguVM is written in Perl (v5.36) over the
[Fugu](https://github.com/FuguBSD/Fugu) library. It adds no direct CPAN
dependency of its own.

## Quick start

```sh
make deps
bin/fuguvm up && bin/fuguvm wait
bin/fuguvm ssh 'uname -a'
bin/fuguvm down
```

`make deps` installs the latest Fugu release, QEMU, and the SSH and HTTP modules
the optional features use. See [INSTALL.md](INSTALL.md) for full instructions.

## Documentation

`man fuguvm` — or `mandoc man/fuguvm/fuguvm.1 | less` from a checkout — holds
the full command, option, and exit-code reference. Each module documents its API
in a `.pod` sidecar; start with `lib/App/FuguVM.pod`.

## Development

See [CLAUDE.md](CLAUDE.md) for the development guide: style, testing,
documentation placement, and the release flow.

## License

ISC. See [LICENSE](LICENSE).
