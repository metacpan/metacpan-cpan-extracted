package Data::Path::XS;
use strict;
use warnings;

our $VERSION = '0.03';

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

=encoding utf8

=head1 NAME

Data::Path::XS - Fast path-based access to nested data structures

=head1 SYNOPSIS

    use Data::Path::XS qw(path_get path_set path_delete path_exists);

    my $data = { foo => { bar => [1, 2, 3] } };

    path_get   ($data, '/foo/bar/1');         # 2
    path_set   ($data, '/foo/bar/1', 42);     # 42 (returns the value set)
    path_exists($data, '/foo/baz');           # 0
    path_delete($data, '/foo/bar/0');         # 1 (returns the deleted value)

    # Pre-parsed path components (binary-safe; allows "/" in keys)
    use Data::Path::XS qw(patha_get patha_set);
    patha_get($data, ['foo', 'bar', 1]);
    patha_set($data, ['foo', 'new'], 'value');

    # Pre-compiled paths for hot loops
    use Data::Path::XS qw(path_compile pathc_get);
    my $cp    = path_compile('/foo/bar/1');
    my $other = { foo => { bar => [4, 5, 6] } };
    pathc_get($data,  $cp);                   # 42
    pathc_get($other, $cp);                   # 5 — reuse across data

    # Keyword syntax (compile-time optimized)
    use Data::Path::XS ':keywords';

    my $v = pathget    $data, "/foo/bar/1";
    pathset            $data, "/foo/bar/1", 99;
    pathdelete         $data, "/foo/bar/1";
    print "ok\n" if pathexists $data, "/foo/bar";

=head1 DESCRIPTION

Fast XS access to deeply nested Perl data structures via slash-separated
paths (similar shape to JSON Pointer, but without RFC 6901's C<~0>/C<~1>
escaping). Four parallel APIs let you trade ergonomics against speed:

=over 4

=item * L</STRING PATH API> - C<path_*>, the general-purpose entry point.

=item * L</ARRAY PATH API> - C<patha_*>, when path components are already
parsed or may contain C</> or other special characters.

=item * L</COMPILED PATH API> - C<path_compile> + C<pathc_*>, when the
same path is reused many times on different data.

=item * L</KEYWORDS API> - C<pathget>/C<pathset>/etc. as syntax via
L<XS::Parse::Keyword>, compiled to inline custom ops or (where possible)
native Perl assignment ops.

=back

All four APIs share the same path syntax (L</PATH FORMAT>) and the same
container-dispatch semantics (L</Numeric vs String Keys>).

=head1 IMPORTING

    use Data::Path::XS qw(path_get path_set ...);   # function exports
    use Data::Path::XS ':keywords';                  # enable keyword syntax
    use Data::Path::XS ':keywords', qw(path_get);    # both

The C<:keywords> tag installs lexically-scoped keyword hints; the keywords
are visible only inside the importing scope. C<no Data::Path::XS;> removes
them. Function exports follow standard L<Exporter> rules.

=head1 PATH FORMAT

=over 4

=item *

Components are separated by C</>. A leading C</> is optional:
C<"/foo/bar"> and C<"foo/bar"> are equivalent.

=item *

An empty string or C<"/"> refers to the root. Repeated and trailing
slashes (C<"//foo//">) are tolerated and yield the same components.

=item *

Numeric components I<may> address array elements when the parent
container is an array; on a hash parent the same string is treated as a
hash key. See L</Numeric vs String Keys>.

=item *

Negative indices work like Perl's native array access (C<-1> is the last
element). See L</Negative Array Indices>.

=item *

No escaping is provided in the string API: keys containing C</> or the
empty string cannot be expressed in a string path. Use the array API
(e.g. C<< patha_get($data, ['', 'a/b']) >>) for those.

=item *

UTF-8 keys are propagated correctly. The path SV's C<SvUTF8> flag (or,
in the array API, each key SV's flag) is forwarded to C<hv_fetch>/
C<hv_store> so C<"/café"> matches hash keys stored under C<use utf8>.

=back

=head2 Numeric vs String Keys

