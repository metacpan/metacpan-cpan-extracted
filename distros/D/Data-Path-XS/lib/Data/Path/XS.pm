package Data::Path::XS;
use strict;
use warnings;

our $VERSION = '0.01';

use parent 'Exporter';
our @EXPORT_OK = qw(path_get path_set path_delete path_exists
                    patha_get patha_set patha_delete patha_exists
                    path_compile pathc_get pathc_set pathc_delete pathc_exists);

require XSLoader;
XSLoader::load('Data::Path::XS', $VERSION);

# Custom import to handle both Exporter and keyword hints
sub import {
    my $class = shift;
    my @args = @_;

    # Check for :keywords tag
    my $enable_keywords = 0;
    my @export_args;
    for my $arg (@args) {
        if ($arg eq ':keywords') {
            $enable_keywords = 1;
        } else {
            push @export_args, $arg;
        }
    }

    # Enable keyword hints if requested
    if ($enable_keywords) {
        $^H{"Data::Path::XS/pathget"} = 1;
        $^H{"Data::Path::XS/pathset"} = 1;
        $^H{"Data::Path::XS/pathdelete"} = 1;
        $^H{"Data::Path::XS/pathexists"} = 1;
    }

    # Forward to Exporter for function exports
    if (@export_args) {
        $class->export_to_level(1, $class, @export_args);
    }
}

sub unimport {
    my $class = shift;
    delete $^H{"Data::Path::XS/pathget"};
    delete $^H{"Data::Path::XS/pathset"};
    delete $^H{"Data::Path::XS/pathdelete"};
    delete $^H{"Data::Path::XS/pathexists"};
}

1;

__END__

=head1 NAME

Data::Path::XS - Fast path-based access to nested data structures

=head1 SYNOPSIS

    use Data::Path::XS qw(path_get path_set path_delete path_exists);

    my $data = { foo => { bar => [1, 2, 3] } };

    # String path API
    path_get($data, '/foo/bar/1');        # 2
    path_set($data, '/foo/bar/1', 42);    # sets to 42
    path_exists($data, '/foo/baz');       # 0
    path_delete($data, '/foo/bar/0');     # removes first element

    # Array path API - when path is already parsed
    use Data::Path::XS qw(patha_get patha_set);
    patha_get($data, ['foo', 'bar', 1]);  # 42
    patha_set($data, ['foo', 'new'], 'value');

    # Compiled path API - for repeated access patterns
    use Data::Path::XS qw(path_compile pathc_get pathc_set);
    my $cp = path_compile('/foo/bar/1');
    pathc_get($data, $cp);                # 42
    pathc_get($other_data, $cp);          # reuse on different data

    # KEYWORDS - Zero-overhead syntax (requires ':keywords')
    use Data::Path::XS ':keywords';

    my $val = pathget $data, "/foo/bar/1";     # fast custom op, no autovivification
    pathset $data, "/foo/bar/1", 99;           # with autovivification
    pathdelete $data, "/foo/bar/1";            # delete element
    if (pathexists $data, "/foo/bar") { ... }  # check existence

=head1 DESCRIPTION

Minimal XS module for fast access to deeply nested Perl data structures
using slash-separated paths. Provides four APIs optimized for different
use cases:

=over 4

=item * B<Keywords API> - Near-native performance via compile-time optimization

=item * B<String API> (path_*) - Best general-purpose performance

=item * B<Array API> (patha_*) - When path components are already parsed

=item * B<Compiled API> (pathc_*) - Maximum speed for repeated access patterns

=back

=head1 KEYWORDS API

The keywords API provides near-native performance through compile-time
optimized custom ops (or native Perl ops for C<pathset> with constant paths).

    use Data::Path::XS ':keywords';

=head2 pathget DATA, PATH

Get a value from a nested data structure. Returns undef for missing paths
without autovivifying intermediate levels.

    my $val = pathget $data, "/users/0/name";

=head2 pathset DATA, PATH, VALUE

Set a value with autovivification support. Returns the value set.

    pathset $data, "/users/0/name", "Alice";

Intermediate structures are created automatically (hashes for string keys,
arrays for numeric indices). If an existing intermediate value is not a
reference, it is silently replaced with the appropriate container type.

=head2 pathdelete DATA, PATH

Delete a value and return the deleted value.

    my $old = pathdelete $data, "/users/0/name";

=head2 pathexists DATA, PATH

Check if a path exists (returns true/false).

    if (pathexists $data, "/users/0/name") {
        print "User has a name\n";
    }

=head2 Constant vs Dynamic Paths

For C<pathset> with constant string paths, the keyword compiles directly to
native Perl assignment ops with autovivification - zero overhead. Because
this uses Perl's native ops, error messages differ from the dynamic-path
form (e.g. "Not a HASH reference" vs "Cannot navigate to path"), and
attempting to traverse a non-reference intermediate will croak rather than
silently replacing it.

