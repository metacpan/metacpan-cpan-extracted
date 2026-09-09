# FuguWeb

Build a documentation website for a Perl project.

`fuguweb` renders one static site from the documentation that a Perl project
already keeps: mdoc(7) manuals, POD sidecars, and Markdown. There is no
templating language and no JavaScript.

The tool runs `mandoc`, `lowdown`, and `pod2man`, and wraps each result in one
shared chrome. A project describes its site in one `.fuguwebrc` at its root and
needs no build recipe of its own.

FuguWeb uses Perl (v5.36) over the [Fugu](https://github.com/FuguBSD/Fugu)
library, with zero CPAN dependencies. The specification in
[spec/](spec/index.md) states the design.

## Quick start

```sh
make deps
bin/fuguweb init
bin/fuguweb build --out web/build
bin/fuguweb check --out web/build
```

`make deps` installs the latest Fugu release and the renderers. See
[INSTALL.md](INSTALL.md) for full instructions.

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

`man fuguweb` — or `mandoc man/fuguweb/fuguweb.1 | less` from a checkout — holds
the full command, option, and exit-code reference. Each module documents its API
in a `.pod` sidecar; start with `lib/App/FuguWeb.pod`.

## License

ISC. See [LICENSE](LICENSE).
