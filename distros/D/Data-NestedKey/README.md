# NAME

Data::NestedKey - Object-oriented handling of deeply nested hash structures.

# SYNOPSIS

    use Data::NestedKey;

    my $nk = Data::NestedKey->new(
        'foo.bar.baz' => 42,
        'foo.bar.qux' => 'hello'
    );

    $nk->set('foo.bar.baz' => 99, 'foo.xyz' => [1, 2, 3]);
    my $baz = $nk->get('foo.bar.baz');
    $nk->delete('foo.bar.baz');
    print $nk->as_string();

# DESCRIPTION

Data::NestedKey provides an object-oriented approach to managing deeply nested 
hash structures using dot-separated keys. This allows structured data to be 
manipulated in a clean and intuitive way without requiring manual traversal 
of nested hashes.

While traditional hash manipulation requires explicitly iterating through nested 
structures, this module allows setting and retrieving values using simple text 
strings. The ability to specify a path using a single, dot-separated key improves 
readability, reduces boilerplate, and enhances efficiency when working with complex 
data structures.

A key motivation for this module is configuration file manipulation. Many applications 
use structured configuration files (e.g., JSON, YAML) where default settings exist, 
but some values require customization. This module enables modifying specific 
configuration elements using intuitive dot-separated keys, making updates more 
straightforward.

For example, given a JSON configuration file, a utility could allow:

    init-config foo.json session_files.dir /some/path

Where the command takes the configuration file name followed by key-value pairs 
representing the specific elements to update. This approach provides a simple 
and effective way to adjust settings without needing to manually traverse the 
configuration structure.

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

## new(\[$hash\_ref\], @kv\_list)

Creates a new Data::NestedKey object. If no arguments are provided, initializes 
with an empty structure. Optionally, an initial hash reference can be supplied. 
Key-value pairs may also be provided for immediate population.

Returns a `Data::NestedKey` object.

## set(@kv\_list)

Inserts, updates, appends, or removes values in the nested structure using dot-separated keys.

- If a key already exists and holds a scalar, assigning a new value will \*\*replace\*\* it.
- If the \`+\` prefix is used (e.g., \`+key\`), the value will be \*\*appended\*\*:

        $nk->set('foo.bar' => 1);
        $nk->set('+foo.bar' => 2);
        $nk->set('+foo.bar' => 3);
        # foo.bar now contains [1, 2, 3]

- If the \`+\` prefix is used with a hash, it merges keys instead of replacing:

        $nk->set('config' => { key1 => 'val1' });
        $nk->set('+config' => { key2 => 'val2' });
        # config now contains { key1 => 'val1', key2 => 'val2' }

- If the \`-\` prefix is used (e.g., \`-key\`), the value is \*\*removed\*\*:

        $nk->set('-foo.bar' => 2);
        # If foo.bar is an array, it removes element '2'
        # If foo.bar is a hash, it removes key '2'
        # Otherwise, it deletes foo.bar entirely

Returns the object itself.

## get(@key\_paths)

Retrieves values from the nested structure based on dot-separated keys.

Returns a list of values corresponding to the requested keys.

## delete(@key\_paths)

Removes the specified keys from the nested structure.

Returns the object itself.

## exists\_key(@key\_paths)

Checks whether the given keys exist in the nested structure.

Returns a list of boolean values (1 for exists, 0 for does not exist).

## as\_string()

Serializes the nested structure into a string using the specified format.

You can also use the "" to interpolate the object into its serialized
representation. Set the `$Data::NestedKey::FORAMAT` variable if you
want to change the default format from JSON to another format.

Returns a string representation of the data.

## clear()

Clears all stored data in the object.

Returns the object itself.

# AUTHORS

Rob Lauer <rlauer6@comcast.net>

# SEE ALSO

[Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper), [JSON](https://metacpan.org/pod/JSON), [YAML](https://metacpan.org/pod/YAML), [Storable](https://metacpan.org/pod/Storable)

# LICENSE

This library is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
