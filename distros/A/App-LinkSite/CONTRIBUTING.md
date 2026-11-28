# Developing App::LinkSite

App::LinkSite is a CPAN distribution and a static-site generator. Start with
[README.md](README.md) for the input format and user workflow. This guide
describes the implementation and how to verify changes locally.

## Repository map

| Path | Responsibility |
| --- | --- |
| `bin/linksite` | CLI option parsing and entry point. |
| `lib/App/LinkSite.pm` | Reads JSON, builds model objects, configures Template Toolkit, and writes the site. |
| `lib/App/LinkSite/Site.pm` | Site fields, section detection, aggregation of links, and JSON-LD. |
| `lib/App/LinkSite/Link.pm` | Link fields and rendering a Bootstrap list item. |
| `lib/App/LinkSite/Section.pm` | Section title, link objects, and `has_links`. |
| `lib/App/LinkSite/Social.pm` | Supported services, profile URL construction, and Font Awesome anchor rendering. |
| `src/index.html.tt` | Page structure, metadata, analytics, section layout, and CDN dependencies. |
| `src/css/style.css` | Local styles, body color defaults, and the “New!” marker. |
| `t/` | Tests using Test::More and a JSON fixture. |
| `example/` | Flat and sectioned configurations, plus a consumer's Pages workflow. |
| `docker/` | Image definition and a build-and-push helper for published CPAN versions. |
| `Makefile.PL`, `MANIFEST` | Distribution metadata, dependencies, and packaged files. |
| `.github/workflows/perltest.yml` | Reusable CI jobs for tests, coverage, Perl::Critic, and complexity. |
| `.github/workflows/static.yml` | Publishes this project's README as its documentation website. |
| `docs/` | Tracked documentation-site files from the Jekyll setup; also the default output path when generating a link site. |

There is no application server, database, frontend build pipeline, or Node
dependency tree. Runtime HTML uses Bootstrap and Font Awesome from CDNs.

## Local setup

Use Perl 5.26 or later and a CPAN client. From the repository root:

```sh
cpanm --installdeps .
perl Makefile.PL
make
make test
```

For a quick run against source modules without rebuilding:

```sh
prove -Ilib -v t
```

`Makefile.PL` is the source for CPAN metadata and all dependency declarations:
`CONFIGURE_REQUIRES`, `PREREQ_PM`, `TEST_REQUIRES`, and `MIN_PERL_VERSION`.
It uses File::ShareDir::Install to install `src/` as distribution share files.
`cpanm --installdeps .` reads this distribution's requirements without a
separate hand-maintained dependency file. Committed `META.json` lets a clean
checkout discover configure dependencies, including File::ShareDir::Install,
before running Makefile.PL. Regenerate this metadata from Makefile.PL when
dependencies or the release version change: run `make distmeta`, then copy
`META.json` from the generated distribution directory back to the repository
root. The directory name includes the current version, for example
`App-LinkSite-0.2.0/`.

`t/prerequisites.t` configures a fresh temporary distribution and checks
that generated metadata retains the required modules and minimum versions,
and that committed bootstrap metadata matches it. Edit Makefile.PL first;
do not maintain a separate dependency list in META.json by hand.

`Makefile`, `MYMETA.*`, `blib/`, `pm_to_blib`, and release tarballs are generated
and ignored by Git. They may already exist and may be stale.

The classes use Feature::Compat::Class and `field`, `:param`, `:reader`,
`ADJUST`, and `method` syntax. Object::Pad supplies compatibility on older
Perls. Follow the existing class style rather than introducing a second
object system. CI currently declares Perl 5.26 through 5.40 in two-version
steps; check the workflow when changing language features or dependencies.

Windows CI uses Strawberry Perl with its bundled compiler and libraries.
The earlier custom Perl/toolchain combination built XS::Parse::Keyword
with an incompatible interpreter ABI on Perl 5.40, which prevented
Object::Pad from configuring. The Windows matrix uses PowerShell, disables
the setup action's module cache (which is keyed on a cpanfile), and invokes
the make program reported by Perl's Config, supporting both dmake and gmake.
Fail-fast is disabled for these jobs so all eight Perl versions finish.
Failed installations upload version-specific CPAN build logs from
`PERL_CPANM_HOME`. Linux and macOS continue using the shared test workflow.
Subprocess-based tests write their helper programs to temporary scripts;
multiline `perl -e` arguments do not execute reliably on Windows.

## Build lifecycle

1. `bin/linksite` parses options and normally calls
   `App::LinkSite->new(...)->run`.
2. Construction immediately reads UTF-8 JSON and decodes it in `ADJUST`. It
   takes `ga4` from JSON, creates Template Toolkit with `src` as `INCLUDE_PATH`
   and `out` as `OUTPUT_PATH`, and exposes `ga4` and `version` to templates.
3. Content links inherit top-level `utm` settings unless their own `utm`
   disables them; per-link objects merge over the global object. Missing
   social handles inherit the top-level `handle` using `//=`. Social,
   link, and section data become `Social`, `Link`, and `Section` objects.
   A `Site` object collects these and the profile fields.
