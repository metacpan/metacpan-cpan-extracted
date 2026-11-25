# Bioconda::Packages

Query a bundled, offline snapshot of [Bioconda](https://bioconda.github.io)
package metadata from Perl — versions, dependencies, licenses, summaries and
homepage/URLs — with no network access at query time.

A gzipped JSON database (~1.4 MB) ships inside the distribution. Maintainer
tooling rebuilds it from a local `bioconda-recipes` clone, optionally enriching
it with published versions and download counts from anaconda.org.

Packages that disappear from `bioconda-recipes` are **kept** in the database and
flagged as *removed*, so historical lookups keep working.

## Install

```sh
perl Makefile.PL
make
make test
make install
```

Only core Perl modules are required to *use* the library (`JSON::PP`,
`IO::Uncompress::Gunzip`). Perl 5.14+ is assumed.

## Library usage

```perl
use Bioconda::Packages;

my $bp = Bioconda::Packages->new;             # loads the bundled database

if ($bp->exists('samtools')) {
    my $pkg = $bp->get('samtools');           # Bioconda::Packages::Package
    print $pkg->current_version, "\n";        # 1.25
    print $pkg->summary, "\n";
    print "$_\n" for $pkg->dependency_names('run');
    print "REMOVED\n" if $pkg->is_removed;
}

my @aligners = $bp->search('aligner');        # name/summary substring match
my @users    = $bp->reverse_dependencies('zlib', kind => 'all');
my @gone     = $bp->removed;                  # packages dropped from bioconda
my %stats    = $bp->stats;
```

### Main methods (`Bioconda::Packages`)

| Method | Description |
|--------|-------------|
| `new(db => $path)` | Load the database (defaults to the bundled one). |
| `exists($name)` | Is the package known? (case-insensitive, includes removed). |
| `get($name)` | A `Bioconda::Packages::Package` object, or `undef`. |
| `list(include_removed => 0\|1)` | Sorted package names. |
| `count(...)` | Number of packages. |
| `search($str_or_regex, fields => [...], include_removed => 0\|1)` | Substring/regex search. |
| `reverse_dependencies($dep, kind => run\|host\|build\|all)` | Who depends on `$dep`. |
| `removed` | Names flagged as removed. |
| `stats` | Summary counts + db provenance. |
| `db_version` | Database snapshot version, e.g. `2026.11.1`. |
| `meta` | Raw db provenance hashref. |

### Package object (`Bioconda::Packages::Package`)

`name`, `current_version`, `versions`, `recipe_versions`, `published_versions`,
`dependencies($kind)`, `dependency_names($kind)`, `summary`, `license`,
`license_family`, `home`, `dev_url`, `doc_url`, `identifiers`, `outputs`,
`noarch`, `downloads`, `is_removed`, `removed_at`, `data` (raw hashref).

## Command-line usage

```sh
bioconda-packages info samtools
bioconda-packages deps multiqc            # --kind host|build|all
bioconda-packages versions samtools
bioconda-packages search aligner
bioconda-packages rdeps zlib              # --kind run|host|build|all
bioconda-packages removed
bioconda-packages stats
bioconda-packages version                 # tool + database version (also --version, -V)
```

### Tool version vs database version

The **tool version** (`Bioconda::Packages->VERSION`, e.g. `0.01`) is the code/API
version. The **database version** is a separate, data-only CalVer string
`YEAR.MONTH.N` (e.g. `2026.11.1`), where `N` is a progressive counter that resets
each month. It is a valid 3-part SemVer, so it sorts correctly under
SemVer/numeric rules (`2026.11.10 > 2026.11.2`) — compare it component-wise, not
as a plain string. Get it with `bioconda-packages version`, `$bp->db_version`, or
`$bp->meta->{recipes_commit}` for the exact source commit.

The counter advances **only when the package data actually changes**: a rebuild
that produces identical content keeps the same version and leaves the database
file untouched (volatile fields — timestamps and download counts — are excluded
from the comparison via a stored content hash). Use `update-db.pl --force` to
bump and rewrite regardless.

## Maintainer workflow: rebuilding the database

The database is regenerated from a local clone of
[`bioconda-recipes`](https://github.com/bioconda/bioconda-recipes). The clone is
**not** part of this repository (`.gitignore` excludes `bioconda-recipes/`).

```sh
# One-time: clone the recipes repo next to this project
git clone --depth 1 https://github.com/bioconda/bioconda-recipes

# Each update: pull the repo, then rebuild the shipped database
perl maintainer/update-db.pl --repo bioconda-recipes
```

What `update-db.pl` does:

1. `git pull --ff-only` the recipes clone (skip with `--no-pull`);
2. parse every `recipes/<name>/meta.yaml`;
3. merge with the existing database — any package that vanished from the repo is
   **retained and flagged `is_removed`**, with `removed_at` stamped once; a
   package that reappears is un-flagged;
4. optionally enrich from anaconda.org (`--api`);
5. write `share/bioconda-packages.json.gz` atomically.

Useful options:

```
--repo PATH      Path to the bioconda-recipes clone (default: ./bioconda-recipes)
--db PATH        Output database (default: share/bioconda-packages.json.gz)
--no-pull        Do not git pull first
--api            Enrich with published versions & download counts from anaconda.org
--api-sleep SEC  Throttle API calls
--limit N        Process only the first N recipes (for testing)
--force          Bump the version and rewrite even if nothing changed
```

> **`--api` requires HTTPS support**: install `IO::Socket::SSL` and `Net::SSLeay`
> (e.g. `cpanm IO::Socket::SSL`). Without them, recipe-only metadata is still
> built; the API step just reports failures.

### Releasing to CPAN

Rebuild the JSON database first, then package as usual:

```sh
perl maintainer/update-db.pl --repo bioconda-recipes      # regenerate the db
make test
make dist
```

The gzipped database is installed next to the modules (via the explicit `PM`
map in `Makefile.PL`), so no `File::ShareDir` is required at runtime.

### A future SQLite workflow

The `Bioconda::Packages::DB` layer isolates all storage I/O. A developer-only
SQLite backend could be added there and kept in the repository (not shipped to
CPAN); the CPAN release would still ship the rebuilt JSON snapshot.

## Architecture

```
lib/Bioconda/Packages.pm              user-facing read-only query API
lib/Bioconda/Packages/Package.pm      a single package record (accessors)
lib/Bioconda/Packages/DB.pm           locate / load / save the JSON(.gz) database
lib/Bioconda/Packages/RecipeParser.pm Jinja-aware meta.yaml parser (core-only)
lib/Bioconda/Packages/Updater.pm      maintainer: build db from recipes (+ API)
bin/bioconda-packages                 user CLI
maintainer/update-db.pl               maintainer CLI (pull + rebuild)
share/bioconda-packages.json.gz       the shipped database
t/                                    tests
```

## License

Same terms as Perl itself.

## Author

Andrea Telatin
