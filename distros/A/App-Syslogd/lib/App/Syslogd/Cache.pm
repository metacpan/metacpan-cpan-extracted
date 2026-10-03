package App::Syslogd::Cache;

# A small in-memory cache with expiry and a size limit: the default home
# for App::Syslogd's reverse-DNS answers.
#
# It replaces a CHI Memory cache, which spent about 17 microseconds on
# every hit (key transformation, cache objects, a Log::Any call): a third
# of the time taken to record a datagram.  Here a hit is one hash lookup
# and a time comparison.  It has the same compute() interface, so any CHI
# object can still be passed to App::Syslogd instead.

use strict;
use warnings;
use autodie qw(:all);

use Params::Get;
use Params::Validate::Strict;
use Readonly;

our $VERSION = '0.002.0';

# Bytes charged for each entry on top of its key and value: a rough figure
# for Perl's own bookkeeping (the hash entry, the small array, the queue
# slot), so that many tiny entries cannot slip past the limit
Readonly::Scalar my $ENTRY_OVERHEAD => 64;

# The default limit, the same as App::Syslogd's dns_cache_bytes default
Readonly::Scalar my $DEFAULT_MAX_BYTES => 262_144;

# The age queue is rebuilt once it holds this many times more items than
# there are entries (replaced entries leave stale items behind)
Readonly::Scalar my $QUEUE_SLACK => 2;

=encoding utf8

=head1 NAME

App::Syslogd::Cache - A small, fast in-memory cache with expiry and a size limit

=head1 VERSION

Version 0.002.0

=head1 SYNOPSIS

	use App::Syslogd::Cache;

	my $cache = App::Syslogd::Cache->new(max_bytes => 65_536);

	# Look a value up; compute and remember it for 300 seconds if missing
	my $name = $cache->compute('192.0.2.1', 300, sub { slow_lookup('192.0.2.1') });

=head1 DESCRIPTION

App::Syslogd uses this to remember reverse-DNS answers.  It holds values in
a Perl hash, forgets each one after its time to live, and keeps its total
size under a limit by dropping the oldest entries first.

Its only method besides C<new()> is C<compute()>, which has the same calling
convention as L<CHI>'s, so either can be given to App::Syslogd as its
C<cache>.

=head1 METHODS

=head2 new

Purpose: make an empty cache.

Args: C<max_bytes> (optional): the most memory, roughly in bytes, that the
entries may use.  Default 262144.  Each entry counts as the length of its
key, plus the length of its value, plus 64.

Returns: the new cache.

Side Effects: none.

Usage:

	my $cache = App::Syslogd::Cache->new(max_bytes => 65_536);

=head3 EXAMPLE

	my $cache = App::Syslogd::Cache->new();	# 256 KB

=head3 API SPECIFICATION