4. `run` creates `out` and traverses `src` with File::Find and `no_chdir`.
   Each `.tt` file is processed with the additional template variable `site`.
   Output names remove only the final `.tt` suffix, preserving the path
   relative to `src`: `news/index.html.tt` renders as `out/news/index.html`.
   Templates are read and output pages written as UTF-8. Other files and
   directories preserve their relative paths, including directory names
   ending in `.tt`.
5. The two configured images are copied from the working directory's `img/`
   into `out/img/`. A working-directory `CNAME`, if present, is copied next.
   Finally the original input file is copied into `out` under its basename.

Construction can fail before `run` because JSON loading and object creation
happen in `ADJUST`. A failure during rendering or copying can leave partial
output. Builds overwrite matching files but do not clean obsolete files.
There is no schema validator or general HTML-escaping layer. Open Graph and
page-description metadata attributes use HTML escaping with double quotes;
the visible description still accepts simple HTML and converts newlines to
`<br>`. Metadata retains description markup as text rather than rendering it.

### Constructor and path behavior

| Parameter | Default / behavior |
| --- | --- |
| `file` | `links.json`, relative to the working directory unless absolute. |
| `src` | Installed `File::ShareDir::dist_dir('App-LinkSite')`, if found; otherwise `$FindBin::Bin/../src`. |
| `out` | `docs`, relative to the working directory unless absolute. |
| `ga4` | Accepted as a parameter but overwritten by the input's `ga4` or `''`. |
| `site` | Accepted as a parameter but replaced by the site constructed from JSON. |

The installed share directory takes precedence even when loading modules
with `-Ilib`. The fallback is relative to the running script, not this module
or necessarily the current directory. Use an explicit absolute `src` for
reliable source-tree template testing. A custom `file` does not relocate
image or `CNAME` lookups to that file's directory.

### Model and rendering details

`Site::has_sections` is true only if at least one section has links. The
template then renders non-empty sections followed by any top-level links
under “Other links”. Otherwise it renders the top-level list without
section headings.

`Site::all_links` returns a Perl list, starting with top-level links and then
each section's links. `json_ld` uses this order for `relatedLink`, even though
the sectioned HTML displays top-level links last. It also emits a WebPage
with a Person `mainEntity` and social URLs in `sameAs`.

`Link::mk_link` returns the entire `<li>` containing the anchor and optional
subtitle. The constructor parameter `new` is stored in `$new_link` and read
through `is_new`; CSS renders the visible label for the `new-link` class.
`Link::tracked_link` adds opt-in UTM parameters to absolute HTTP(S) click
destinations; `link` and JSON-LD remain canonical. An empty UTM object enables
source `linksite`, medium `referral`, campaign `profile`, and content from a
lowercase title slug. Supplied values override those defaults, and null/empty
parameter values are omitted.
Existing query keys win, including percent-encoded keys and bare parameters.
URI is used for URL parsing and URI::Escape for UTF-8 value encoding; appended
parameters do not rewrite existing query bytes. Only tracked anchors get
attribute escaping in this path. Social profile URLs are not tagged.

`Social::mk_social_link` returns an explicit `url` first. Otherwise it finds
the service pattern, substitutes `XXXX` for subdomain-based profiles, or
appends the handle. An unknown service warns and returns no generated URL.
`mk_social_icon` uses the service's display name and Font Awesome brand key,
so a custom URL alone does not make a new service fully supported.

## Safely preview source changes

Do not run a default build in the repository root: it writes into the tracked
`docs/` directory. This recipe uses a temporary content directory, explicitly
selects the checkout's templates, and needs no image files:

```sh
repo_dir="$PWD"
preview_dir=$(mktemp -d)
cp t/links.json "$preview_dir/links.json"
cd "$preview_dir"
perl -MJSON -e 'local $/; my $d = decode_json(<>); $d->{image} = ""; $d->{og_image} = ""; delete $d->{ga4}; print encode_json($d)' links.json > preview.json
perl -I"$repo_dir/lib" -MApp::LinkSite -e 'App::LinkSite->new(file => "preview.json", src => $ARGV[0], out => "public")->run' "$repo_dir/src"
python3 -m http.server 8000 --directory public
```

Visit `http://localhost:8000/`. Stop the server with Ctrl-C and return to
`repo_dir` before further repository commands. `LINKSITE_DEBUG=1` enables
the builder's path/copy diagnostics on stderr. Output includes a build
timestamp, so byte-for-byte HTML comparisons need to account for that.

## Verification and test gaps

The suite covers model construction/readers, colors, sections, link
aggregation, default paths,
and the driver's custom input parameter. `t/basic.t` marks its source-path
expectation as TODO because an installed share directory can take precedence.
That TODO failure is not a suite failure.

`t/file-parameter.t` uses a temporary content directory for the default input
filename and restores the caller's working directory, including on an
exception. `t/file-parameter-isolation.t` runs it from a separate content
directory and checks that a pre-existing `links.json` remains byte-for-byte
unchanged. Keep tests that create input/output files isolated this way.