All other keywords and dynamic paths use optimized custom ops. C<pathget>,
C<pathexists>, and C<pathdelete> never autovivify intermediate structures.
Dynamic C<pathset> autovivifies intermediates, including replacing
non-reference scalars.

All keyword forms achieve near-native performance.

=head1 STRING PATH API

=head2 path_get($data, $path)

Returns value at path, or undef if not found. Empty path returns root.

    path_get($data, '/foo/bar');  # deep access
    path_get($data, '');          # returns $data

=head2 path_set($data, $path, $value)

Sets value at path. Creates intermediate hashes/arrays as needed.
Numeric keys create arrays, string keys create hashes.
Returns the value set.

    path_set($data, '/foo/bar', 42);
    path_set($data, '/items/0/name', 'first');  # creates array

=head2 path_delete($data, $path)

Deletes value at path. Returns deleted value or undef if not found.

    my $old = path_delete($data, '/foo/bar');

=head2 path_exists($data, $path)

Returns 1 if path exists, 0 otherwise. Empty path always exists.

    if (path_exists($data, '/foo/bar')) { ... }

=head1 ARRAY PATH API

Functions that accept path as an arrayref of components. Useful when
path components are already parsed or contain special characters.

=head2 patha_get($data, \@path)

    patha_get($data, ['foo', 'bar', 0]);
    patha_get($data, []);  # returns root

=head2 patha_set($data, \@path, $value)

    patha_set($data, ['foo', 'bar'], 42);

=head2 patha_delete($data, \@path)

    patha_delete($data, ['foo', 'bar']);

=head2 patha_exists($data, \@path)

    patha_exists($data, ['foo', 'bar']);

=head1 COMPILED PATH API

Pre-compile paths for maximum performance when accessing the same path
repeatedly on different data structures. Compiled paths eliminate
parsing overhead and pre-compute array indices.

=head2 path_compile($path)

Compiles a path string into a reusable compiled path object.

    my $cp = path_compile('/users/0/name');

=head2 pathc_get($data, $compiled)

    my $cp = path_compile('/deep/path/here');
    for my $record (@records) {
        my $val = pathc_get($record, $cp);  # no parsing each time
    }

=head2 pathc_set($data, $compiled, $value)

    pathc_set($data, $cp, 'new value');

=head2 pathc_delete($data, $compiled)

    pathc_delete($data, $cp);

=head2 pathc_exists($data, $compiled)

    pathc_exists($data, $cp);

=head1 PATH FORMAT

=over 4

=item * Leading "/" is optional (e.g., "/foo/bar" and "foo/bar" are equivalent)

=item * Empty string or "/" refers to root

=item * Components are separated by "/"

=item * Numeric components access array elements (including negative indices)

=item * No escaping - keys containing "/" cannot be used with string API;
use array API instead

=item * Empty string keys ("") cannot be accessed via string API; use array API:
C<patha_get($data, [''])>

=back

=head1 EDGE CASES

=head2 Empty Paths

An empty path ("" or "/") refers to the root data structure:

    path_get($data, "");   # returns $data
    path_get($data, "/");  # returns $data
    path_get($data, "foo/bar");  # same as "/foo/bar"
    path_exists($data, ""); # returns 1 (root always exists)
    path_set($data, "", $v); # croaks - cannot set root
    path_delete($data, ""); # croaks - cannot delete root

=head2 Negative Array Indices

Negative indices work like Perl's native array access:

    my $data = { arr => ['a', 'b', 'c'] };
    path_get($data, '/arr/-1');  # 'c' (last element)
    path_get($data, '/arr/-2');  # 'b' (second to last)
    path_set($data, '/arr/-1', 'z');  # sets last element

Out-of-bounds negative indices return undef (or false for exists).

=head2 Leading Zeros

Numeric strings with leading zeros are treated as hash keys, not array indices:

    path_get($data, '/arr/007');  # looks up $data->{arr}{007}, not $data->{arr}[7]
    path_get($data, '/arr/0');    # accesses $data->{arr}[0] (single zero is valid)

=head2 Integer Overflow

Indices longer than 18 digits (9 on 32-bit perls) are treated as hash keys
to prevent overflow:

    path_get($data, '/arr/12345678901234567890');  # hash key, not array index

=head1 THREAD SAFETY

This module is designed for single-threaded use. It does not use any global
state and should work correctly in a threaded environment where each thread
has its own data structures, but no thread-safety guarantees are made for
shared data structures.

B<Compiled paths> hold an internal copy of the path string and should not
be shared across threads. Create separate compiled path objects in each thread
if needed.

=head1 PERFORMANCE

Benchmarks show XS implementation is 10-25x faster than pure Perl for
deep paths, and competitive with native Perl hash/array access.

For hot paths accessed repeatedly, the compiled API provides additional
20-35% speedup over the string API by eliminating parsing overhead.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
