# Bioconda::Packages

[![CPAN Version](https://img.shields.io/cpan/v/Bioconda-Packages)](https://metacpan.org/dist/Bioconda-Packages)
![CPAN License](https://img.shields.io/cpan/l/Bioconda-Packages)
[![test](https://github.com/telatin/perl-bioconda-packages/actions/workflows/ci.yml/badge.svg)](https://github.com/telatin/perl-bioconda-packages/actions/workflows/ci.yml)


Query a bundled, offline snapshot of [Bioconda](https://bioconda.github.io)
package metadata from Perl — versions, dependencies, licenses, summaries and
homepage/URLs — with no network access at query time.

A gzipped JSON database (~1.4 MB) ships inside the distribution. Packages that
disappear from `bioconda-recipes` are **kept** and flagged *removed*, so
historical lookups keep working.

## Install

```sh
perl Makefile.PL && make && make test && make install
```

Runtime dependencies are core-only (`JSON::PP`, `IO::Uncompress::Gunzip`).
Perl 5.14+ required.

## Library usage

```perl
use Bioconda::Packages;

my $bp = Bioconda::Packages->new;             # loads the bundled database

if ($bp->exists('samtools')) {
    my $pkg = $bp->get('samtools');           # Bioconda::Packages::Package
    print $pkg->current_version, "\n";
    print $pkg->summary, "\n";
    print "$_\n" for $pkg->dependency_names('run');
    print "REMOVED\n" if $pkg->is_removed;
}

my @aligners = $bp->search('aligner');        # name/summary substring match
my @users    = $bp->reverse_dependencies('zlib', kind => 'all');
my @gone     = $bp->removed;
my %stats    = $bp->stats;
```

### `Bioconda::Packages` methods

| Method | Description |
|--------|-------------|
| `new(db => $path)` | Load the database (defaults to the bundled one). |
| `exists($name)` | Is the package known? (case-insensitive, includes removed). |
| `get($name)` | A `Bioconda::Packages::Package` object, or `undef`. |
| `list(include_removed => 0\|1)` | Sorted package names. |
| `search($str_or_regex, fields => [...])` | Substring/regex search. |
| `reverse_dependencies($dep, kind => ...)` | Who depends on `$dep`. |
| `removed` | Names flagged as removed. |
| `stats` | Summary counts + db provenance. |
| `db_version` | Database snapshot version, e.g. `2026.11.1`. |

### `Bioconda::Packages::Package` accessors

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
bioconda-packages version                 # tool + database version
```

The **tool version** (`Bioconda::Packages->VERSION`) is the code version.
The **database version** is a separate CalVer string (`YYYY.M.N`); compare it
component-wise, not as a plain string (`2026.11.10 > 2026.11.9`).

## Maintainer: rebuilding the database

See **[DEV_UPGRADE.md](DEV_UPGRADE.md)** for the full workflow. Quick start:

```sh
git clone --depth 1 https://github.com/bioconda/bioconda-recipes
./maintainer/upgrade-db.sh          # check prereqs, pull, rebuild, test
```

## Further reading

- [DEV_UPGRADE.md](DEV_UPGRADE.md) — rebuilding and versioning the bundled database
- [ARCHITECTURE.md](ARCHITECTURE.md) — module layout, DB lookup order, design notes

## License

Same terms as Perl itself.

## Author

Andrea Telatin
