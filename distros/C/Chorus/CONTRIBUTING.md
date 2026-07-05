# Contributing to Chorus

Thank you for your interest in Chorus!
Contributions of any kind are welcome: bug reports, documentation improvements,
new examples, or engine enhancements.

---

## Table of contents

- [Reporting bugs](#reporting-bugs)
- [Requesting features](#requesting-features)
- [Submitting a pull request](#submitting-a-pull-request)
- [Development setup](#development-setup)
- [Running the tests](#running-the-tests)
- [Coding conventions](#coding-conventions)
- [Commit message format](#commit-message-format)
- [Branch workflow](#branch-workflow)
- [Documentation](#documentation)

---

## Reporting bugs

Please open an [Issue](https://github.com/civorra/Chorus/issues) on GitHub,
or file a ticket on the CPAN RT queue:
<https://rt.cpan.org/Dist/Display.html?Name=Chorus>

A good bug report includes:

- Perl version (`perl -v`)
- Chorus::Engine version (`perldoc -l Chorus::Engine`)
- A minimal, self-contained script that reproduces the problem
- The actual output vs. the expected output

---

## Requesting features

Open an [Issue](https://github.com/civorra/Chorus/issues) with the label
`enhancement`. Describe the use case first — a concrete scenario is more useful
than an abstract feature description.

---

## Submitting a pull request

1. Fork the repository and clone your fork.
2. Create a branch from `devel` (see [Branch workflow](#branch-workflow)).
3. Make your changes — one logical change per commit.
4. Add or update tests in `t/` if applicable.
5. Run the full test suite (see [Running the tests](#running-the-tests)).
6. Push your branch and open a pull request **targeting `devel`**, not `main`.

Please keep pull requests focused. A PR that mixes unrelated changes is harder
to review and slower to merge.

---

## Development setup

The only build tool required is `ExtUtils::MakeMaker`, which ships with Perl.

```sh
git clone https://github.com/civorra/Chorus.git
cd Chorus
perl Makefile.PL
make
make test
```

Runtime dependencies are minimal and available on any standard CPAN mirror:
`YAML`, `Scalar::Util`, `Digest::MD5`.

To install them if needed:

```sh
cpanm --installdeps .
```

---

## Running the tests

```sh
make test
```

All tests must pass before submitting a pull request.

To run author tests (POD syntax check):

```sh
AUTHOR_TESTING=1 make test
```

To run a single test file:

```sh
perl -Ilib t/10-Frame-get.t
```

---

## Coding conventions

- **Perl 5.006+** — classic style, no Moose or Moo.
- Every module must start with `use strict; use warnings;`.
- No external dependencies beyond those already listed in `Makefile.PL`.
- YAML rules use English keys by default (`RULE`, `FIND`, `ACTION`, `PREMISES`).
  Use the French form (`REGLE`, `CHERCHER`, `EFFET`, `PREMISSES`) only when the
  corpus processed is in French. The sub-keys `attribut` and `filtre` are invariant.
- New public methods must be documented in POD.
- Maintain compatibility with Perl 5.006+; avoid syntax or modules introduced
  in later versions without a stated minimum-version bump.

---

## Commit message format

Use the conventional commit format:

```
type: short description in imperative mood

Optional longer explanation.
```

Common types: `fix`, `feat`, `docs`, `chore`, `refactor`, `test`.

Examples:

```
fix: prevent infinite loop when TERMINAL rule fires on empty frame
feat: add fselect() as a filtered variant of fmatch()
docs: document _MAX_CYCLES in Chorus::Engine POD
chore: regenerate MANIFEST
```

- Keep the subject line under 72 characters.
- No period at the end of the subject line.
- No `Co-Authored-By` or tool-generated footers.

---

## Branch workflow

| Branch | Purpose |
|---|---|
| `devel` | Active development — **target for all pull requests** |
| `main` | Mirrors the latest CPAN release |

Never open a pull request against `main` directly.

---

## Documentation

User-facing documentation lives in `doc/en/` (English) and `doc/fr/` (French).
API documentation is inline POD in `lib/`.

If your change affects the public API or the YAML DSL, please update both
the relevant POD section and the corresponding `doc/en/` Markdown file.
