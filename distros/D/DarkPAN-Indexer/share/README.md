# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [CONSTRUCTOR](#constructor)
  * [new](#new)
* [METHODS](#methods)
  * [create\_index](#create\index)
  * [update\_index](#update\index)
  * [delete\_from\_index](#delete\from\index)
* [CONFIGURATION](#configuration)
* [STORAGE ENGINES](#storage-engines)
* [FORMAT ENGINES](#format-engines)
* [SEE ALSO](#see-also)
* [AUTHOR](#author)
# NAME

DarkPAN::Indexer - build and maintain a multi-version index of a DarkPAN

# SYNOPSIS

    use DarkPAN::Indexer;

    my $indexer = DarkPAN::Indexer->new( config_file => '/path/to/darkpan.json' );

    # full build from every distribution in the repository
    my $stats = $indexer->create_index;

    # incrementally (re)index a single distribution
    $indexer->update_index( distribution => 'authors/id/A/AB/AUTHOR/Foo-1.0.tar.gz' );

    # remove a distribution's packages from the index
    $indexer->delete_from_index( distribution => 'authors/id/A/AB/AUTHOR/Foo-1.0.tar.gz' );

# DESCRIPTION

`DarkPAN::Indexer` builds and maintains a **multi-version** package index for a
DarkPAN. Unlike `02packages.details.txt.gz`, which records only the latest
version of each package, this index records **every** version of every package
present in the repository, so a client can resolve and install a specific
historical version by name -- not just the latest.

The indexer is an **orchestrator**. It composes two pluggable pieces and moves
opaque data between them:

- A **storage** engine (["STORAGE ENGINES"](#storage-engines)) -- where the distributions
and the index physically live (S3, local filesystem, ...).
- A **format** engine (["FORMAT ENGINES"](#format-engines)) -- how the index is built and
queried (SQLite, ...).

The orchestrator itself knows nothing about S3 or SQLite. It reads config,
constructs the two engines named there, and drives them. This is what lets the
same code index an S3-backed DarkPAN behind CloudFront and a plain directory of
tarballs on a laptop.

# CONSTRUCTOR

## new

my $indexer = DarkPAN::Indexer->new( config\_file => $path );
my $indexer = DarkPAN::Indexer->new( config      => \\%config );

Constructs an indexer. Provide either `config_file` (a path to a JSON config,
see ["CONFIGURATION"](#configuration)) or `config` (an already-loaded config hashref). The
storage and format engines are constructed immediately from the config.

# METHODS

## create\_index

    my $stats = $indexer->create_index;

Builds a fresh index from **every** distribution in the repository. Enumerates
the repository (`storage->list_distributions`), scans each distribution for
the packages it provides, loads them into a new index, and publishes the index
back to storage. This is the full-rebuild / authoritative operation; run it to
create the index initially or to rebuild it from ground truth.

Returns a stats hashref (distributions seen, distributions indexed, failures,
modules written).

## update\_index

    $indexer->update_index( distribution => $key );

Incrementally (re)indexes a single distribution. Retrieves the current index,
performs a delete-then-insert for the named distribution's packages, and
publishes the updated index. `$key` is the storage key of the distribution
tarball (e.g. `authors/id/A/AB/AUTHOR/Foo-1.0.tar.gz`). The whole
read-modify-write is performed under a storage lock.

## delete\_from\_index

    $indexer->delete_from_index( distribution => $key );

Removes a single distribution's packages from the index. Retrieves the current
index, deletes the rows for the named distribution, and publishes. Also
performed under a storage lock.

# CONFIGURATION

The config (JSON file via `config_file`, or a hashref via `config`) describes
one DarkPAN. The keys the indexer reads are:

- `storage`

    Selects and configures the storage engine, e.g.:

        "storage" : { "type" : "S3", "bucket" : "my-darkpan", "region" : "us-east-1" }
        "storage" : { "type" : "Filesystem", "root" : "/srv/darkpan" }

    `type` names the engine (resolved to `DarkPAN::Indexer::Storage::<type>`,
    or a `+Fully::Qualified` name). For backward compatibility, a config with a
    legacy `AWS` block and no `storage` block is treated as S3.

- `format`

    Selects the index format engine, e.g. `"format" : { "type" : "SQLite" }`.
    Defaults to `SQLite` if omitted.

- `packages_version_index`

    The storage key of the published index, e.g.
    `orepan2/modules/packages.db.gz`. A `.gz` suffix causes the index to be
    stored compressed.

# STORAGE ENGINES

A storage engine consumes the `DarkPAN::Indexer::Storage` role and provides:
`list_distributions`, `fetch_object`, `save_object`, `has_object`, `lock`,
and `base_url`, plus the role-provided `retrieve_index`/`publish_index`.
`DarkPAN::Indexer::Storage::S3` and `DarkPAN::Indexer::Storage::Filesystem`
ship with this distribution.

# FORMAT ENGINES

A format engine consumes the `DarkPAN::Indexer::Format` role and provides:
`create_index`, `update_index`, `load_index`, and `delete_from_index`. The
role provides the shared `index_distribution` (tarball -> package records)
machinery. `DarkPAN::Indexer::Format::SQLite` ships with this distribution.

# SEE ALSO

[DarkPAN::Indexer::CLI](https://metacpan.org/pod/DarkPAN%3A%3AIndexer%3A%3ACLI), [DarkPAN::Resolver::SQLite](https://metacpan.org/pod/DarkPAN%3A%3AResolver%3A%3ASQLite), [OrePAN2::Lite](https://metacpan.org/pod/OrePAN2%3A%3ALite)

# AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>
