# FuguWeb

Build a documentation website for a Perl project.

`fuguweb` renders one static site from the documentation that a Perl project
already keeps: mdoc(7) manuals, POD sidecars, and Markdown. There is no
templating language and no JavaScript. The tool runs `mandoc`, `lowdown`, and
`pod2man`, and wraps each result in one shared chrome. A project describes its
site in one `.fuguwebrc` at its root and needs no build recipe of its own.

FuguWeb is written in Perl (v5.36) over the
[Fugu](https://github.com/FuguBSD/Fugu) library, with zero CPAN dependencies.

## Quick start

```sh
make deps
bin/fuguweb init
bin/fuguweb build --out web/build
bin/fuguweb check --out web/build
```

`make deps` installs the latest Fugu release and the renderers. See
[INSTALL.md](INSTALL.md) for full instructions.

## Documentation

`man fuguweb` — or `mandoc man/fuguweb/fuguweb.1 | less` from a checkout — holds
the full command, option, and exit-code reference. Each module documents its API
in a `.pod` sidecar; start with `lib/App/FuguWeb.pod`.

## Development

See [CLAUDE.md](CLAUDE.md) for the development guide: style, testing,
documentation placement, and the release flow.

## License

ISC. See [LICENSE](LICENSE).
