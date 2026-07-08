# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [METHODS AND SUBROUTINES](#methods-and-subroutines)
  * [new(\[$data\_ref\], @kv\_list)](#new\[$data\ref\]-kv\list)
  * [set(@kv\_list)](#setkv\list)
  * [get(@key\_paths)](#getkey\paths)
  * [delete(@key\_paths)](#deletekey\paths)
  * [exists\_key(@key\_paths)](#exists\keykey\paths)
  * [as\_string()](#as\string)
* [AUTHOR](#author)
* [SEE ALSO](#see-also)
* [LICENSE](#license)
* [POD ERRORS](#pod-errors)
# NAME

Data::NestedKey - Object-oriented handling of deeply nested hash structures.

# SYNOPSIS

    use Data::NestedKey;

    my $nk = Data::NestedKey->new(
        'foo.bar.baz' => 42,
        'foo.bar.qux' => 'hello'
    );

    $nk->set('foo.bar.baz' => 99, 'foo.xyz' => [1, 2, 3]);

    # Plain dot-path access
    my $baz = $nk->get('foo.bar.baz');

    # Array subscript access
    my $nk2 = Data::NestedKey->new($ecr_response);
    my $uri  = $nk2->get('repositories[0].repositoryUri');

    $nk->delete('foo.bar.baz');
    print $nk->as_string();

# DESCRIPTION

Data::NestedKey provides an object-oriented approach to managing deeply nested
hash structures using dot-separated keys. This allows structured data to be
manipulated in a clean and intuitive way without requiring manual traversal
of nested hashes.

Path strings use dots to separate hash keys. Array elements may be accessed
by appending a zero-based subscript in square brackets to any hash key segment.
Negative indices count from the end of the array (`-1` is the last element).

    repositories[0].repositoryUri   # first element of the repositories array
    items[-1].name                  # last element of the items array
    a.b[2].c.d[-1]                  # deeply nested mix of hashes and arrays

The root of the structure may itself be an array. A path that begins with a
bare subscript indexes the top-level array directly:

    [0].name        # 'name' field of the first top-level element
    [-1]            # the last top-level element

Array subscript notation is supported in `get`, `exists_key`, and `delete`
(including bare leading subscripts against an array root). It is **not**
supported in `set` (see below).

Array subscript notation is supported in `get`, `exists_key`, and `delete`.
`set` continues to operate on plain dot-separated hash paths only.

A key motivation for this module is configuration file and API response
manipulation. Many applications use structured data (e.g., JSON, YAML) where
values are nested several levels deep. This module enables reading and modifying
specific elements using intuitive dot-separated keys, making access more
straightforward.

For example, given a JSON configuration file, a utility could allow:

    init-config foo.json session_files.dir /some/path

Where the command takes the configuration file name followed by key-value pairs
representing the specific elements to update.

The class also supports serialization in multiple formats, controlled by
package variables:

- `$Data::NestedKey::JSON_PRETTY` (default: 1)

    Controls whether JSON output is formatted prettily or in a compact form.

- `$Data::NestedKey::FORMAT` (default: 'JSON')

    Specifies the serialization format. Supported formats:

        - JSON (default)
        - YAML
        - Data::Dumper
        - Storable

# METHODS AND SUBROUTINES

## new(\[$data\_ref\], @kv\_list)

Creates a new Data::NestedKey object. If no arguments are provided, initializes
with an empty structure. Optionally, an initial data reference can be supplied
as the root: either a **hash reference** or an **array reference**. Key-value
pairs may also be provided for immediate population, but only when the root is
a hash (or defaulted) — supplying key-value pairs together with an array-ref
root throws an exception, since `set` operates on dot-separated hash keys.

Returns a `Data::NestedKey` object.

## set(@kv\_list)

Inserts, updates, appends, or removes values in the nested structure using
dot-separated keys. Array subscript notation (e.g. `key[0]`) is **not**
supported in `set` paths — nor can values be set against an array-rooted
structure — and an exception is thrown in either case. To modify array
contents, retrieve the parent with `get`, alter the Perl structure directly,
and construct a new object if needed.

- If a key already exists and holds a scalar, assigning a new value will **replace** it.
- If the `+` prefix is used (e.g., `+key`), the value will be **appended**:

        $nk->set('foo.bar' => 1);
        $nk->set('+foo.bar' => 2);
        $nk->set('+foo.bar' => 3);
        # foo.bar now contains [1, 2, 3]

- If the `+` prefix is used with a hash, it merges keys instead of replacing:

        $nk->set('config' => { key1 => 'val1' });
        $nk->set('+config' => { key2 => 'val2' });
        # config now contains { key1 => 'val1', key2 => 'val2' }

- If the `-` prefix is used (e.g., `-key`), the value is **removed**:

        $nk->set('-foo.bar' => 2);
        # If foo.bar is an array, it removes element '2'
        # If foo.bar is a hash, it removes key '2'
        # Otherwise, it deletes foo.bar entirely

Returns the object itself.

## get(@key\_paths)

Retrieves values from the nested structure based on dot-separated key paths.
Array elements may be accessed with `[n]` subscripts (zero-based; negative
indices count from the end):

    my $uri  = $nk->get('repositories[0].repositoryUri');
    my $last = $nk->get('items[-1].name');

The root may be an array, in which case a leading subscript indexes it
directly:

    my $first = $nk->get('[0]');
    my $name  = $nk->get('[0].name');

Returns `undef` for any path that does not exist or whose subscript is out
of range.  In list context returns all requested values; in scalar context
returns the first.

## delete(@key\_paths)

Removes the specified keys from the nested structure. If the final segment
carries an array subscript, the element is removed with `splice` (the array
shrinks; no undef hole is left). Empty parent hashes are pruned automatically
when no array is traversed on the way down.

Returns the object itself.

## exists\_key(@key\_paths)

Checks whether the given keys exist in the nested structure. Array subscripts
are honoured: a subscript pointing past the end of an array, or to an undef
slot, is treated as non-existent.

Returns a list of boolean values (1 for exists, 0 for does not exist).

## as\_string()

Serializes the nested structure into a string using the specified format.

The `""` operator is overloaded to call this method, so the object may be
interpolated directly into strings.  Set `$Data::NestedKey::FORMAT` to change
the default format from JSON.

Returns a string representation of the data.

# AUTHOR

Rob Lauer <rlauer@treasurersbriefcase.com>

# SEE ALSO

[Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper), [JSON](https://metacpan.org/pod/JSON), [YAML::XS](https://metacpan.org/pod/YAML%3A%3AXS), [Storable](https://metacpan.org/pod/Storable)

# LICENSE

This library is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 480:

    Non-ASCII character seen before =encoding in '—'. Assuming UTF-8
