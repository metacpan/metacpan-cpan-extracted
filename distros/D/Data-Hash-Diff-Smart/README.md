# NAME

Data::Hash::Diff::Smart - Smart structural diff for Perl data structures

# VERSION

Version 0.01

# SYNOPSIS

    use Data::Hash::Diff::Smart qw(diff diff_text diff_json diff_yaml diff_test2);

    my $changes = diff($old, $new);

    print diff_text($old, $new);

    my $json = diff_json($old, $new);

    my $yaml = diff_yaml($old, $new);

    diag diff_test2($old, $new);

# DESCRIPTION

`Data::Hash::Diff::Smart` provides a modern, recursive, configurable diff
engine for Perl data structures. It understands nested hashes, arrays,
scalars, objects, and supports ignore rules, custom comparators, and
multiple array diffing strategies.

The diff engine produces a stable, structured list of change operations,
which can be rendered as text, JSON, YAML, or Test2 diagnostics.

# FUNCTIONS

## diff($old, $new, %opts)

Compute a structural diff between two Perl data structures.

Returns an arrayref of change operations:

    [
        { op => 'change', path => '/user/name', from => 'Nigel', to => 'N. Horne' },
        { op => 'add',    path => '/tags/2',    value => 'admin' },
        { op => 'remove', path => '/debug',     from  => 1 },
    ]

### Options

- ignore => \[ '/path', qr{^/debug}, '/foo/\*/bar' \]

    Ignore specific paths. Supports exact paths, regexes, and wildcard
    segments.

- compare => { '/price' => sub { abs($\_\[0\] - $\_\[1\]) < 0.01 } }

    Custom comparator callbacks for specific paths.

- array\_mode => 'index' | 'lcs' | 'unordered'

    Choose how arrays are diffed:

    - index - compare by index (default)
    - lcs - minimal diff using Longest Common Subsequence
    - unordered - treat arrays as multisets (order ignored)

- array\_key => 'id'

    When using unordered `array_mode` with arrays of hashes,
    nominate a field to use as the identity key for matching elements across the two arrays.
    Without this, elements are compared as multisets by structure.

        diff($old, $new, array_mode => 'unordered', array_key => 'id')

## diff\_text($old, $new, %opts)

Render the diff as a human-readable text format.

## diff\_json($old, $new, %opts)

Render the diff as JSON using `JSON::MaybeXS`.

## diff\_yaml($old, $new, %opts)

Render the diff as YAML using `YAML::XS`.

## diff\_test2($old, $new, %opts)

Render the diff as Test2 diagnostics suitable for `diag`.

# INTERNALS

The diff engine lives in [Data::Hash::Diff::Smart::Engine](https://metacpan.org/pod/Data%3A%3AHash%3A%3ADiff%3A%3ASmart%3A%3AEngine).

# BENCHMARKS

To run all benchmarks:

    perl benchmarks/bench.pl

This will run diff operations on:

\- small structures
\- medium nested structures
\- large 5000-element arrays
\- cyclic structures (cycle detection)
\- unordered array mode
\- LCS array mode

Example output:

    === Benchmark: medium ===
                 Rate
    diff     12000/s

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SEE ALSO

[Data::Hash::Patch::Smart](https://metacpan.org/pod/Data%3A%3AHash%3A%3APatch%3A%3ASmart)

# REPOSITORY

[https://github.com/nigelhorne/Data-Hash-Diff-Smart](https://github.com/nigelhorne/Data-Hash-Diff-Smart)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-data-hash-diff-smart at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Hash-Diff-Smart](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Hash-Diff-Smart).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Data::Hash::Diff::Smart

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Data-Hash-Diff-Smart](https://metacpan.org/dist/Data-Hash-Diff-Smart)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Hash-Diff-Smart](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Hash-Diff-Smart)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Data-Hash-Diff-Smart](http://matrix.cpantesters.org/?dist=Data-Hash-Diff-Smart)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Data::Hash::Diff::Smart](http://deps.cpantesters.org/?module=Data::Hash::Diff::Smart)

# LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