All four APIs dispatch by B<parent container type>, not by key shape:

    my $h = { '0' => 'zero' };
    path_get($h, '/0');               # 'zero' - hash key
    pathget $h, "/0";                 # 'zero' - same

    my $a = ['x', 'y', 'z'];
    path_get($a, '/0');               # 'x' - array index
    pathget $a, "/0";                 # 'x' - same

When autovivifying a missing intermediate, the type to create is chosen
by the B<next> component's shape: a numeric next component creates an
array, otherwise a hash.

=head1 STRING PATH API

=head2 path_get($data, $path)

Returns the value at C<$path>, or C<undef> if any component is missing.
An empty path returns C<$data> itself. Never autovivifies.

    path_get($data, '/foo/bar');
    path_get($data, '');               # returns $data

=head2 path_set($data, $path, $value)

Stores C<$value> at C<$path>, creating intermediate hashes/arrays as
needed (see L</Numeric vs String Keys> for the type-decision rule).
Existing non-reference scalars at intermediate positions are silently
replaced. Returns C<$value>. Croaks on an empty path or on a path that
cannot be navigated (e.g. through a tied container, see L</Tied
containers>).

    path_set($data, '/foo/bar', 42);
    path_set($data, '/items/0/name', 'first');   # autovivifies array

=head2 path_delete($data, $path)

Deletes the value at C<$path> and returns it, or C<undef> if not found.
Croaks on an empty path.

    my $old = path_delete($data, '/foo/bar');

=head2 path_exists($data, $path)

Returns C<1> if C<$path> resolves to an existing element (using
C<exists> semantics: explicit C<undef> values count as existing), C<0>
otherwise. The empty path always exists.

    do_thing() if path_exists($data, '/foo/bar');

=head1 ARRAY PATH API

The C<patha_*> functions take an arrayref of components instead of a
slash-separated string. Use this when path pieces are already parsed,
when keys may contain C</>, or when you want to address an empty-string
key (C<< [''] >>).

Each key SV's C<SvUTF8> flag is honoured per component.

=head2 patha_get($data, \@path)

    patha_get($data, ['foo', 'bar', 0]);
    patha_get($data, []);             # returns $data

=head2 patha_set($data, \@path, $value)

    patha_set($data, ['foo', 'bar'], 42);

=head2 patha_delete($data, \@path)

    patha_delete($data, ['foo', 'bar']);

=head2 patha_exists($data, \@path)

    patha_exists($data, ['foo', 'bar']);

=head1 COMPILED PATH API

Pre-compile a path once, then reuse it for many lookups. The compiled
object holds parsed components, pre-computed array indices, and the
UTF-8 flag, so per-call overhead drops to the navigation itself.

=head2 path_compile($path)

Returns a compiled path object (a blessed reference). The object owns
its own copy of the path string, so the caller may freely mutate or
discard the source SV.

    my $cp = path_compile('/users/0/name');

=head2 pathc_get($data, $compiled)

    for my $record (@records) {
        my $val = pathc_get($record, $cp);
    }

=head2 pathc_set($data, $compiled, $value)

    pathc_set($data, $cp, 'new value');

=head2 pathc_delete($data, $compiled)

    pathc_delete($data, $cp);

=head2 pathc_exists($data, $compiled)

    pathc_exists($data, $cp);

=head1 KEYWORDS API

    use Data::Path::XS ':keywords';

The keywords compile to either an inline custom op or, where the path
allows, native Perl assignment ops. They never call into XSUB
dispatch and so reach near-native speed.

=head2 pathget DATA, PATH

Get a value. Returns C<undef> for missing paths and never autovivifies.

    my $val = pathget $data, "/users/0/name";

=head2 pathset DATA, PATH, VALUE

Set a value, autovivifying intermediates as needed. Returns C<VALUE>.

    pathset $data, "/users/0/name", "Alice";

=head2 pathdelete DATA, PATH

Delete a value and return it.

    my $old = pathdelete $data, "/users/0/name";

=head2 pathexists DATA, PATH

True if C<PATH> exists.

    print "found\n" if pathexists $data, "/users/0/name";

=head2 Constant vs Dynamic Paths

When C<pathset> is called with a compile-time constant path that

=over 4

=item *

contains only string components (no numeric pieces), and

=item *

does not carry the C<SvUTF8> flag (i.e. is not authored under
C<use utf8>),

=back

