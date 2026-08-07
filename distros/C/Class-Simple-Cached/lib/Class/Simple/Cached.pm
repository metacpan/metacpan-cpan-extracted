package Class::Simple::Cached;

use strict;
use warnings;

use Carp ();
use Class::Simple;
use Params::Get 0.15;
use Scalar::Util ();
use Sub::Protected;

# Stored in the cache to distinguish "the object returned undef" from
# "this key has never been cached".  Must never be a legitimate return value.
use constant UNDEF_SENTINEL => __PACKAGE__ . '>UNDEF<';

# Evaluated once at compile time so DESTROY never pays a string comparison
# on every object teardown just to decide whether ${^GLOBAL_PHASE} exists.
use constant _GLOBAL_PHASE_AVAILABLE => defined($^V) && ($^V ge 'v5.14.0');

=head1 NAME

Class::Simple::Cached - cache getter results for any get/set object

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=encoding UTF-8

=head1 SYNOPSIS

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

=head1 DESCRIPTION

A transparent caching wrapper for any L<Class::Simple>-compatible get/set object.
Repeated getter calls hit the cache instead of the wrapped object, avoiding
expensive recomputation or remote round-trips.

Cache coherency is I<not> automatic.  If the wrapped object's state changes
through a path other than the cached wrapper, callers must invalidate the cache
themselves.

=head1 SUBROUTINES/METHODS

=head2 new

Constructs a C<Class::Simple::Cached> instance that wraps C<object> behind
C<cache>.

=head3 ARGUMENTS

=over 4

=item C<cache> (mandatory)

Either a blessed object implementing C<get($key)>, C<set($key, $val, $expires)>,
and C<purge()> (e.g. any L<CHI> driver); or a plain hash reference used as an
in-process store.

=item C<object> (optional)

The object whose methods will be proxied and cached.  Defaults to a fresh
C<Class::Simple> instance.

=back

Calling C<< ->new() >> on an already-blessed instance returns a shallow clone
(all stored fields are merged, including the existing cache handle).

=head3 RETURNS

A blessed C<Class::Simple::Cached> instance.

=head3 SIDE EFFECTS

None beyond allocating the new instance.

=head3 EXAMPLE

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

=head3 API SPECIFICATION

    Input:
      cache  => HashRef | CHICompatibleObject  # required
      object => Object                          # optional

    Output:
      Class::Simple::Cached instance

=head3 MESSAGES

    Message                                              Meaning                              Resolution
    ---------------------------------------------------  -----------------------------------  ----------------------------------------
    "use ->new() not ::new() to instantiate"             Called as Class::Simple::Cached::new  Use $obj->new() or ClassName->new()
    "Usage: $class->new(cache => \$cache)"               No arguments supplied                 Pass at least cache => ...
    "Cache must be ref to HASH or object"                cache is a plain scalar or wrong ref  Use a hashref or CHI-compatible object
    "Cache object must implement get, set, purge"        Blessed cache lacks required methods  Use a fully CHI-compatible object

=head3 PSEUDOCODE

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

=cut

