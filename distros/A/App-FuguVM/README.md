# FuguVM

Install and manage OpenBSD virtual machines under QEMU, by hand or by agent. The
tool exists so a test suite can run against a real OpenBSD guest, on a Linux or
Darwin host and in CI.

`fuguvm` installs a guest without interaction, caches the installed disk, and
drives the lifecycle: boot, wait, ssh, snapshot, and shutdown. A project
describes its guests in one `.fuguvmrc` at its root. FuguVM uses Perl (v5.36)
over the [Fugu](https://github.com/FuguBSD/Fugu) library. See
[INSTALL.md](INSTALL.md) to install it, and `man fuguvm` for the reference.

## Commands

```sh
make deps        # install Fugu, QEMU, and the optional modules
make check       # run every gate; run it before each commit
make test        # run every test tier
make format-fix  # fix the Perl, Markdown, JSON and YAML formatting
make dist        # build the release tarball
make install     # install the binary, the modules, and the manual
```