`t/cli.t` exercises actual CLI generation from default and custom input files,
including paths with spaces and the filename `0`. It checks rendered input,
CSS, and the published JSON, along with help/version behavior and option
errors. Its temporary runner selects the checkout's templates through
File::ShareDir so an installed distribution cannot mask template changes.
`t/analytics.t` builds pages with explicit checkout templates and temporary
inputs/outputs. It checks that the GA4 loader and configuration use the same
supplied ID, and that omitted, empty, or null IDs emit no analytics code.
`t/template-paths.t` uses a temporary source tree to check nested templates,
matching basenames in different directories, final-suffix removal, and
unchanged copying of text/binary assets and input JSON.
Its template fixtures use raw writes for consistent LF line endings across
platforms; Template Toolkit reads template bytes without newline conversion.
`t/metadata.t` renders the checkout's page template in memory and checks
metadata attribute escaping for apostrophes, double quotes, ampersands, and
markup, alongside the visible description's HTML and newline handling.
It accepts literal or entity-encoded apostrophes across Template Toolkit
versions; both are valid inside double-quoted attributes.
`t/utm.t` checks opt-in defaults, title slugs and content overrides,
global/per-link inheritance, opt-out, existing queries/fragments, UTF-8
encoding and rendering, unsupported URL
schemes, invalid settings, canonical JSON-LD, and unchanged copied input.
Most social URL patterns and detailed HTML rendering remain untested; a
passing suite alone will not catch every template regression.

For rendering or asset changes, also build into a temporary directory and
check `index.html`, `css/style.css`, configured images, copied input, and
`CNAME` where applicable. Exercise both a flat list and sections with an
empty section and top-level links. For social-service changes, check the URL,
display name, icon key, inherited handle, and explicit URL override. Add
focused regression tests when changing behavior that is not covered.

Before finishing a change, run:

```sh
prove -Ilib -v t
git diff --check
git status --short
```

## Known issues to account for

These describe the checked-in implementation, rather than intended behavior:

- Local CSS and profile images use domain-root paths, so subpath hosting
  needs template changes. `site_url` is only used for Open Graph metadata;
  it is not inferred or normalized, and its image URL concatenation needs
  a trailing `/`.
- The social fixture uses `service => 'twitter'` with an explicit URL and
  only tests readers. The supported service key for generated icons/URLs is
  `x-twitter`.

Keep documentation accurate if these issues are fixed; do not preserve a
bug merely because it is documented.

## Documentation, CI, and releases

`README.md` is the canonical user guide. The active documentation workflow
converts it to `_site/index.html` using `davorg/readme-to-index`, then deploys
that artifact. It runs on README changes pushed to `main` or a manual run
on `main`. Pull requests do not trigger it, and manual runs on other branches
skip the deployment job. `docs/index.md`, `_config.yml`,
and `CNAME` belong to the older Jekyll arrangement; `docs/README.md` points
readers to the canonical guide instead of maintaining a second copy.
The consumer workflow in `example/build.yml` deploys generated link pages
and is separate from this repository's documentation workflow.
Its push filters watch `links.json`, `img/**`, `CNAME`, and the workflow's
installed path, `.github/workflows/build.yml`, on `main`. Manual dispatch
is preserved, with the build job guarded to run only on `main`; the dependent
deployment job skips when the build skips. Consumers with another default
branch must update both the push branch filter and the build job condition.
Validate changes to this sample with actionlint and check the branch/path
combinations, including asset-only pushes and manual runs on other branches.

Keep `MANIFEST` current for files that must ship. Use `make distcheck` to
review its warnings, then `make dist` to build a release archive. Check that
the archive contains the full `t/` suite and its fixtures, plus the flat,
sectioned, and UTM configuration examples. Extract it into a temporary
directory and run `perl Makefile.PL`, `make`, and `make test` there before releasing;
a passing checkout suite alone does not verify packaged files.
Repository-only CI and docs files may intentionally be excluded.

See [docker/README.md](docker/README.md) for the container workflow. The
Dockerfile installs a version from CPAN, not the checkout. `docker/build`
publishes images to Docker Hub, so it is a release operation rather than a
local verification command.

### Versioning

App::LinkSite follows Semantic Versioning (SemVer): `MAJOR.MINOR.PATCH`.
Assess compatibility across the documented JSON configuration format, CLI,
and public Perl API when choosing a release version.

For stable releases (`1.0.0` and later):

- Increment `MAJOR` for incompatible public interface changes, resetting
  `MINOR` and `PATCH` to zero.
- Increment `MINOR` for backward-compatible functionality or deprecation of
  public functionality, resetting `PATCH` to zero.
- Increment `PATCH` for backward-compatible bug fixes.

The current `0.x.y` series is initial development under SemVer: the public
API is not yet considered stable and compatibility is not guaranteed.
Describe breaking changes and any migration steps explicitly in `Changes.md`.

Record release changes in `Changes.md`. `VERSION_FROM` in `Makefile.PL`
points at `lib/App/LinkSite.pm`; all four model modules also declare versions.
Keep all five declarations aligned when preparing a release. Do not change
an already published version's contents; publish a new version instead.
Routine documentation edits do not require a version bump on their own.