sub new
{
	my $class = shift;

	# Guard: always call as a method, not a bare function
	if(!defined($class)) {
		Carp::carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		return;
	}

	# When called on a blessed instance, return a shallow clone
	if(Scalar::Util::blessed($class)) {
		my $params = Params::Get::get_params(undef, \@_) || {};
		my %merged = (%{$class}, %{$params});
		# Always recalculate internal dispatch fields after the merge so that
		# caller-supplied _is_hash_cache or _cache_prefix args cannot corrupt
		# the cache-type flag or the key-prefix (internal field injection).
		$merged{'_is_hash_cache'} = ref($merged{'cache'}) eq 'HASH';
		$merged{'_cache_prefix'}  = ref($class) . ':';

		# Validate the (potentially-replaced) cache object using the same rules
		# as new() — the clone path must not produce an unusable object.
		if(!$merged{'_is_hash_cache'}) {
			if(Scalar::Util::blessed($merged{'cache'})) {
				unless($merged{'cache'}->can('get')
					&& $merged{'cache'}->can('set')
					&& $merged{'cache'}->can('purge'))
				{
					Carp::croak("Cache object must implement 'get', 'set', and 'purge' methods");
				}
			} else {
				Carp::croak(ref($class) . ': Cache must be ref to HASH or object');
			}
		}

		return bless \%merged, ref($class);
	}

	# Require at least one argument so Params::Get's confess is never reached;
	# we want croak (Test::Carp-compatible) not confess.
	if(scalar(@_) == 0) {
		Carp::croak('Usage: ', $class, '->new(cache => $cache)');
	}

	my $params = Params::Get::get_params('cache', @_) || {};

	# Default the wrapped object to a bare Class::Simple instance
	$params->{'object'} ||= Class::Simple->new();

	# Precompute per-instance fields so AUTOLOAD (hot path) avoids ref() and
	# string concatenation on every call.
	$params->{'_is_hash_cache'} = ref($params->{'cache'}) eq 'HASH';
	$params->{'_cache_prefix'}  = "$class:";

	if(Scalar::Util::blessed($params->{'cache'})) {
		# Verify the cache object speaks the required interface
		unless($params->{'cache'}->can('get')
			&& $params->{'cache'}->can('set')
			&& $params->{'cache'}->can('purge'))
		{
			Carp::croak("Cache object must implement 'get', 'set', and 'purge' methods");
		}
		return bless $params, $class;
	}

	# Transitive reduction: _is_hash_cache already holds ref($cache) eq 'HASH'
	# computed two statements earlier — no need to call ref() again.
	if($params->{'_is_hash_cache'}) {
		return bless $params, $class;
	}

	Carp::croak("$class: Cache must be ref to HASH or object");
}

=head2 can

Reports whether this wrapper (or its embedded object) can handle a method.

=head3 ARGUMENTS

=over 4

=item C<$method> — the method name to probe.

=back

=head3 RETURNS

True if the method is known; false otherwise.

=head3 EXAMPLE

    $obj->can('name');   # true if the wrapped object has a name() method

=head3 API SPECIFICATION

    Input:  method_name : Str
    Output: Bool

=head3 MESSAGES

    None.

=cut

sub can
{
	my ($self, $method) = @_;

	# Undefined method name is outside the documented API; return undef cleanly.
	return unless defined $method;

	# When called as a class method there is no wrapped object to probe
	return $self->SUPER::can($method) unless Scalar::Util::blessed($self);

	return ($method eq 'new')
		|| $self->{'object'}->can($method)
		|| $self->SUPER::can($method);
}

=head2 isa

Reports whether this wrapper or its embedded object is of a given class.

=head3 ARGUMENTS

=over 4

=item C<$class> — the class name to test.

=back

=head3 RETURNS

True if the wrapper or the wrapped object is-a C<$class>.

=head3 EXAMPLE

    $obj->isa('My::Model');   # delegates to the wrapped object

=head3 API SPECIFICATION

    Input:  class_name : Str
    Output: Bool

=head3 MESSAGES

    None.

=cut

sub isa
{
	my ($self, $class) = @_;

	# Undefined class name is outside the documented API; return undef cleanly.
	return unless defined $class;

	# When called as a class method there is no wrapped object to interrogate
	return $self->SUPER::isa($class) unless Scalar::Util::blessed($self);

	return 1 if $class eq ref($self)
		|| $class eq __PACKAGE__
		|| $self->SUPER::isa($class);

	return $self->{'object'}->isa($class);
}

# DESTROY — purge this instance's entries from the cache on object teardown.
#
# Purpose:      Prevent stale entries from leaking into a shared cache after
#               the wrapper goes out of scope.
# Entry:        Called automatically by Perl's garbage collector.
# Exit Status:  None (void).
# Side Effects: Removes all cache keys prefixed with ref($self) for hash caches;
#               calls purge() for CHI-style caches.
#               See https://github.com/Perl/perl5/issues/14673 for why an
#               explicit DESTROY is required even though AUTOLOAD could catch it.
sub DESTROY
{
	my $self = shift;

	my $cache = $self->{'cache'} or return;

	if($self->{'_is_hash_cache'}) {
		# Remove only this class's keys to avoid stomping on siblings sharing the hash
		my $prefix = $self->{'_cache_prefix'};
		delete $cache->{$_} for grep { index($_, $prefix) == 0 } keys %{$cache};
		return;
	}

	# Skip purge during global destruction to avoid order-of-destruction crashes
	return if _GLOBAL_PHASE_AVAILABLE && ${^GLOBAL_PHASE} eq 'DESTRUCT';

	$cache->purge();
}