=head4 INPUT

	{
		max_bytes => { type => 'integer', min => 1, optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Syslogd::Cache' }

=head3 MESSAGES

	+--------------------------------------------+--------------------------+-------------------------+
	| Message (dies)                             | Meaning                  | What to do              |
	+--------------------------------------------+--------------------------+-------------------------+
	| validate_strict: Parameter 'max_bytes' ... | Not a whole number of at | Give 1 or more          |
	|                                            | least 1                  |                         |
	| validate_strict: Unknown parameter 'x'     | A misspelt option        | Use max_bytes           |
	+--------------------------------------------+--------------------------+-------------------------+

=cut

sub new
{
	my $class = shift;

	my $args = Params::Validate::Strict::validate_strict({
		schema => { max_bytes => { type => 'integer', min => 1, optional => 1 } },
		input => Params::Get::get_params(undef, \@_) || {},
	});

	# entries: key => [value, expiry time, size, serial]
	# order:   [key, serial] pairs, oldest first, for eviction
	return bless {
		max_bytes => $args->{max_bytes} // $DEFAULT_MAX_BYTES,
		entries => {},
		order => [],
		bytes => 0,
		serial => 0,
	}, $class;
}

=head2 compute

Purpose: return the remembered value for a key, or compute, remember and
return it.

Args:

=over 4

=item 1. The key (a string).

=item 2. How many seconds to remember a new value.  0 (or less) means
"do not remember": the value is computed every time.

=item 3. A code reference that computes the value.

=back

Returns: the value (it may be C<undef>, which is remembered like any other).

Side Effects: may call the code reference; may forget the oldest entries to
stay under C<max_bytes>.  A value too big to fit at all is returned but not
remembered.  If the code dies, the error is passed on and nothing is
remembered.

Usage:

	my $value = $cache->compute($key, $seconds, sub { ... });

=head3 EXAMPLE

	my $calls = 0;
	my $get = sub { $cache->compute('k', 60, sub { ++$calls }) };
	$get->();	# 1: computed
	$get->();	# 1: remembered; $calls is still 1

=head3 API SPECIFICATION

=head4 INPUT

	{
		key => { type => 'string', position => 0 },
		ttl => { type => 'number', position => 1 },
		code => { type => 'coderef', position => 2 },
	}

The arguments are not validated: this is called for every datagram, and its
only caller is App::Syslogd.

=head4 OUTPUT

	{ type => 'any', optional => 1 }

=head3 MESSAGES

None of its own; an error from the code reference is passed on.

=head3 PSEUDOCODE

	if the key has an entry that has not expired: return its value
	value = code()
	if ttl <= 0: return value (not remembered)
	forget any old entry for the key
	size = length(key) + length(value) + 64
	if size > max_bytes: return value (too big to remember)
	while the entries plus size would exceed max_bytes:
		forget the oldest entry
	remember the value until now + ttl
	if the age queue has grown well past the entries: rebuild it
	return value

=cut

sub compute
{
	my ($self, $key, $ttl, $code) = @_;

	# The fast path: a value that has not expired
	my $entry = $self->{entries}{$key};
	return $entry->[0] if($entry && $entry->[1] > time());

	my $value = $code->();
	return $value unless($ttl > 0);

	# Forget the old (expired) entry before charging for the new one
	$self->{bytes} -= delete($self->{entries}{$key})->[2] if($entry);

	my $size = length($key) + length($value // '') + $ENTRY_OVERHEAD;
	return $value if($size > $self->{max_bytes});

	# Make room, oldest first.  Queue items whose serial no longer matches
	# are left over from replaced entries, and are just dropped.
	my $order = $self->{order};
	while($self->{bytes} + $size > $self->{max_bytes}) {
		my $item = shift(@{$order}) or last;	# cannot happen while bytes is right
		my ($old_key, $old_serial) = @{$item};
		my $old = $self->{entries}{$old_key};
		next unless($old && $old->[3] == $old_serial);
		delete $self->{entries}{$old_key};
		$self->{bytes} -= $old->[2];
	}

	my $serial = ++$self->{serial};
	$self->{entries}{$key} = [$value, time() + $ttl, $size, $serial];
	$self->{bytes} += $size;
	push @{$order}, [$key, $serial];

	# A key that is replaced again and again leaves stale queue items;
	# rebuild the queue from the live entries before they pile up
	if(@{$order} > $QUEUE_SLACK * keys(%{$self->{entries}}) + 1) {
		my $entries = $self->{entries};
		@{$order} = map { [$_, $entries->{$_}[3]] }
			sort { $entries->{$a}[3] <=> $entries->{$b}[3] } keys %{$entries};
	}

	return $value;
}

=head1 LIMITATIONS

The size limit is an estimate: Perl's real memory use per entry depends on
its build and the strings stored.  Expired entries are only removed when
their key is looked up again or when space is needed, not on a timer.
Times are whole seconds.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2
(see the F<LICENSE> file).  If you use it, please let me know.

=head1 FORMAL SPECIFICATION

=head2 new

	Cache
	  entries : KEY ⇸ (VALUE × TIME × ℕ × ℕ)
	  max_bytes, bytes : ℕ
	  ─────────
	  bytes = Σ { k : dom entries • size(entries(k)) } ∧ bytes ≤ max_bytes

	New
	  Cache'
	  max? : ℕ₁
	  ─────────
	  entries' = ∅ ∧ bytes' = 0 ∧ max_bytes' = max?

=head2 compute

	Compute
	  ΔCache
	  k? : KEY ; ttl? : ℤ ; code? : → VALUE ; v! : VALUE
	  ─────────
	  k? ∈ dom entries ∧ expiry(entries(k?)) > now ⇒
	    v! = value(entries(k?)) ∧ θCache' = θCache
	  otherwise ⇒
	    v! = code?() ∧
	    (ttl? ≤ 0 ∨ size(k?, v!) > max_bytes ⇒ k? ∉ dom entries') ∧
	    (ttl? > 0 ∧ size(k?, v!) ≤ max_bytes ⇒
	      entries'(k?) = (v!, now + ttl?, size(k?, v!), serial') ∧
	      ∀ k : dom entries' \ {k?} • k ∈ dom entries ∧
	        (∀ j : dom entries \ dom entries' • serial(entries(j)) <
	                                            min(serial ∘ entries' (dom entries')))) ∧
	    bytes' ≤ max_bytes

=head1 STATE DIAGRAM

	                     new()
	                       |
	                       v
	   compute(k) hit  +-------+   compute(k) miss, ttl > 0, fits
	  +--------------->| CACHE |------------------------------------+
	  |  [return the   +-------+   [compute; drop oldest entries    |
	  |   value]           ^        until it fits; remember until   |
	  +--------------------+        now + ttl]                      |
	                       +----------------------------------------+
	   compute(k) miss with ttl <= 0, or too big: [compute; return; nothing kept]
	   code dies: [error passed on; nothing kept]

=cut

1;
