# Guidance for coding agents

## Start here

Read [README.md](README.md) for the user's JSON format and current limitations,
then [CONTRIBUTING.md](CONTRIBUTING.md) for architecture and safe build commands.
This is a Perl CPAN distribution that generates a static links page. There is
no application server or Node build.

## Find the right code

- `bin/linksite`: CLI parsing and entry point.
- `lib/App/LinkSite.pm`: JSON loading in `ADJUST`, object construction,
  Template Toolkit setup, traversal, and file copying in `run`.
- `lib/App/LinkSite/{Site,Link,Section,Social}.pm`: data and rendering helpers.
  `Site` owns JSON-LD; `Link` and `Social` return HTML fragments.
- `src/index.html.tt` and `src/css/style.css`: page layout and styling.
- `t/`: Test::More suite; `t/links.json` is the common fixture.
- `example/`: user configurations and a consumer deployment workflow.
- `Makefile.PL`, `MANIFEST`: packaging and prerequisites.
- `META.json`: committed, generated metadata used to bootstrap configure
  dependencies on clean checkouts; regenerate it from Makefile.PL.

Use the existing Feature::Compat::Class style (`class`, `field`, `method`,
`ADJUST`) and preserve support for Perl 5.26 unless the task changes that
requirement. Object::Pad is part of the compatibility setup.

Windows CI uses Strawberry Perl's bundled toolchain and the make program
reported by Perl's Config. Keep all supported versions in the matrix and
preserve independent failure logs. The setup action's module cache is
disabled because this distribution has no cpanfile to key it on.
Use temporary script files for subprocess test helpers instead of multiline
`perl -e` arguments, and check that child tests actually emit a test plan.

## Verify changes

From the repository root, run `prove -Ilib -v t` and `git diff --check`.
For a fresh dependency setup, use the commands in CONTRIBUTING.md.
The prerequisite regression configures a temporary distribution and checks
that generated metadata retains configure, runtime, and test dependencies,
including minimum versions, and agrees with committed bootstrap metadata.
`t/basic.t` has a TODO source-directory check that may fail without failing
the suite.

The suite checks constructors/readers and end-to-end CLI builds in temporary
directories. `t/cli.t` covers file selection, help/version, and option errors
using the checkout's templates. `t/analytics.t` checks rendered GA4 IDs and
disabled analytics. `t/template-paths.t` checks nested template output and
asset copying. `t/metadata.t` checks attribute escaping and preserves visible
description HTML. For template or copy changes, also inspect output.
`t/utm.t` covers tracking settings, URL preservation, and UTF-8 text. JSON
and templates are read and generated pages written as UTF-8; preserve that
encoding through the build pipeline.
Source-template smoke builds must pass an explicit absolute
`src`; installed File::ShareDir assets otherwise take precedence over the
checkout even with `-Ilib`. CONTRIBUTING.md contains a complete recipe.

## Avoid local data loss and misleading checks

- The default output is `docs/`, which contains tracked documentation in
  this repository. Use a temporary `out` when exercising generation.
- Keep test inputs and outputs in temporary directories. The default-file
  test restores its working directory even on exceptions; its isolation
  regression checks that a caller's existing `links.json` is preserved.
- Image and `CNAME` inputs are relative to the working directory, regardless
  of the JSON file's location. Use content fixtures in a temporary directory.
- Output includes the original JSON and is not cleaned between builds.
- Ignored `Makefile`, `MYMETA.*`, `blib/`, and tarballs may be stale. Edit
  source files, not generated copies, and do not assume `blib` is current.
- `docker/build` builds from a published CPAN release and pushes Docker Hub
  tags. Do not use it as a local test or run it unless publication is requested.

## Behavior worth preserving or deliberately changing

- Missing social handles inherit the site handle. An explicit social URL
  overrides URL generation; adding a service also requires a name and icon.
- `new` is the Link constructor parameter, and `is_new` is its reader.
- UTM tracking is opt-in for content links. Per-link objects merge over global
  settings; false/null opts out. Existing URL parameters win. `tracked_link`
  is the click destination, while `link` and JSON-LD remain canonical. Social
  URLs are unchanged. Declare URI and URI::Escape as runtime prerequisites.
  Default `utm_content` is a lowercase title slug with non-letter/number
  runs replaced by hyphens. Empty slugs are omitted; explicit settings or
  existing URL parameters take precedence.
- Only non-empty sections activate section layout. Top-level links then
  appear under “Other links”; otherwise the display is a flat list.
- `Site::all_links` returns a list with top-level links first, followed by
  section links, and feeds JSON-LD's `relatedLink`.
- Template files lose only the final `.tt` suffix and retain their path
  relative to `src`; ordinary assets retain their relative paths too.
  Directories ending in `.tt` remain directories.
- Open Graph and page-description metadata attributes are HTML-escaped in
  double quotes. The visible description retains simple HTML and converts
  newlines to `<br>`; keep those contexts separate when changing escaping.
- JSON input is trusted and other HTML is not generally escaped. Review
  effects on descriptions, link fragments, attributes, and JSON-LD when
  changing rendering or escaping.

Known issues are recorded in CONTRIBUTING.md, including root-relative asset
URLs. Do not mistake those limitations for working features. Fix them when
in scope and update their documentation and coverage.

## Keep documentation and packaging aligned

`README.md` is the canonical user guide and the source for the active
documentation website. `docs/README.md` points to it. The documentation
workflow and `example/build.yml` deploy different things.
The documentation workflow deploys only from `main`; keep pull requests and
manual runs on other branches from deploying to Pages.
The consumer workflow watches JSON, images, `CNAME`, and its installed path
on `main`. Keep its push branch filter and build job guard aligned so manual
runs on feature branches also skip deployment.

Update examples and user docs for configuration or CLI changes. Update
`Changes.md` for behavior changes. Declare dependencies in `Makefile.PL`
using the appropriate configure, runtime, or test phase; it is the single
dependency source for this CPAN distribution. Include new distribution files
in `MANIFEST`. For packaging changes, inspect a `make dist` archive and run
the tests from an extracted temporary copy; include the full test suite,
fixtures, and configuration examples. Regenerate committed `META.json` after
changing dependencies or the release version; CONTRIBUTING.md describes the
`make distmeta` workflow.
Follow Semantic Versioning (SemVer), using `MAJOR.MINOR.PATCH`. Assess changes
to the documented JSON format, CLI, and public Perl API using the
[versioning policy](CONTRIBUTING.md#versioning), including its `0.x.y` caveat.
Keep version declarations in the main module and all four model modules
aligned when preparing a release; do not bump them merely for routine
documentation work.
