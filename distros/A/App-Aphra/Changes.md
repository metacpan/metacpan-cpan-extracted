# Change Log

## [0.2.6] - 2026-01-02

### Fixed

- Naming confusion in new test

## [0.2.5] - 2026-01-01

### Fixed

- Don't recreate files that already exist in the output directory
- Skip processing source files when the output file already exists (e.g., from redirects)
- Emit warnings when skipping file processing to avoid overwriting existing files

## [0.2.4] - 2024-11-27

### Fixed

- Use new version of Template::Provider, which handles the frontmatter

## [0.2.3] - 2024-11-25

### Fixed

- Remove frontmatter before processing template

## [0.2.2] - 2024-10-27

### Fixed

- When creating redirections, ensure all directories are created

## [0.2.1] - 2024-08-13

### Added

- Support for overriding layouts

## [0.2.0] - 2024-07-01

### Added

- Support for redirection pages

## [0.1.3] - 2024-06-14

### Fixed

- Bug in App::Aphra::File::uri

## [0.1.2] - 2024-06-14

### Added

- Added uri() method to both classes
- Pass $self (as "file") to file template processing

## [0.1.1] - 2024-01-24

### Fixed

- Improved CI and repo metadata

## [0.1.0] - 2023-10-27

### Fixed

- Only run conversion tests if `pandoc` is installed

## [0.0.7] - 2023-10-26

### Added

- Support for `site.yml`
- Support for front matter in templates

## [0.0.6] - 2020-12-06

### Fixed

- Bring minimum Perl requirements into line
- Add bugtracker details

## [0.0.5] - 2018-02-25

### Fixed

- Another fix for the extensions problem.

## [0.0.4] - 2018-02-23

### Fixed

- The extensions hash was the wrong way round.
- Added a `serve` command.
- Improved the tests.

## [0.0.3] - 2017-09-05

### Fixed

- Internals now use an App::Aphra::File class.
- Added MIN_PERL_VERSION to Makefile.PL.
- Fixed packaging to include Meta.*.

## [0.0.2] - 2017-09-02

### Fixed

- Fixed documentation
- Added missing pre-req
- Fix syntax error

## [0.0.1] - 2017-09-02
 
### Added
 
- All the things. Release early, release often.
