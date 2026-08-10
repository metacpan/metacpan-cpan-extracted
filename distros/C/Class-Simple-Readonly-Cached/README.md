# NAME

Class::Simple::Readonly::Cached - cache messages to an object

# VERSION

Version 0.13

# SYNOPSIS

A caching decorator for [Class::Simple](https://metacpan.org/pod/Class%3A%3ASimple)-based (and arbitrary) objects.

It is up to the caller to maintain the cache if the object comes out of
sync with the cache, for example by changing its state.

    use Class::Simple::Readonly::Cached;

    my $obj = Class::Simple->new();
    $obj->val('foo');
    my $cached = Class::Simple::Readonly::Cached->new(
        object => $obj,
        cache  => {},
    );

    my $val  = $cached->val();   # calls the real object
    my $val2 = $cached->val();   # served from cache

    $val = $cached->val(a => 'b');   # args form part of the cache key

Note that when the object goes out of scope (DESTROY is called), the
cache is cleared automatically.

# DESCRIPTION

Wraps any Perl object in a transparent caching layer.  Every method call
is intercepted via AUTOLOAD; on the first call (a _miss_) the result is
stored in the cache and returned.  Subsequent identical calls (same method
name, same argument list) are _hits_ and are served directly from the
cache without touching the inner object.

Two cache backends are supported: a plain hash reference (fast, in-process,
no expiry) and any CHI-compatible object (persistent, shared, with expiry).

# SUBROUTINES/METHODS

## new

Construct a caching proxy around any Perl object.

### Arguments

- `cache` (mandatory)

    Either a plain hash reference (`{}`) or a CHI-compatible object that
    implements `get()`, `set()`, and `purge()`.

- `object` (optional)

    The object to wrap.  Defaults to a bare [Class::Simple](https://metacpan.org/pod/Class%3A%3ASimple) instance.
    Must be a reference; a plain scalar argument causes a `carp` and an
    `undef` return.  Wrapping an already-wrapped
    `Class::Simple::Readonly::Cached` object returns the existing wrapper
    with a warning.

- `quiet` (optional, boolean)

    Suppress the double-wrap warning when non-zero.

### Returns

A `Class::Simple::Readonly::Cached` object, or `undef` on invalid
`object`.  Croaks on invalid `cache`.

### EXAMPLE

    use CHI;
    use Class::Simple::Readonly::Cached;

    # --- Hash-ref cache (in-process, no expiry) ---
    my $obj    = My::Expensive->new();
    my $cached = Class::Simple::Readonly::Cached->new(
        object => $obj,
        cache  => {},
    );
    my $result  = $cached->compute();   # calls the real object
    my $result2 = $cached->compute();   # from cache -- object not called

    # --- CHI cache (persistent, file-based) ---
    use File::Temp qw(tempdir);
    my $chi = CHI->new(driver => 'File', root_dir => tempdir(CLEANUP => 1));
    my $cached2 = Class::Simple::Readonly::Cached->new(
        object => $obj,
        cache  => $chi,
    );

    # --- Clone an existing wrapper ---
    my $clone = $cached->new();   # shares the same inner object and cache

### API SPECIFICATION

    # Input
    {
        cache  => { type => ['hashref', 'object'], required => 1  },
        object => { type => 'ref',                 optional => 1  },
        quiet  => { type => 'bool',                optional => 1  },
    }

    # Output
    { type => 'object', class => 'Class::Simple::Readonly::Cached',
      optional => 1 }

### MESSAGES

    Message                                                 Meaning                              Resolution
    -------                                                 -------                              ----------
    Cache must be ref to HASH or object                     cache is not a hashref or blessed    Pass \%hash or a CHI object.
                                                            object
    Cache object must implement get(), set(), and purge()   blessed cache lacks required API      Use a CHI-compatible object.
    $object must be a reference, not a scalar               object is a plain string             Pass a blessed reference.
    warning: $object is already a cached object             wrapping an already-wrapped object   Reuse the returned wrapper.
    $object is already cached at LINE of FILE               double-wrap detected                 Reuse the existing wrapper;
                                                                                                 set quiet => 1 to silence.

### PSEUDOCODE

    1.  If class is undef:           carp and return undef   (::new() misuse)
    2.  If class is blessed:         merge params into a clone and return
    3.  Validate cache:              croak if not a hashref or CHI-compatible object
    4.  Validate object:             carp+return if scalar; return existing
                                     wrapper if already __PACKAGE__
    5.  Create inner object:         Class::Simple->new(non-wrapper params)
                                     unless object was supplied
    6.  Check double-wrap registry:  if object in %cached, carp and return
                                     existing wrapper (unless quiet)
    7.  Bless and register:          bless $params, $class; set _class = $class;
                                     call _build_cache_accessors to install
                                     _get/_set coderefs and _cache_is_hash;
                                     store in %cached with caller file and line
    8.  Return $self

## object

Return the inner (wrapped) object.

### Returns

The blessed reference that was passed as `object` to `new()`.

### EXAMPLE

    # Bypass the cache to mutate state directly.
    $cached->object()->reset();

### API SPECIFICATION

    # Input  none
    # Output { type => 'object' }

### MESSAGES

    (none)

## state

Return a snapshot of cache hit and miss counts per cache key.
Primarily useful for performance profiling and white-box tests.

### Returns

A hash reference:

- `hits`

    Hash reference mapping each cache key to the number of times the
    result was served from cache.  `undef` until the first hit.

- `misses`

    Hash reference mapping each cache key to the number of times the
    inner object was actually invoked.  `undef` until the first miss.

### EXAMPLE

    my $s = $cached->state();
    my $hits   = do { my $n=0; $n += $_ for values %{$s->{hits}   // {}}; $n };
    my $misses = do { my $n=0; $n += $_ for values %{$s->{misses} // {}}; $n };
    printf "Hit rate: %.0f%%\n", 100 * $hits / ($hits + $misses) if $hits + $misses;

### API SPECIFICATION

    # Input  None
    # Output { type => 'hashref',
    #          keys => { hits   => 'hashref|undef',
    #                    misses => 'hashref|undef' } }

### MESSAGES

    (none)

## can

Report whether the inner object (or this class) can respond to a
given method.  Overrides `UNIVERSAL::can` to account for the
decorator pattern.

### Returns

A code reference if the method exists, `undef` otherwise.

### EXAMPLE

    my $code = $cached->can('compute');
    $code->($cached) if $code;

### API SPECIFICATION

    # Input  { self   => { type => 'object|string' },
    #          method => { type => 'string' } }
    # Output { type => 'coderef|undef' }

### MESSAGES

    (none)

## isa

Test class membership, delegating to the inner object's class
hierarchy when needed.  Overrides `UNIVERSAL::isa` to support the
transparent decorator pattern.

### Returns

True if the wrapper or its inner object is-a `$class`.

### EXAMPLE

    $cached->isa('My::Domain::Object');   # true if inner object is

### API SPECIFICATION

    # Input  { self  => { type => 'object|string' },
    #          class => { type => 'string' } }
    # Output { type => 'bool' }

### MESSAGES

    (none)

## AUTOLOAD

Not called directly.  Intercepts every method call not explicitly
defined in this package, looks up the result in the cache, and on a
miss proxies the call to the inner object and stores the result.

Cache lookup and storage use the pre-built `_get`/`_set` coderefs
installed by `_build_cache_accessors` at construction time, so the
backend-type decision (HASH vs CHI) is made once -- never on each
dispatch.

Three stored-value forms are mutually exclusive and exhaustive:

- ARRAY ref

    The wrapped method previously returned a list.  Served as `@array`
    in list context, or `$array[-1]` in scalar context.

- `$UNDEF_SENTINEL`

    The wrapped method returned `undef` or an empty list.  Stored as the
    sentinel string so a cache miss (undefined value) can be distinguished
    from a cached `undef`.

- Any other defined scalar

    The wrapped method returned a plain scalar in scalar context.  Served
    as-is in scalar context.  If the caller subsequently asks for the
    same key in list context, the scalar cannot be adapted -- the call is
    treated as a miss and the method is re-invoked so the array form gets
    independently cached.

Handles `DESTROY` specially: removes the wrapper from the double-wrap
registry and clears cache entries whose keys begin with `$self-`{\_class}>
(Invariant I3 guarantees this is always set), then returns without
calling the inner object's DESTROY.

# LIMITATIONS

- **Not safe for mutable objects**

    The cache is never invalidated automatically.  If the inner object's
    state changes after caching, the wrapper will return stale data.  The
    caller must either reset the cache manually or avoid using this module
    with objects that mutate.

- **Argument serialisation is naive**

    Cache keys are built by joining defined arguments with `::`.  Two
    different argument lists can therefore produce the same key if an
    argument itself contains `::` (e.g. `foo('a::b', 'c')` vs
    `foo('a', 'b::c')`).  Callers that pass arguments containing `::`
    should use a CHI backend with a custom key serialiser.

- **Undefined arguments are collapsed**

    Undefined values in the argument list are silently dropped from the
    cache key, so `foo(undef)` and `foo()` share a cache entry.

- **Scalar-then-list context mismatch is a miss**

    If a method is first called in scalar context and then in list
    context with identical arguments, the second call is a cache miss
    and re-invokes the inner object.  Both results are then independently
    cached.

- **`can('new')` returns a code reference, not a boolean**

    For strict correctness `can` returns `\&new` for the `'new'`
    method rather than the boolean `1`.  The code reference is callable
    but callers who compare it with `==` to `1` will see a mismatch.

- **Does not work with [Memoize](https://metacpan.org/pod/Memoize)**

    `Memoize` intercepts at the symbol-table level and conflicts with
    the `AUTOLOAD` dispatch used here.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

Please report any bugs or feature requests to
[https://github.com/nigelhorne/Class-Simple-Readonly-Cached/issues](https://github.com/nigelhorne/Class-Simple-Readonly-Cached/issues).

# SEE ALSO

- [Test Dashboard](https://nigelhorne.github.io/Class-Simple-Readonly-Cached/coverage/)
- [Class::Simple](https://metacpan.org/pod/Class%3A%3ASimple)
- [CHI](https://metacpan.org/pod/CHI)
- [Data::Reuse](https://metacpan.org/pod/Data%3A%3AReuse)

    Values are shared between `Class::Simple::Readonly::Cached` objects,
    since they are read-only.

- [constant::defer](https://metacpan.org/pod/constant%3A%3Adefer)

# SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

    perldoc Class::Simple::Readonly::Cached

- MetaCPAN

    [https://metacpan.org/release/Class-Simple-Readonly-Cached](https://metacpan.org/release/Class-Simple-Readonly-Cached)

- Source Repository

    [https://github.com/nigelhorne/Class-Simple-Readonly-Cached](https://github.com/nigelhorne/Class-Simple-Readonly-Cached)

- CPAN Testers

    [http://matrix.cpantesters.org/?dist=Class-Simple-Readonly-Cached](http://matrix.cpantesters.org/?dist=Class-Simple-Readonly-Cached)

# FORMAL SPECIFICATION

## new

    new : (C x P) -> (W | undef)

    C = class name string
    P = { cache : (HashRef | CacheObj), object? : Ref, quiet? : Bool, ... }
    W = blessed P in C

    valid_cache(c) :=
        ref(c) = 'HASH'
        OR ( blessed(c) AND c.can('get') AND c.can('set') AND c.can('purge') )

    Precondition:
        valid_cache(P.cache)

    Post-construction invariants (hold for all W returned by new()):
        W._class         = C
        W._cache_is_hash = (ref(P.cache) = 'HASH')
        W._get           = λk. (W._cache_is_hash ? W.cache[k] : W.cache.get(k))
        W._set           = λ(k,v). (W._cache_is_hash ? W.cache[k]:=v
                                                      : W.cache.set(k,v,'never'))

    Double-wrap invariant:
        forall o in Dom(cached): new(C, {object: o, ...}) = cached[o].object

    Clone (object invocation):
        forall w : W: w.new(P') = bless( merge(w, P'), ref(w) )
        Corollary: if cache in Dom(P'), rebuild _get/_set/_cache_is_hash for P'.cache

## object

    object : W -> Ref

    forall w : W: object(w) = w.object

## state

    state : W -> HashRef

    forall w : W: state(w) = { hits => w._hits, misses => w._misses }

## can

    can : (W|Str x Str) -> (CodeRef | undef)

    forall w : W, m : Str:
      can(w, 'new') = \&new
      can(w, m)     = w.object.can(m)  OR SUPER::can(w, m)

## isa

    isa : (W x Str) -> Bool

    forall w : W, c : Str:
      isa(w, c) = 1  if c in { ref(w), 'Class::Simple::Readonly::Cached' }
               | 1  if SUPER::isa(w, c)
               | w.object.isa(c)  if ref(w)
               | 0  otherwise

## autoload

    autoload : (W x M x A*) -> R

    M  = method name string
    A* = argument tuple (possibly empty)
    R  = scalar | list | undef

    Cache key:
        k(w, m, a) := w._class ++ '::' ++ m ++ '::' ++ defined_args(a)
        (w._class = ref(w), pre-computed once in new() to avoid ref() per dispatch)

    Caching law:
        get(cache(w), k(w,m,a)) = v, v != undef
            => autoload(w, m, a) = v          (cache hit)
        get(cache(w), k(w,m,a)) = undef
            => v = w.object.m(a)
               set(cache(w), k(w,m,a), v)
               autoload(w, m, a) = v          (cache miss)

# LICENSE AND COPYRIGHT

Author Nigel Horne: `njh@nigelhorne.com`
Copyright (C) 2019-2026 Nigel Horne

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
