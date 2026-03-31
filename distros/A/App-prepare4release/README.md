

[![License](https://img.shields.io/badge/license-Perl%205-blue.svg)](https://github.com/neo1ite/prepare4release/blob/main/LICENSE)
[![Perl](https://img.shields.io/badge/perl-5.10%2B-blue.svg)](https://www.perl.org/)
[![CI](https://github.com/neo1ite/prepare4release/actions/workflows/ci.yml/badge.svg)](https://github.com/neo1ite/prepare4release/actions/workflows/ci.yml)
[![MetaCPAN package](https://repology.org/badge/version-for-repo/metacpan/perl%3Aapp-prepare4release.svg)](https://repology.org/project/perl%3Aapp-prepare4release/versions)
[![CPAN version](https://badge.fury.io/pl/App-prepare4release.svg)](https://metacpan.org/pod/App/prepare4release)
[![CPAN testers](https://cpants.cpanauthors.org/dist/App-prepare4release.svg)](https://cpants.cpanauthors.org/dist/App-prepare4release)

# NAME

App::prepare4release - prepare a Perl distribution for release (skeleton)

# SYNOPSIS

```perl
use App::prepare4release;
App::prepare4release->run(@ARGV);
```

# DESCRIPTION

Run from the distribution root (where `prepare4release.json` and `Makefile.PL`
live). The tool:

- Loads `prepare4release.json` and resolves `module_name` / `version` / `dist_name`
when omitted (from `Makefile.PL` and the main `.pm`).
- Patches `Makefile.PL`: `META_MERGE` (`repository` and `bugtracker` URLs), and
a marked `MY::postamble` block (between `# BEGIN PREPARE4RELEASE_POSTAMBLE` and
`# END PREPARE4RELEASE_POSTAMBLE`) that runs `pod2github` when `--github` or
`--gitlab` was used (else `pod2markdown`), then `maint/inject-readme-badges.pl`
(a standalone Perl script regenerated each run, core modules only) so `make README.md`
reapplies the same shields without depending on `App::prepare4release`. The block
is refreshed on each run to match the current `pod2*` choice; the script embeds the
frozen badge Markdown for the chosen `--github` / `--gitlab` / `--cpan` flags.
- When `--github` or `--gitlab` is set, ensures CI workflow files exist (see
["Continuous integration"](#continuous-integration)).
- Regenerates `README.md` from the `VERSION_FROM` module (`make README.md` when
`Makefile` exists, otherwise `pod2github` or `pod2markdown`), then injects
Markdown shield lines (`[![Alt](image)](link)`) into `README.md` after the first
title block (runs of `#` headings) or before `# NAME` when that is the first
heading. The `Makefile.PL` postamble runs `maint/inject-readme-badges.pl` after
`pod2github`/`pod2markdown` so badges stay in sync without a runtime dependency
on this distribution. Strips any
legacy badge block from POD after `__END__`. License and minimum Perl badges
are always added; with `--cpan`, also Repology, CPAN version, and cpants. The
GitHub Actions CI badge is added only with `--github`; the GitLab pipeline badge
only with `--gitlab` (host from `git.server`, else from `git.repo` URL, else
`gitlab.com`). License shield (always blue) uses the same key as ExtUtils::MakeMaker
(`Makefile.PL` `LICENSE`), or the type inferred from a root `LICENSE` file when
present; the link is the repository `LICENSE` blob when that file exists and
`--github` or `--gitlab` is set (branch from `git.default_branch`, default
`main`), otherwise the usual canonical license URL. Minimum Perl on the shield
comes from `min_perl_version` / `perl_min` in the JSON file, else
`Makefile.PL` `MIN_PERL_VERSION`, else the stricter of makefile and main module
(as for CI).
- Creates author tests under `xt/author/` when missing: `pod.t` ([Test::Pod](https://metacpan.org/pod/Test%3A%3APod)),
`eol.t` ([Test::EOL](https://metacpan.org/pod/Test%3A%3AEOL)), `pod-coverage.t` ([Test::Pod::Coverage](https://metacpan.org/pod/Test%3A%3APod%3A%3ACoverage)), using
[Test2::V1](https://metacpan.org/pod/Test2%3A%3AV1).
- With `--cpan`, after the steps above: ensures `LICENSE` exists. The license
_type_ is taken from `Makefile.PL` `LICENSE` (via the same snippet scan as
elsewhere in this tool); if that is missing, _perl_ (same terms as Perl 5) is
assumed. The file text is downloaded from official upstream sources (for
`perl`, the `Artistic` and `Copying` files from the Perl 5 repository; for
`apache_2`, `mit`, `gpl_3`, etc., the canonical license URLs). If a fetch
fails, a short built-in fallback is written. If `README` is missing but
`README.md` exists, writes a short stub `README` pointing readers to
`README.md`. Creates a default `MANIFEST.SKIP` when none is present (skipping
`blib/`, `cover_db/`, `nytprof/`, tarballs, `.git/`, etc.); runs
`perl Makefile.PL`, copies `MYMETA.*` to `META.*`, and `make manifest` so
`MANIFEST` matches the tree for CPAN packaging.
- Warns when any `t/*.t` or `xt/**/*.t` file starts with `use Test::More` or
`use Test::Most` (legacy assertion frameworks). Prefer [Test2::V1](https://metacpan.org/pod/Test2%3A%3AV1) or
[Test2::Tools::Spec](https://metacpan.org/pod/Test2%3A%3ATools%3A%3ASpec).

# README badge injector (`maint/inject-readme-badges.pl`)

The `MY::postamble` fragment cannot hold large, self-contained Perl _sub_s:
`ExtUtils::MakeMaker` expects that section to expand into Makefile rules, and
keeping badge logic only in `Makefile.PL` would either duplicate a lot of text
or imply loading this distribution at `make README.md` time. Instead,
`prepare4release` writes `maint/inject-readme-badges.pl`, a small, generated
program (core modules only) that strips prior shield lines and inserts the
frozen Markdown block computed on the last run (same flags as `--github` /
`--gitlab` / `--cpan`). Downstream distributions should _commit_ that file
with the rest of the tree so `make README.md` works in a clean clone and the
file is included in the CPAN tarball like any other tracked asset. Re-run
`prepare4release` after changing repository URLs, license, or badge-related
options so the script and `README.md` stay consistent. No runtime dependency on
`App::prepare4release` is added to the target module.

# CONFIGURATION FILE

File name: `prepare4release.json` (in the distribution root).

An empty file or whitespace-only file is treated as an empty JSON object `{}`.

- `module_name`

    Optional. Perl package (e.g. `My::Module`). If omitted, taken from the
    `VERSION_FROM` module's `package` line, from `NAME` in `Makefile.PL`, or from
    the first `lib/**/*.pm` file.

- `version`

    Optional. If omitted, taken from `$VERSION` in the resolved main module file.

- `dist_name`

    Optional. Defaults to `module_name` with `::` replaced by hyphens.

- `min_perl_version`

    Optional. Minimum Perl version string for the README `Perl` badge (e.g. `5.026`
    or `v5.26.0`). If omitted, `MIN_PERL_VERSION` from `Makefile.PL` is used, then
    the combined makefile/module heuristic.

- `perl_min`

    Optional alias for `min_perl_version`.

- `bugtracker`

    Optional bugtracker URL. If omitted, it is built as
    `<repository web>/issues` for the selected git host.

- `git`

    Object (optional) with:

    - `author`

        Required for `--github` or `--gitlab` unless `git.repo` is a namespace path
        (`group/project`) or a repository URL. Otherwise required to build repository
        URLs when `git.repo` is only a short name or omitted.

    - `repo`

        Repository name, `namespace/project` path, or `https://...` / `git@...`
        URL. If omitted, defaults to `perl-` plus `module_name` with `::` replaced
        by hyphens.

    - `server`

        Optional hostname (e.g. `gitlab.example.com`) for `https://` links instead of
        `github.com` / `gitlab.com`.

    - `default_branch`

        Optional branch name for `LICENSE` blob links in the README badge (default
        `main`).

- `ci`

    Optional object:

    - `apt_packages`

        Array of Debian package names (e.g. `libssl-dev`) appended to the generated
        GitHub Actions and GitLab CI `apt-get install` steps. System libraries are not
        inferrable reliably from CPAN metadata alone; list them here when XS or
        `Alien::*` needs OS packages.

# Continuous integration

When `--github` is set, if `.github/workflows/ci.yml` does not exist it is
created. It runs `prove -lr t` on an Ubuntu runner using
[https://github.com/shogo82148/actions-setup-perl|shogo82148/actions-setup-perl](https://github.com/shogo82148/actions-setup-perl|shogo82148/actions-setup-perl), with a
matrix of stable Perl releases from the stricter of `Makefile.PL`
`MIN_PERL_VERSION` and the main module's `use v5...` / `use 5...` line, up
to the latest stable Perl.

The ceiling is resolved at each run via the MetaCPAN FastAPI
`GET /v1/release/perl` (latest `perl` distribution release). The previous
`release/_search sort=version:desc` query could return ancient tarballs because
Elasticsearch sort is not Perl version order. If the request fails, a fallback
(currently `5.40`) is used. Override for tests or air-gapped use:

```
PREPARE4RELEASE_PERL_MAX=5.40 prepare4release ...
```

Matrix entries use even minor versions only (`5.10`, `5.12`, …) between the
computed minimum and maximum.

When `--gitlab` is set, if `.gitlab-ci.yml` is missing it is created with a
`parallel.matrix` over `PERL_VERSION` and the official `perl` Docker image.

Existing workflow files are never overwritten.

# System dependencies (apt)

There is no robust automatic mapping from CPAN modules to Debian packages. The
tool scans `Makefile.PL`, `cpanfile`, and `Build.PL` for `Alien::...` names
and, with `--verbose`, warns so you can add `ci.apt_packages` manually.

# ENVIRONMENT

- `PREPARE4RELEASE_PERL_MAX`

    If set, used as the matrix ceiling instead of querying MetaCPAN (useful for CI
    of this tool or offline work).

- `RELEASE_TESTING`

    If set to a true value, author tests under `xt/` may run (see
    `xt/metacpan-live.t` for a live MetaCPAN request that validates
    `fetch_latest_perl_release_version`).

# COPYRIGHT AND LICENSE

Copyright (C) by the authors.

Same terms as Perl 5 itself.
