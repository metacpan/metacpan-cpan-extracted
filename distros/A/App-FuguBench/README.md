# FuguBench

Outfit a FuguBSD checkout for a coding agent. `fugubench` installs the
dependencies that a repository names, and it makes and removes the worktrees of
a workspace. It operates the learning library, answers the Claude Code hooks,
and measures the sessions. One packed Perl file holds every verb, and it runs on
core Perl v5.34.

The program builds on the [Fugu](https://github.com/FuguBSD/Fugu) library, and
the pack carries the Fugu modules that it uses. `fugubench shim` prints a
wrapper shim that pins one release. The shim downloads that release once, holds
it to a digest, and caches it. See [INSTALL.md](INSTALL.md) to install it. The
specification in [spec/](spec/index.md) states the design.

## Commands

```sh
make deps-test   # install the runtime and the test dependencies
make check       # run every gate; run it before each commit
make test        # run every test tier
make format-fix  # fix the Perl, Markdown, JSON and YAML formatting
make dist        # build the release tarball and the packed file
```
