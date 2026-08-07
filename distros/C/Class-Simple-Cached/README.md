[![Kwalitee](https://cpants.cpanauthors.org/dist/Class-Simple-Cached.png)](http://cpants.cpanauthors.org/dist/Class-Simple-Cached)
[![Tweet](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://twitter.com/intent/tweet?text=Cache+messages+to+an+object+#perl&url=https://github.com/nigelhorne/class-simple-cached&via=nigelhorne)

# NAME

Class::Simple::Cached - cache getter results for any get/set object

# VERSION

Version 0.07

# SYNOPSIS

    use CHI;
    use Class::Simple::Cached;

    # Wrap an existing object with a cache layer
    my $cache = CHI->new(driver => 'RawMemory', global => 1);
    my $obj   = Class::Simple::Cached->new(
        cache  => $cache,
        object => My::Expensive::Object->new(),
    );

    $obj->name('Alice');      # setter: delegates to wrapped object, updates cache
    my $n = $obj->name();     # getter: returns cached 'Alice' without hitting object

    # Or use a plain hash ref as the cache backend
    my %store;
    my $simple = Class::Simple::Cached->new(cache => \%store);
    $simple->colour('blue');
    print $simple->colour();  # 'blue', served from %store

# DESCRIPTION

A transparent caching wrapper for any [Class::Simple](https://metacpan.org/pod/Class%3A%3ASimple)-compatible get/set object.
Repeated getter calls hit the cache instead of the wrapped object, avoiding
expensive recomputation or remote round-trips.

Cache coherency is _not_ automatic.  If the wrapped object's state changes
through a path other than the cached wrapper, callers must invalidate the cache
themselves.

# SUBROUTINES/METHODS

## new

Constructs a `Class::Simple::Cached` instance that wraps `object` behind
`cache`.

### ARGUMENTS

- `cache` (mandatory)

    Either a blessed object implementing `get($key)`, `set($key, $val, $expires)`,
    and `purge()` (e.g. any [CHI](https://metacpan.org/pod/CHI) driver); or a plain hash reference used as an
    in-process store.

- `object` (optional)

    The object whose methods will be proxied and cached.  Defaults to a fresh
    `Class::Simple` instance.

Calling `->new()` on an already-blessed instance returns a shallow clone
(all stored fields are merged, including the existing cache handle).

### RETURNS

A blessed `Class::Simple::Cached` instance.

### SIDE EFFECTS

None beyond allocating the new instance.

### EXAMPLE

    # CHI-backed cache
    use CHI;
    my $obj = Class::Simple::Cached->new(
        cache  => CHI->new(driver => 'RawMemory', global => 1),
        object => My::Model->new(),
    );

    # Hash-ref cache (useful for tests or short-lived objects)
    my $obj = Class::Simple::Cached->new(cache => {});

    # Clone an existing wrapped object
    my $clone = $obj->new();

### API SPECIFICATION

    Input:
      cache  => HashRef | CHICompatibleObject  # required
      object => Object                          # optional

    Output:
      Class::Simple::Cached instance

### MESSAGES

    Message                                              Meaning                              Resolution
    ---------------------------------------------------  -----------------------------------  ----------------------------------------
    "use ->new() not ::new() to instantiate"             Called as Class::Simple::Cached::new  Use $obj->new() or ClassName->new()
    "Usage: $class->new(cache => \$cache)"               No arguments supplied                 Pass at least cache => ...
    "Cache must be ref to HASH or object"                cache is a plain scalar or wrong ref  Use a hashref or CHI-compatible object
    "Cache object must implement get, set, purge"        Blessed cache lacks required methods  Use a fully CHI-compatible object

### PSEUDOCODE

    new(class, args):
      IF class undefined   → carp and return undef
      IF class is blessed  → merge fields, return shallow clone
      IF no args           → croak Usage message
      PARSE args into hashref via Params::Get
      IF params.object absent → params.object = Class::Simple->new()
      IF params.cache is a blessed object:
        VERIFY it can('get') AND can('set') AND can('purge')
        IF not → croak capability message
        RETURN bless params, class
      IF params.cache is a HASH ref:
        RETURN bless params, class
      croak "Cache must be ref to HASH or object"

## can

Reports whether this wrapper (or its embedded object) can handle a method.

### ARGUMENTS

- `$method` — the method name to probe.

### RETURNS

True if the method is known; false otherwise.

### EXAMPLE

    $obj->can('name');   # true if the wrapped object has a name() method

### API SPECIFICATION

    Input:  method_name : Str
    Output: Bool

### MESSAGES

    None.

## isa

Reports whether this wrapper or its embedded object is of a given class.

### ARGUMENTS

- `$class` — the class name to test.

### RETURNS

True if the wrapper or the wrapped object is-a `$class`.

### EXAMPLE

    $obj->isa('My::Model');   # delegates to the wrapped object

### API SPECIFICATION

    Input:  class_name : Str
    Output: Bool

### MESSAGES

    None.

## AUTOLOAD (getter/setter proxy)

Intercepts every method call that is not explicitly defined, proxying it to
the wrapped object with a caching layer for zero-argument (getter) calls.

Setter calls (one or more arguments) always pass through to the wrapped object
and update the cache with the new value.

### ARGUMENTS

    $method()        — getter: returns cached value if present, else calls object
    $method($scalar) — scalar setter: stores scalar, updates cache
    $method(@list)   — array setter: stores list, updates cache

### RETURNS

The value returned by the wrapped object (or the cached copy thereof).

### SIDE EFFECTS

- Getter: may write to the cache on first call.
- Setter: writes to both the wrapped object and the cache.
- DESTROY: clears cache entries for this instance (see above).

### EXAMPLE

    $obj->colour('red');    # setter — writes 'red' to object and cache
    $obj->colour();         # getter — returns 'red' from cache

### API SPECIFICATION

    Input (getter):  method_name : Str,  args : ()
    Input (setter):  method_name : Str,  args : (Scalar | List)
    Output:          the stored/retrieved value or list

### MESSAGES

    Message                           Meaning                             Resolution
    --------------------------------  ----------------------------------  ----------------------------------------
    "$method" (croak)                 Cached array's first element is     Do not store the sentinel string
                                      the UNDEF_SENTINEL string           as a real value in the wrapped object

### PSEUDOCODE

    AUTOLOAD(method, args...):
      key = ref(self) + ":" + method

      IF no args (getter mode):
        val = cache_get(key)
        IF cache hit:
          IF val is a plain string (not a ref):
            IF val is UNDEF_SENTINEL → return undef
            RETURN val
          IF val is an arrayref:
            IF first element is a plain string AND equals UNDEF_SENTINEL → croak
            RETURN dereferenced list
          RETURN val (blessed object)
        # Cache miss — ask the wrapped object
        IF list context:
          result_list = object->method()
          IF empty      → return ()
          cache_set(key, \result_list)
          RETURN result_list
        # Scalar context
        result = object->method()
        IF defined:
          cache_set(key, result)
          RETURN result
        cache_set(key, UNDEF_SENTINEL)
        RETURN undef

      ELSE (setter mode):
        IF more than one arg (array setter):
          val = object->method(\@args)     # wrapped object stores arrayref
          IF defined:
            cache_set(key, val)
            RETURN @val
          cache_set(key, UNDEF_SENTINEL)
          RETURN undef
        ELSE (scalar setter):
          val = object->method(args[0])
          cache_set(key, val // UNDEF_SENTINEL)
          RETURN val

# LIMITATIONS

- Setter arguments are not part of the cache key.

    Calls like `$obj->method($arg)` use the key `ClassName:method` regardless
    of `$arg`.  Setters with different arguments therefore overwrite each other's
    cache entries.  For read-only caching of parameterised methods, see
    [Class::Simple::Readonly::Cached](https://metacpan.org/pod/Class%3A%3ASimple%3A%3AReadonly%3A%3ACached).

- Falsy scalar return values are not cached.

    Methods that return `0` or `''` (false but defined) are treated as a cache
    miss on every call: the underlying object is re-invoked each time.  Only
    `undef` is cached (via the UNDEF\_SENTINEL).  If you need to cache `0`, wrap
    it in a container object or use a different caching strategy.

- Sentinel collision.

    If the wrapped object ever returns the literal string
    `"Class::Simple::Cached\>UNDEF\<"` as a scalar, or as the first element of a
    list, the module will misinterpret it as a cached-undef marker.  This string is
    deliberately unusual, but callers working with arbitrary string data should be
    aware of the constraint.

- Shared cache and multiple classes.

    When two `Class::Simple::Cached` instances of **different** classes share the
    same cache object, their keys are namespaced by class name and do not collide.
    However, `purge()` on a CHI-style cache is global: destroying one instance will
    purge _all_ entries from a shared CHI cache, including those of the other
    instance.  Use per-instance cache objects, or a hash-ref cache, to avoid this.

- Does not work with [Memoize](https://metacpan.org/pod/Memoize).
- Overloaded `eq` on cached values.

    If the wrapped object returns a blessed value that overloads the `eq` operator,
    the sentinel comparison in the getter uses a `ref()` pre-check so that only
    plain strings are compared against the sentinel.  Array elements are subject to
    the same pre-check.  Callers wrapping objects that return sentinel-like strings
    via overloading should be aware of this guard.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

Please report bugs and feature requests at
[https://github.com/nigelhorne/Class-Simple-Cached/issues](https://github.com/nigelhorne/Class-Simple-Cached/issues).

# SEE ALSO

[Class::Simple](https://metacpan.org/pod/Class%3A%3ASimple), [CHI](https://metacpan.org/pod/CHI), [Class::Simple::Readonly::Cached](https://metacpan.org/pod/Class%3A%3ASimple%3A%3AReadonly%3A%3ACached)

- [Test Dashboard](https://nigelhorne.github.io/Class-Simple-Cached/coverage/)

# SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command:

    perldoc Class::Simple::Cached

- MetaCPAN: [https://metacpan.org/release/Class-Simple-Cached](https://metacpan.org/release/Class-Simple-Cached)
- Source: [https://github.com/nigelhorne/Class-Simple-Cached](https://github.com/nigelhorne/Class-Simple-Cached)
- CPANTS: [http://cpants.cpanauthors.org/dist/Class-Simple-Cached](http://cpants.cpanauthors.org/dist/Class-Simple-Cached)
- Testers Matrix: [http://matrix.cpantesters.org/?dist=Class-Simple-Cached](http://matrix.cpantesters.org/?dist=Class-Simple-Cached)

# FORMAL SPECIFICATION

## new

    ─────────────────────────────────────────────────────────────────
    [State]
      cache  : ℙ(HashRef ∪ CHIObject)
      object : Object

    [CHIObject]
      can_get   : Method
      can_set   : Method
      can_purge : Method

    new ──────────────────────────────────────────────────────────────
    Δ(cache, object)
    cache? : HashRef ∪ CHIObject
    object? : Object ∪ {∅}
    ─────────────────────────────────────────────────
    cache? ≠ ∅
    cache ′ = cache?
    object ′ = (object? ≠ ∅ ⟹ object?) ∨ Class::Simple.new()
    ─────────────────────────────────────────────────

## can

    can ──────────────────────────────────────────────────
    Ξ(cache, object)
    method? : MethodName
    ─────────────────────────────────────────────────
    result! = (method? = 'new')
            ∨ object.can(method?)
            ∨ SUPER::can(method?)

## isa

    isa ──────────────────────────────────────────────────
    Ξ(cache, object)
    class? : ClassName
    ─────────────────────────────────────────────────
    result! = (class? = ref(self))
            ∨ (class? = __PACKAGE__)
            ∨ SUPER::isa(class?)
            ∨ object.isa(class?)

## AUTOLOAD

    AUTOLOAD ─────────────────────────────────────────────────────────
    Δ(cache)
    method? : MethodName
    args?   : Seq(Any)
    ─────────────────────────────────────────────────
    key = ref(self) ⊕ ":" ⊕ method?

    Getter (args? = ∅):
      (∃ v • cache_hit(key, v) ∧ v ≠ UNDEF_SENTINEL ⟹ result! = v)
      ∨ (cache_hit(key, UNDEF_SENTINEL)              ⟹ result! = undef)
      ∨ (¬cache_hit(key, _)
          ∧ result! = object.method?()
          ∧ cache′ = cache ∪ {key ↦ encode(result!)})

    Setter (args? ≠ ∅):
      object′.method?(args?) = args?
      cache′ = cache ∪ {key ↦ encode(object′.method?())}
      result! = args?

# LICENCE AND COPYRIGHT

Copyright (C) 2019-2026, Nigel Horne

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
