# Change Log

## [0.2.0] - 2026-11-27

### Added

- Document configuration, development and coding-agent workflows, packaging,
  and the Semantic Versioning policy.
- Add opt-in UTM parameters for content links, with configurable defaults,
  title-slug defaults for `utm_content`, global and per-link settings, and
  per-link opt-out. Preserve existing query parameters, fragments, canonical
  URLs, and social profile URLs (#25).

### Fixed

- Read JSON and templates and write generated pages as UTF-8 so non-ASCII
  campaign values and page text are encoded correctly (#25).
- Escape Open Graph and page-description metadata attributes so names and
  descriptions containing quotes or ampersands remain intact. Preserve HTML
  in the visible description (#32).
- Include the section test and sectioned configuration example in CPAN
  distributions (#30).
- Preserve relative directories when rendering templates, avoiding output
  collisions between matching basenames. Treat directories ending in `.tt`
  as directories rather than template files (#33).
- Correct the sample deployment workflow's `branches` filter and rebuild
  for image or `CNAME` changes; skip manual deployments from other branches
  (#28).
- Use the configured GA4 measurement ID in both the Google tag loader URL
  and configuration call; cover configured and disabled analytics (#27).
- Deploy the documentation site only from `main`, skipping feature-branch
  manual runs and removing deployments on pull requests.
- Honor the CLI `--file` option, including filenames such as `0`, and stop
  invalid options from building the default input (#26).
- Use Strawberry Perl's bundled Windows toolchain in CI to avoid XS
  extension/interpreter ABI mismatches; retain the full Perl matrix and
  collect failures independently for each Windows version (#36).
- Run subprocess test helpers from temporary scripts so Windows executes
  their complete program, and verify the child test emits its plan (#36).
- Correct configure prerequisite metadata, require Path::Tiny 0.125, and
  declare File::Basename and Test::More in Makefile.PL (#29).
- Include generated META.json so clean checkouts can install configure
  dependencies before running Makefile.PL (#29).
- Isolate the default input-file test in a temporary directory so running
  the test suite preserves an existing `links.json` (#31).

### Removed

- Remove the legacy cpanfile; Makefile.PL is the dependency source for the
  CPAN distribution (#29).

## [0.1.3] - 2026-08-17

### Fixed

- Ko-fi needs a newer version of Font Awesome

## [0.1.2] - 2026-08-17

### Added

- Support for Ko-fi as a social network
- Missing pre-reqs

## [0.1.1] - 2026-02-19

### Added

- Missing module

## [0.1.0] - 2026-02-18

### Updated

- Allow configuration of text colour and background colour
- Add support for sections in list of links
- Simply example workflow
- Accept filename as command-line argument

## [0.0.17] - 2025-08-04

### Updated

- Sticky footer

## [0.0.16] - 2025-08-04

### Updated

- Improved footer links

## [0.0.15] - 2025-06-27

### Updated

- Update version of Bootstrap used in example

## [0.0.14] - 2025-04-14

### Fixed

- Require Feature::Compat::Class 0.07 (for :reader)

## [0.0.13] - 2025-03-28

### Added

- Add "rel='me'" to the social links

## [0.0.12] - 2025-02-22

### Added

- Publish the input JSON to the website

## [0.0.11] - 2024-11-25

### Fixed

- Fixed invalid JSON-LD

## [0.0.10] - 2024-11-12

### Fixed

- A stupid typo

## [0.0.9] - 2024-11-12

### Fixed

- Added meta description to output page

## [0.0.8] - 2024-11-04

### Improved

- Remove the requirement for a Font Awesome kit number

## [0.0.7] - 2024-11-02

### Fixed

- Missing tests
- Fix bug they found

## [0.0.6] - 2024-11-02

### Fixed

- Test improvements

## [0.0.5] - 2024-10-30

### Fixed

- Load the function so we can find the shared files

## [0.0.4] - 2024-10-30

### Fixed

- Actually install the shared files

## [0.0.3] - 2024-10-29

### Removed

- Unnecessary debugging

## [0.0.2] - 2024-10-29

### Added

- Changes.md

## [0.0.1] - 2024-10-29
 
### Added
 
- All the things. Release early, release often.