# _cache_get / _cache_set — unified read/write; hides hash-ref vs. CHI dispatch
# so the rest of the code never needs to branch on ref($cache).
sub _cache_get :Protected
{
	my ($self, $key) = @_;
	my $cache = $self->{'cache'};
	return $self->{'_is_hash_cache'} ? $cache->{$key} : $cache->get($key);
}

sub _cache_set :Protected
{
	my ($self, $key, $val) = @_;
	my $cache = $self->{'cache'};
	if($self->{'_is_hash_cache'}) {
		$cache->{$key} = $val;
	} else {
		$cache->set($key, $val, 'never');
	}
}

=head2 AUTOLOAD (getter/setter proxy)

Intercepts every method call that is not explicitly defined, proxying it to
the wrapped object with a caching layer for zero-argument (getter) calls.

Setter calls (one or more arguments) always pass through to the wrapped object
and update the cache with the new value.

=head3 ARGUMENTS

    $method()        — getter: returns cached value if present, else calls object
    $method($scalar) — scalar setter: stores scalar, updates cache
    $method(@list)   — array setter: stores list, updates cache

=head3 RETURNS

The value returned by the wrapped object (or the cached copy thereof).

=head3 SIDE EFFECTS

=over 4

=item * Getter: may write to the cache on first call.

=item * Setter: writes to both the wrapped object and the cache.

=item * DESTROY: clears cache entries for this instance (see above).

=back

=head3 EXAMPLE

    $obj->colour('red');    # setter — writes 'red' to object and cache
    $obj->colour();         # getter — returns 'red' from cache

=head3 API SPECIFICATION

    Input (getter):  method_name : Str,  args : ()
    Input (setter):  method_name : Str,  args : (Scalar | List)
    Output:          the stored/retrieved value or list

=head3 MESSAGES

    Message                           Meaning                             Resolution
    --------------------------------  ----------------------------------  ----------------------------------------
    "$method" (croak)                 Cached array's first element is     Do not store the sentinel string
                                      the UNDEF_SENTINEL string           as a real value in the wrapped object

=head3 PSEUDOCODE

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

=cut

sub AUTOLOAD
{
	our $AUTOLOAD;
	# rindex+substr avoids regex engine startup on every method dispatch
	my $param = substr($AUTOLOAD, rindex($AUTOLOAD, '::') + 2);

	my $self = shift;
	# _cache_prefix is precomputed at new() time (= ref($self) . ":") to avoid
	# calling ref() and doing string concat on every AUTOLOAD invocation.
	my $key  = $self->{'_cache_prefix'} . $param;
	my $object = $self->{'object'};

	# Getter path ─────────────────────────────────────────────────────────────
	if(scalar(@_) == 0) {
		my $rc = $self->_cache_get($key);

		# Truthiness check: falsy-but-defined values (0, '') are treated as cache
		# misses so the object is re-invoked every call.  This is a known
		# limitation; see the LIMITATIONS section in the POD.
		if($rc) {
			# Premise 1: $rc is truthy (the if-guard guarantees this).
			# Premise 2: ref($rc) returns '' for plain scalars, 'ARRAY' for
			#   arrayrefs, or a package name for blessed objects.
			# The three branches below are mutually exclusive and exhaustive.
			if(!ref($rc)) {
				# Conclusion: plain scalar — only type that can equal the sentinel.
				return if $rc eq UNDEF_SENTINEL;
				return $rc;
			} elsif(ref($rc) eq 'ARRAY') {
				# Premise: !ref($rc) was false, so ref($rc) is truthy; no need
				# to re-test ref() — the elsif is the deductive next step.
				Carp::croak($param)
					if !ref($rc->[0]) && $rc->[0] eq UNDEF_SENTINEL;
				return @{$rc};
			}
			# Conclusion: ref($rc) is truthy and ≠ 'ARRAY' → blessed object.
			# Overloaded eq was never invoked; return the object as-is.
			return $rc;
		}

		# Cache miss — call the real object
		if(wantarray) {
			my @result = $object->$param();
			return unless scalar(@result);	# empty list: don't cache, return ()
			$self->_cache_set($key, \@result);
			return @result;
		}

		# Scalar / void context: cache the value (or the sentinel for undef)
		my $val = $object->$param();
		$self->_cache_set($key, defined($val) ? $val : UNDEF_SENTINEL);
		return $val;
	}

	# Setter path — array ─────────────────────────────────────────────────────
	if(scalar(@_) > 1) {
		# Pass the list as an arrayref; the wrapped object stores it
		my $val = $object->$param(\@_);
		$self->_cache_set($key, defined($val) ? $val : UNDEF_SENTINEL);
		return defined($val) ? @{$val} : ();
	}

	# Setter path — scalar ────────────────────────────────────────────────────
	# CHI's set() returns the cache object, not the stored value;
	# capture the value before the set call and return it directly.
	my $val = $object->$param($_[0]);
	$self->_cache_set($key, defined($val) ? $val : UNDEF_SENTINEL);
	return $val;
}

