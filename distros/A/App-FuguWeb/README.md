# FuguWeb

Build a documentation website for a Perl project. `fuguweb` renders one static
site from the documentation that a Perl project already keeps: mdoc(7) manuals,
POD sidecars, and Markdown. There is no templating language and no JavaScript.

The tool runs `mandoc`, `lowdown`, and `pod2man`, and wraps each result in one
shared chrome. A project describes its site in one `.fuguwebrc` at its root.
FuguWeb uses Perl (v5.36) over the [Fugu](https://github.com/FuguBSD/Fugu)
library. See [INSTALL.md](INSTALL.md) to install it, and `man fuguweb` for the
reference.

## Commands

```sh
make deps        # install Fugu and the renderers
make check       # run every gate; run it before each commit
make test        # run every test tier
make format-fix  # fix the Perl, Markdown, JSON and YAML formatting
make dist        # build the release tarball
make install     # install the binary, the modules, and the manual
```
