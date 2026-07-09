package Data::NDArray::Shared;
use strict;
use warnings;
use Carp ();
our $VERSION = '0.02';
require XSLoader;
XSLoader::load('Data::NDArray::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)

*numel = \&size;
*flat  = \&to_list;

# ---------------------------------------------------------------------------
# PDL interop.  PDL is an optional, load-on-demand dependency (no build or
# runtime prereq).  Each dtype maps to a PDL type of the SAME byte width, so the
# data copies/aliases with no element conversion.  NOTE the axis order: this
# array is row-major C-order while PDL's dim(0) is the fastest-varying axis, so
# shapes are reversed across the boundary -- an (r, c) array <-> PDL dims (c, r).
# ---------------------------------------------------------------------------
my %PDL_TYPE = (   # dtype => PDL type-constructor name
    f64 => 'double',    f32 => 'float',
    i64 => 'longlong',  i32 => 'long',   i16 => 'short',  i8 => 'sbyte',
    u64 => 'ulonglong', u32 => 'ulong',  u16 => 'ushort', u8 => 'byte',
);
my %DTYPE_OF = reverse %PDL_TYPE;   # PDL type name => dtype

sub _require_pdl {
    eval { require PDL; 1 }
        or Carp::croak("Data::NDArray::Shared: PDL interop needs PDL installed (cpanm PDL)");
}
sub _pdl_ctor {
    my ($dtype) = @_;
    my $name = $PDL_TYPE{$dtype} or Carp::croak("no PDL type for dtype '$dtype'");
    exists &{"PDL::$name"}
        or Carp::croak("this PDL has no '$name' type (needed for dtype '$dtype'); upgrade PDL");
    \&{"PDL::$name"};
}

# NDArray -> a NEW (copied) PDL piddle; dims = reverse(shape).
sub to_pdl {
    my ($self) = @_;
    _require_pdl();
    my $p = PDL->new_from_specification(_pdl_ctor($self->dtype)->(), reverse $self->shape);
    ${ $p->get_dataref } = $self->buffer;   # read-locked snapshot
    $p->upd_data;
    return $p;
}

# A NEW shared NDArray copied from a piddle; $path undef => anonymous mapping.
sub from_pdl {
    my ($class, $p, $path) = @_;
    _require_pdl();
    my $tname = "" . $p->type;
    my $dt = $DTYPE_OF{$tname}
        or Carp::croak("Data::NDArray::Shared->from_pdl: unsupported PDL type '$tname'");
    $p = $p->copy;                          # force a contiguous, physical piddle
    my $self = $class->new($path, $dt, reverse $p->dims);
    $self->update_from_bytes(${ $p->get_dataref });
    return $self;
}

# Copy a piddle into THIS array in place (same dtype + shape); returns self.
sub update_from_pdl {
    my ($self, $p) = @_;
    _require_pdl();
    my $tname = "" . $p->type;
    my $dt = $DTYPE_OF{$tname}
        or Carp::croak("Data::NDArray::Shared->update_from_pdl: unsupported PDL type '$tname'");
    $dt eq $self->dtype
        or Carp::croak("update_from_pdl: dtype mismatch (piddle $dt vs array " . $self->dtype . ")");
    my @want = reverse $self->shape;
    my @got  = $p->dims;
    "@want" eq "@got"
        or Carp::croak("update_from_pdl: shape mismatch (array (@{[ $self->shape ]}) vs piddle dims (@got))");
    $p = $p->copy;
    $self->update_from_bytes(${ $p->get_dataref });
    return $self;
}

# Zero-copy: a PDL ndarray ALIASING this array's shared mmap, built via PDL's C
# API (PDL_DONTTOUCHDATA, so PDL never frees/reallocates our mapping).  In-place
# PDL ops write straight through (visible to every sharing process); reads see
# live data.  NO locking -- coordinate access yourself.  The array is kept alive
# while the piddle lives.  Needs PDL at BUILD time (the C path); croaks otherwise.
sub as_pdl_alias {
    my ($self) = @_;
    _require_pdl();
    my $typenum = _pdl_ctor($self->dtype)->()->enum;        # PDL type number for our dtype
    # _alias_pdl_create croaks if the module was built without PDL (no C path).
    my $p = $self->_alias_pdl_create($typenum, [ reverse $self->shape ]);   # dims in PDL order
    $p->hdr->{_nda_shared} = $self;   # keep the mapping alive while the piddle lives
    return $p;
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::NDArray::Shared - shared-memory typed N-dimensional numeric array for Linux

=head1 SYNOPSIS

    use Data::NDArray::Shared;

    # a 2x3 array of doubles in an anonymous shared mapping
    # ($path = undef for an anonymous array)
    my $a = Data::NDArray::Shared->new(undef, "f64", 2, 3);

    $a->ndim;        # 2
    $a->size;        # 6   (== 2 * 3, also ->numel)
    $a->shape;       # (2, 3)
    $a->strides;     # (3, 1)   row-major, in elements
    $a->dtype;       # "f64"
    $a->itemsize;    # 8

    $a->set(0, 0, 1.5);          # element [0][0] = 1.5  (multi-index)
    $a->get(0, 0);               # 1.5
    $a->set_flat(5, 9);          # last element by flat index
    $a->get_flat(5);             # 9

    $a->fill(7);                 # every element = 7
    $a->zero;                    # every element = 0

    $a->sum;  $a->mean;  $a->min;  $a->max;   # whole-array reductions

    $a->add_scalar(2);           # every element += 2   (in place)
    $a->mul_scalar(3);           # every element *= 3   (in place)

    $a->reshape(3, 2);           # same data, shape (3,2), strides (2,1)

    # element-wise array arithmetic (same dtype + total size), in place
    my $b = Data::NDArray::Shared->new(undef, "f64", 3, 2);
    $a->add($b);                 # a[i] += b[i]
    $a->subtract($b);            # a[i] -= b[i]
    $a->multiply($b);            # a[i] *= b[i]

    my $list = $a->to_list;      # arrayref of all elements, row-major

    # integer dtypes: i64/i32/i16/i8/u64/u32/u16/u8
    my $c = Data::NDArray::Shared->new(undef, "u8", 4);
    $c->set_flat(0, 300);        # wraps to 44 (stored in the element width)

    # share across processes via a backing file ($path = the file)
    my $shared = Data::NDArray::Shared->new("/tmp/nd.bin", "f64", 100, 100);

=head1 DESCRIPTION

A dense, row-major numeric tensor in shared memory, shared across processes. The
array has a B<fixed dtype> (one of C<f64>, C<f32>, C<i64>, C<i32>, C<i16>,
C<i8>, C<u64>, C<u32>, C<u16>, C<u8>), a B<fixed shape> of 1 to 8 dimensions,
and the matching B<row-major strides> (in elements). The elements live
contiguously in a shared mapping, so several processes share one array: any
process that opens the same backing file, inherits the anonymous mapping across
C<fork>, or reopens a passed memfd, sees the same data.

Supported operations:

=over 4

=item *

B<Indexed access> -- C<get(@idx)> / C<set(@idx, $val)> by a full multi-index,
and C<get_flat($e)> / C<set_flat($e, $val)> by a single linear (row-major)
index C<0 .. size-1>.

=item *

B<Bulk fills> -- C<fill($val)> sets every element; C<zero> sets every element to
zero.

=item *

B<reshape(@newshape)> -- change the shape B<without copying data>; the total
element count must be unchanged. Strides are recomputed row-major.

=item *

B<Reductions> -- C<sum>, C<mean> (both return a floating-point number computed by
double accumulation), C<min> and C<max> (return the actual extreme element in the
dtype-correct type).

=item *

B<In-place scalar arithmetic> -- C<add_scalar($s)> and C<mul_scalar($s)> apply
C<element OP $s> to every element.

=item *

B<In-place element-wise array arithmetic> -- C<add>, C<subtract> and
C<multiply> combine the receiver with another C<Data::NDArray::Shared> of the
B<same dtype and same total size>, element by element.

=back

Values are stored in the element type. For the integer dtypes, a value that does
not fit the element width B<wraps/truncates> to that width per C cast rules
(storing 300 into a C<u8> yields 44); the caller is responsible for fitting
values to the dtype. Float dtypes store the nearest representable value
(C<f32> loses precision relative to a Perl NV). All arithmetic on integer
dtypes is performed in the element's integer type (so it can overflow/wrap);
float dtypes accumulate reductions in C<double>.

A write-preferring futex rwlock with dead-process recovery guards every
mutation, so writes from many processes serialize cleanly. The immutable header
fields C<dtype>, C<size>, and C<itemsize> are immutable; C<ndim>, C<shape>, and
C<strides> can change under C<reshape> (which holds the write lock), so element
access reads them under the read lock. B<Linux-only>. Requires 64-bit Perl.

=head1 METHODS

=head2 Constructors

    my $a = Data::NDArray::Shared->new($path, $dtype, @shape);     # file-backed
    my $a = Data::NDArray::Shared->new(undef, $dtype, @shape);     # anonymous
    my $a = Data::NDArray::Shared->new_memfd($name, $dtype, @shape);
    my $a = Data::NDArray::Shared->new_memfd(undef, $dtype, @shape);
    my $a = Data::NDArray::Shared->new_from_fd($fd);

C<$path> is the backing file (C<undef> for an anonymous mapping); C<$dtype> is
the dtype name (C<f64>, C<i32>, ...); and C<@shape> is the shape:
C<< ($path, $dtype, @shape) >>. C<new_memfd> takes the memfd label as its
leading argument instead of a path (C<undef> for an unnamed memfd):
C<< ($name, $dtype, @shape) >>.

C<@shape> must have 1 to 8 dimensions, each C<< >= 1 >>. The constructor croaks
on an B<unknown dtype>, on B<no dimensions> or a B<zero/negative dimension>, on
B<more than 8 dimensions>, or if the implied data buffer
(C<product(shape) * itemsize>) would overflow or exceed an internal 1 TiB cap
(C<shape too large>). A freshly created array is B<zero-filled>.

When reopening an existing file or memfd, the B<stored dtype, shape and strides
win> and the existing data is preserved; the dtype/shape you pass to C<new> on a
reopen are only used when the file is brand new. C<new_memfd> creates a Linux
memfd (transferable via its C<memfd> descriptor); C<new_from_fd> reopens one in
another process.

=head2 Element access

    my $v = $a->get(@idx);            # element at the full multi-index
    $a->set(@idx, $val);              # write the element at the multi-index
    my $v = $a->get_flat($e);         # element at flat (row-major) index $e
    $a->set_flat($e, $val);           # write the element at flat index $e

C<get>/C<set> take exactly C<ndim> indices; each index must be in
C<< 0 .. shape[d]-1 >>. The flat index for C<get_flat>/C<set_flat> must be in
C<< 0 .. size-1 >>. A wrong index count or an out-of-range index is rejected
under the read lock, which is released before the croak, so a caught croak
never leaks a lock. C<get> and
C<get_flat> return the B<dtype-correct> scalar (a floating-point number for
float dtypes, a signed integer for the signed-int dtypes, an unsigned integer
for the unsigned-int dtypes). C<set>/C<set_flat> store the value in the element
type, B<wrapping> integer values to the element width (see L</DESCRIPTION>).

Indices must be non-negative integers in C<< 0 .. shape-1 >>; a negative index
is treated as a large unsigned value and croaks out of range.

=head2 Bulk fills

    $a->fill($val);                   # every element = $val  (returns $a)
    $a->zero;                         # every element = 0     (returns $a)

C<fill> writes the typed value of C<$val> to every element (integers wrap to the
element width). C<zero> sets the whole buffer to zero. Both return the array for
chaining.

=head2 reshape

    $a->reshape(@newshape);           # returns $a

C<reshape> changes the shape B<in place without moving any data>: the flat,
row-major sequence of elements is unchanged; only C<shape>, C<strides> and
C<ndim> are updated (strides recomputed row-major). The product of C<@newshape>
must equal the current C<size>, and the new rank must be 1 to 8; otherwise it
croaks. Returns the array for chaining.

=head2 Reductions

    my $s = $a->sum;                  # floating-point sum  (double accumulation)
    my $m = $a->mean;                 # $s / size
    my $lo = $a->min;                 # smallest element, dtype-correct
    my $hi = $a->max;                 # largest  element, dtype-correct

C<sum> and C<mean> always return a floating-point number: every element is read
as a C<double> and accumulated, so for the 64-bit integer dtypes a very large
sum may lose integer precision. C<min> and C<max> return the actual extreme
B<element value> in its native dtype (so an C<i64> min is exact). The array
always has at least one element, so these never operate on an empty array.

=head2 Scalar arithmetic (in place)

    $a->add_scalar($s);               # element += $s for every element
    $a->mul_scalar($s);               # element *= $s for every element

Each applies the operation to every element B<in the element's own arithmetic>:
float dtypes compute in floating point; integer dtypes compute in the element's
integer type (and therefore wrap on overflow). Both return the array for
chaining.

=head2 Element-wise array arithmetic (in place)

    $a->add($b);                      # a[i] += b[i]
    $a->subtract($b);                 # a[i] -= b[i]
    $a->multiply($b);                 # a[i] *= b[i]

Each combines the receiver with another C<Data::NDArray::Shared> element by
element, storing the result back into the receiver. The other array must have
the B<same dtype> and the B<same total size> (its shape need not match, only the
element count); a mismatch croaks B<before> any lock is taken. Self-application
is allowed and meaningful: C<< $a->add($a) >> doubles, C<< $a->subtract($a) >>
zeroes, C<< $a->multiply($a) >> squares. Each returns the receiver for chaining.

Locking is deadlock-free across processes: the two arrays' locks are acquired in
a globally consistent order keyed on a per-array shared identity, with the
receiver taking the write lock and the other the read lock. Two unrelated
processes performing C<< X->add(Y) >> and C<< Y->add(X) >> concurrently cannot
deadlock.

=head2 Whole-array list

    my $aref = $a->to_list;           # arrayref of all elements, row-major
    my $aref = $a->flat;              # alias for to_list

C<to_list> (aliased C<flat>) returns a new array reference holding every
element in flat row-major order, each as the dtype-correct scalar.

=head2 Accessors

    $a->dtype;        # dtype name string, e.g. "f64"
    $a->ndim;         # number of dimensions
    $a->size;         # total element count   (also ->numel)
    $a->itemsize;     # bytes per element
    $a->shape;        # list of dimension sizes
    $a->strides;      # list of row-major strides (in elements)

All read immutable (or reshape-updated) header fields. C<size> (aliased
C<numel>) and C<itemsize> never change; C<shape>/C<strides>/C<ndim> change only
under C<reshape>.

=head2 Lifecycle

    $a->path; $a->memfd; $a->sync; $a->unlink;   # or Class->unlink($path)

C<sync> flushes the mapping to its backing store (a no-op for anonymous and
memfd arrays, which have none); C<unlink> removes the backing file (also callable
as C<< Class->unlink($path) >>); C<path> returns the backing path (C<undef> for
anonymous, memfd, or fd-reopened arrays); C<memfd> returns the backing descriptor
-- the memfd of a C<new_memfd> array or the dup'd fd of a C<new_from_fd> array,
and -1 for file-backed or anonymous arrays.

=head1 STATS

C<stats()> returns a hashref describing the array:

=over 4

=item * C<dtype> -- the dtype name string.

=item * C<ndim> -- the number of dimensions.

=item * C<size> -- the total element count.

=item * C<itemsize> -- bytes per element.

=item * C<shape> -- an arrayref of the dimension sizes.

=item * C<ops> -- running count of operations that took the write lock (every
C<set>, C<set_flat>, C<fill>, C<zero>, C<reshape>, C<add_scalar>,
C<mul_scalar>, C<add>, C<subtract>, C<multiply>).

=item * C<mmap_size> -- bytes of the shared mapping.

=back

=head1 PDL INTEROP

If L<PDL> is installed the array converts to and from PDL ndarrays. PDL is an
B<optional, load-on-demand> dependency -- there is no build- or runtime prereq;
the four conversion methods (C<to_pdl>, C<from_pdl>, C<update_from_pdl>,
C<as_pdl_alias>) C<croak> if PDL is missing, while C<buffer> and
C<update_from_bytes> have no PDL dependency. Each dtype maps to a PDL type of
the B<same byte width> (C<f64> to C<double>, C<i32> to C<long>, C<u64> to
C<ulonglong>, and so on), so the data moves with no per-element conversion.

B<Axis order:> this array is row-major (C-order) while PDL's C<dim(0)> is the
B<fastest-varying> axis, so the shape is B<reversed> across the boundary -- an
C<($r, $c)> array corresponds to PDL dims C<($c, $r)>, and
C<< $piddle-E<gt>at($j, $i) >> is C<< $array-E<gt>get($i, $j) >>. The conversion
methods handle this for you.

=over 4

=item * C<< $piddle = $array->to_pdl >>

A B<new> piddle holding a B<copy> of the data, of the mapped PDL type and dims
C<< reverse($array-E<gt>shape) >>. Read under the lock, so it is a consistent
snapshot.

=item * C<< $array = Data::NDArray::Shared->from_pdl($piddle, $path) >>

A B<new> shared array B<copied> from C<$piddle> (made physical and contiguous
first); the dtype and shape follow the piddle's type and C<reverse> of its dims.
C<$path> is the backing file (C<undef> or omitted for an anonymous mapping).

=item * C<< $array->update_from_pdl($piddle) >>

Copy C<$piddle> into this array B<in place> (write-locked). The piddle's type
must match the dtype and its dims must equal C<< reverse($array-E<gt>shape) >>,
else it croaks. Returns the array.

=item * C<< $piddle = $array->as_pdl_alias >>

A piddle that B<aliases the shared mapping with no copy> (a real
C<PDL_DONTTOUCHDATA> ndarray over our memory): an B<in-place> PDL operation
(C<< $p .= ... >>, C<< $p-E<gt>inplace-E<gt>... >>) writes straight through to
shared memory -- visible to every process that maps it -- and reads see live
data. The array is kept alive for as long as the piddle.

This one method needs PDL at B<build> time (it is compiled against PDL's C API):
if the module was installed without PDL present it C<croak>s, while the copy
methods above keep working through a runtime C<require PDL>. Reinstall with PDL
installed to enable it.

B<Caveats.> The alias B<bypasses the rwlock>: you must coordinate access
yourself (no other process mutating concurrently), as with any unlocked
shared-memory view. Do not B<resize or retype> the alias (a reshape that grows
it, a type conversion) -- it is a fixed window onto the mapping; use
C<to_pdl>/C<from_pdl> when you want an independent, resizable copy.

=item * C<< $bytes = $array->buffer >>

The raw contiguous data region as a byte string (read-locked snapshot),
row-major C-order -- useful on its own for serialization or IPC, and the basis
for C<to_pdl>. C<< $array->update_from_bytes($bytes) >> is the inverse
(write-locked; the string must be exactly C<< size * itemsize >> bytes).

=back

See F<eg/pdl_interop.pl> for a worked example, including a cross-process PDL
transform on one shared array.

=head1 SHARING ACROSS PROCESSES

The array lives in a shared mapping, shared the same three ways as the rest of
the family: a B<backing file> (every process calls C<< new($path, $dtype,
@shape) >> on the same path), an B<anonymous mapping inherited across C<fork>>,
or a B<memfd> whose descriptor is passed to an unrelated process (over a UNIX
socket via C<SCM_RIGHTS>, or via C</proc/$pid/fd/$n>) and reopened with
C<< new_from_fd($fd) >>. Because the mapping is shared, B<every process reads and
writes the same elements>. All mutation is serialized by the write lock, so a
set of disjoint writers produces a well-defined final array regardless of how
they interleave.

    # parent and children fill disjoint slices of one shared array
    my $a = Data::NDArray::Shared->new(undef, "f64", 4000);   # before fork
    unless (fork) { $a->set_flat($_, $_) for 0 .. 999; exit }
    wait;
    print $a->get_flat(500), "\n";   # reflects the child's writes

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default, so only the
creating user can open and attach them. To share a backing file across users,
pass an explicit octal file mode such as C<0660> via a C<< mode => 0660 >> option to C<new>; the mode is applied
only when the file is created (an existing file keeps its own permissions). The
file is opened with C<O_NOFOLLOW>, so a symlink planted at the path is refused,
and created with C<O_EXCL>; the on-disk header is validated when the file is
attached. Any process you grant write access to a shared mapping is trusted not
to corrupt its contents while other processes are using it.

=head1 CRASH SAFETY

Mutation is guarded by a futex-based write-preferring rwlock with PID-encoded
ownership; if a holder dies, the next contender detects the dead owner and
recovers. Because each mutation updates the data buffer (and, for C<reshape>, a
few header words) while holding the lock, a crash leaves the array consistent up
to the last completed operation. B<Limitation>: PID reuse is not detected (very
unlikely in practice).

=head1 SEE ALSO

L<Data::Histogram::Shared>, L<Data::RoaringBitmap::Shared>,
L<Data::DisjointSet::Shared>, L<Data::CountMinSketch::Shared>,
L<Data::HyperLogLog::Shared>, L<Data::BloomFilter::Shared>,
L<Data::Intern::Shared>, L<Data::SortedSet::Shared>,
L<Data::SpatialHash::Shared>, and the rest of the C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