=head1 FORMAL SPECIFICATION

=head2 new

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

=head2 can

    can ──────────────────────────────────────────────────
    Ξ(cache, object)
    method? : MethodName
    ─────────────────────────────────────────────────
    result! = (method? = 'new')
            ∨ object.can(method?)
            ∨ SUPER::can(method?)

=head2 isa

    isa ──────────────────────────────────────────────────
    Ξ(cache, object)
    class? : ClassName
    ─────────────────────────────────────────────────
    result! = (class? = ref(self))
            ∨ (class? = __PACKAGE__)
            ∨ SUPER::isa(class?)
            ∨ object.isa(class?)

=head2 AUTOLOAD

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

=head1 LIMITATIONS

=over 4

=item Setter arguments are not part of the cache key.

Calls like C<< $obj->method($arg) >> use the key C<ClassName:method> regardless
of C<$arg>.  Setters with different arguments therefore overwrite each other's
cache entries.  For read-only caching of parameterised methods, see
L<Class::Simple::Readonly::Cached>.

=item Falsy scalar return values are not cached.

Methods that return C<0> or C<''> (false but defined) are treated as a cache
miss on every call: the underlying object is re-invoked each time.  Only
C<undef> is cached (via the UNDEF_SENTINEL).  If you need to cache C<0>, wrap
it in a container object or use a different caching strategy.

=item Sentinel collision.

If the wrapped object ever returns the literal string
C<< "Class::Simple::Cached\>UNDEF\<" >> as a scalar, or as the first element of a
list, the module will misinterpret it as a cached-undef marker.  This string is
deliberately unusual, but callers working with arbitrary string data should be
aware of the constraint.

=item Shared cache and multiple classes.

When two C<Class::Simple::Cached> instances of B<different> classes share the
same cache object, their keys are namespaced by class name and do not collide.
However, C<purge()> on a CHI-style cache is global: destroying one instance will
purge I<all> entries from a shared CHI cache, including those of the other
instance.  Use per-instance cache objects, or a hash-ref cache, to avoid this.

=item Does not work with L<Memoize>.

=item Overloaded C<eq> on cached values.

If the wrapped object returns a blessed value that overloads the C<eq> operator,
the sentinel comparison in the getter uses a C<ref()> pre-check so that only
plain strings are compared against the sentinel.  Array elements are subject to
the same pre-check.  Callers wrapping objects that return sentinel-like strings
via overloading should be aware of this guard.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

Please report bugs and feature requests at
L<https://github.com/nigelhorne/Class-Simple-Cached/issues>.

=head1 SEE ALSO

L<Class::Simple>, L<CHI>, L<Class::Simple::Readonly::Cached>

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Class-Simple-Cached/coverage/>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command:

    perldoc Class::Simple::Cached

=over 4

=item * MetaCPAN: L<https://metacpan.org/release/Class-Simple-Cached>

=item * Source: L<https://github.com/nigelhorne/Class-Simple-Cached>

=item * CPANTS: L<http://cpants.cpanauthors.org/dist/Class-Simple-Cached>

=item * Testers Matrix: L<http://matrix.cpantesters.org/?dist=Class-Simple-Cached>

=back

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2019-2026, Nigel Horne

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