the keyword compiles directly to a native HELEM-chain assignment with
autovivification - zero per-call overhead. Because this uses Perl's
native ops:

=over 4

=item *

error messages match Perl's (e.g. C<"Not a HASH reference">) rather
than this module's (C<"Cannot navigate to path">), and

=item *

a non-reference intermediate causes a croak rather than being silently
replaced.

=back

In every other case (numeric component, UTF-8 path, non-constant path),
the keyword falls through to a custom op with the same semantics as
C<path_set>.

The other three keywords (C<pathget>, C<pathexists>, C<pathdelete>)
always use custom ops.

=head1 EDGE CASES

=head2 Empty Paths

The empty path (C<"">, C<"/">, C<"///">) addresses the root:

    path_get   ($data, "");           # $data
    path_exists($data, "/");          # 1
    path_set   ($data, "", $v);       # croaks "Cannot set root"
    path_delete($data, "");           # croaks "Cannot delete root"

=head2 Negative Array Indices

Negative indices behave like Perl's:

    my $data = { arr => ['a', 'b', 'c'] };
    path_get($data, '/arr/-1');       # 'c'
    path_set($data, '/arr/-1', 'z');  # arr now ['a','b','z']

Out-of-range negative indices return C<undef> (or false for C<exists>).

=head2 Leading Zeros

Strings with leading zeros are treated as hash keys, not array indices:

    path_get($data, '/arr/007');      # $data->{arr}{007}
    path_get($data, '/arr/0');        # $data->{arr}[0] (single zero ok)

=head2 Integer Overflow

Indices with more than 18 digits (9 on 32-bit perls) are treated as
hash keys to prevent overflow:

    path_get($data, '/arr/12345678901234567890');  # hash key

=head1 LIMITATIONS

=head2 Tied containers

Read operations (C<path_get>, C<path_exists>, C<path_delete>, and their
array/compiled/keyword counterparts) work on tied hashes and arrays via
the standard fetch/exists/delete magic.

Write operations (C<path_set>, C<patha_set>, C<pathc_set>, and the
C<pathset> keyword) currently croak with a message of the form
C<"Cannot ... on tied/magical hash"> or C<"... on tied/magical array">,
rather than invoking the tied STORE method. For tied write targets,
assign through native Perl syntax. This limitation may be relaxed in a
future release.

=head1 THREAD SAFETY

The module uses no global state and is safe in threaded programs as
long as each thread operates on its own data. No locking is performed
on shared structures.

Compiled-path objects own internal buffers and should not be shared
across threads; create one per thread.

=head1 PERFORMANCE

Indicative numbers from F<bench/benchmark.pl> on a single sample run
(rate per second, higher is better):

    Operation                Pure Perl    Native Perl    Data::Path::XS
    ----------------------- ----------- -------------- -----------------
    path_get shallow            2.1 M/s        35.4 M/s          22.6 M/s
    path_get deep (5 levels)    0.8 M/s         7.0 M/s           8.6 M/s
    path_get missing key        1.3 M/s         4.4 M/s          14.7 M/s
    path_set deep existing      0.8 M/s         8.1 M/s           7.3 M/s
    pathget kw const shallow    -              37.5 M/s          42.2 M/s
    pathget kw const deep       -               7.3 M/s           8.5 M/s
    pathexists kw const deep    -               6.3 M/s          10.2 M/s

The keyword API matches or exceeds native Perl on most workloads. The
compiled API adds another ~20-35% on hot paths by skipping parsing.
Run F<bench/benchmark.pl> for a fuller comparison on your hardware.

=head1 SEE ALSO

=over 4

=item *

L<Data::Diver> - pure-Perl deep accessor with similar reach.

=item *

L<JSON::Pointer> - RFC 6901 path syntax (with C<~0>/C<~1> escaping)
over the same kinds of structures.

=item *

L<Data::DPath> - XPath-like queries over data.

=item *

L<XS::Parse::Keyword> - the keyword-plugin framework used to install
the C<pathget>/C<pathset>/C<pathdelete>/C<pathexists> syntax.

=back

=head1 AUTHOR

vividsnow

=head1 BUGS

Please report issues at
L<https://github.com/vividsnow/perl5-data-path-xs/issues>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
