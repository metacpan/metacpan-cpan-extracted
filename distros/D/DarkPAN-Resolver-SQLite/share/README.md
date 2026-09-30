# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [WHY THIS EXISTS](#why-this-exists)
* [USAGE](#usage)
* [HOW IT WORKS](#how-it-works)
* [METHODS](#methods)
  * [new](#new)
  * [resolve](#resolve)
* [LIMITATIONS](#limitations)
* [SEE ALSO](#see-also)
* [AUTHOR](#author)
# NAME

DarkPAN::Resolver::SQLite - a cpm resolver for multi-version DarkPAN indexes

# SYNOPSIS

    # install the latest version from your DarkPAN
    cpm install \
      --resolver +DarkPAN::Resolver::SQLite,https://cpan.openbedrock.net/orepan2 \
      Amazon::API

    # install a specific historical version
    cpm install \
      --resolver +DarkPAN::Resolver::SQLite,https://cpan.openbedrock.net/orepan2 \
      Amazon::API@2.6.0

    # or a range
    cpm install \
      --resolver +DarkPAN::Resolver::SQLite,https://cpan.openbedrock.net/orepan2 \
      'Amazon::API~">= 2.0.0, < 3.0.0"'

# DESCRIPTION

`DarkPAN::Resolver::SQLite` is a resolver plugin for
[cpm](https://metacpan.org/pod/App%3A%3Acpm) that resolves distributions from a DarkPAN's
**multi-version** SQLite index (as produced by [DarkPAN::Indexer](https://metacpan.org/pod/DarkPAN%3A%3AIndexer)).

A conventional DarkPAN publishes `02packages.details.txt.gz`, which records
one indexed distribution for each package. A resolver using that index therefore
cannot select an older distribution merely because its tarball still exists in
the repository.

`DarkPAN::Resolver::SQLite` instead reads the multi-version index produced by
[DarkPAN::Indexer](https://metacpan.org/pod/DarkPAN%3A%3AIndexer), allowing it to select the highest available version that
satisfies the requested version constraint.

Because it participates in cpm's ordered resolver cascade, the SQLite
resolver composes with cpm's normal CPAN resolvers. Requests the DarkPAN can
satisfy are resolved from its multi-version index; requests it cannot satisfy
continue to cpm's default resolvers.

By default, adding `--resolver` does not disable cpm's normal resolvers.
Users who specify `--no-default-resolvers` are responsible for supplying the
complete resolver chain themselves.

# WHY THIS EXISTS

A standard 02packages index is sufficient when only the current
indexed version matters. This resolver exists for DarkPANs that retain
multiple historical distributions and need normal Perl version
constraints to select among them.

# USAGE

Invoke it as a custom cpm resolver. cpm prepends `App::cpm::Resolver::` to a
bare resolver name, so a class outside that namespace must be given with a
leading `+` (take-the-name-verbatim):

\--resolver +DarkPAN::Resolver::SQLite,&lt;mirror-url>

`<mirror-url>` is the public base URL of your DarkPAN (the same URL a
browser or `cpanm --mirror` would use), for example
`https://cpan.openbedrock.net/orepan2`. The resolver fetches the index from
`<mirror-url>/modules/packages.db.gz`.

Only a public HTTP(S) URL is required -- the resolver uses [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny) and does
**not** need AWS credentials or S3 access, even for an S3-backed DarkPAN fronted
by CloudFront. (HTTPS requires [IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL)/[Net::SSLeay](https://metacpan.org/pod/Net%3A%3ASSLeay) to be present,
as with any `HTTP::Tiny` https use.)

# HOW IT WORKS

On construction the resolver fetches `modules/packages.db.gz` from
the mirror, decompresses it to a temporary file, opens the SQLite
database, and uses it only for package lookups.

- 1. selects all rows for the requested package from the index;
- 2. keeps only versions that satisfy the request's version range, using
cpm's own version semantics ([App::cpm::version](https://metacpan.org/pod/App%3A%3Acpm%3A%3Aversion)) so its choices agree with the
rest of the cascade;
- 3. picks the highest satisfying version (compared in Perl -- SQLite's
lexical `ORDER BY` would order `1.10.0` below `1.9.0`);
- 4. reconstructs the fetch URI from the stored distribution path via
[App::cpm::DistNotation](https://metacpan.org/pod/App%3A%3Acpm%3A%3ADistNotation) and returns it to cpm.

The temporary database file is removed when the resolver object is destroyed.

# METHODS

These implement the cpm resolver contract; you do not normally call them
directly.

## new

    DarkPAN::Resolver::SQLite->new( $ctx, $mirror_url )

Fetches and opens the index. Called by cpm with the context and the argument
you supplied after the class name in `--resolver`.

## resolve

    $resolver->resolve( $ctx, $task )

Resolves one request. `$task` carries `package` and `version_range`. Returns
a resolution hashref (`source`, `distfile`, `uri`, `version`, `package`) on
success, or `{ error => ... }` if the package or a satisfying version is
not found -- allowing the cascade to fall through to the next resolver.

# LIMITATIONS

Per-package resolution only: like every cpm resolver, it answers "which version
of _this_ package, from where"; it is not a global dependency solver. The
version index it reads must be published by [DarkPAN::Indexer](https://metacpan.org/pod/DarkPAN%3A%3AIndexer) at
`modules/packages.db.gz` under the mirror. The whole index is fetched on
construction (no incremental/conditional fetch); this is negligible for typical
index sizes.

The resolver can select only distributions recorded in the published SQLite
index. A distribution tarball that exists in the repository but has not been
indexed is not visible to the resolver.

# SEE ALSO

[DarkPAN::Indexer](https://metacpan.org/pod/DarkPAN%3A%3AIndexer), [App::cpm](https://metacpan.org/pod/App%3A%3Acpm), [App::cpm::Resolver::02Packages](https://metacpan.org/pod/App%3A%3Acpm%3A%3AResolver%3A%3A02Packages)

# AUTHOR

Rob Lauer
