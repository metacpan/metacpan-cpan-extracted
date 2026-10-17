package Database::BI::Model::Geocode;

# Resolve a location column to coordinates, once per distinct value.
#
# Phase 6.2 of BI-Phase6.md: a dataset with places but no coordinates offers
# loc=<column>, and the distinct values of that column are looked up in
# Geo::Coder::Free.  This module is that lookup, kept out of the controller so
# that the interesting part - which values are worth asking about, which were
# asked already, and what happens to the rest - is testable without an HTTP
# request, a data file, or a geocoder on the machine.
#
# The rule it is built around is that a dirty column is normal rather than an
# error.  A place column holds street names, blank cells, and the odd bare number
# that a column-offset mistake put there.  Two things stop that from ending a
# request:
#
#   1. Every distinct value is put to the geocoder's own valid_location() before
#      anything is looked up.  A value it refuses is counted, reported, and
#      dropped: it never reaches a backend, so it cannot croak, and it is not
#      counted as a lookup.
#   2. The batch is made with on_error => 'undef', so a value the geocoder
#      refuses later is a miss rather than a death.  Nothing is wrapped in an
#      eval: a backend exception still propagates, exactly as it does from
#      geocode() itself.
#
# Skipping is remembered rather than repeated.  An attempted-and-unresolved value
# is stored as 0 - the shape BI-Phase6.md section 6.3 gives the geo section of
# .bi/models.json - so the next request over the same column plots what resolved,
# reports the rest, and asks the geocoder nothing at all.

use strict;
use warnings;

use Carp			qw(croak);
use Readonly;
use Scalar::Util		qw(blessed);
use Params::Get			();
use Params::Validate::Strict	qw(validate_strict);

our $VERSION = '0.013.0';

# The version of Geo::Coder::Free this module asks for: 0.46 added valid_location()
# and on_error => 'undef', 0.47 added geocode_many(), and this module asks for both
# rather than reimplementing the rule or the batch loop it exists to use.
Readonly my $MIN_GEOCODER_VERSION => '0.47';

# The default for map_geocode_max (section 6.2): new lookups allowed in one
# request.  A crafted URL must not be able to turn one request into unbounded CPU.
Readonly my $DEFAULT_MAX => 500;

# ---------------------------------------------------------------------------
# I18N message dictionary.
# Every user-visible string this module produces is keyed here.  The keys are
# BI-Phase6.md section 11's for the conditions it names - geocoder missing, the
# location column not being in the view, skipped rows, the cap, and no openaddr
# data - so the controller and this module describe the same conditions with the
# same words; the rest are this module's own argument and interface errors, which
# section 11 does not name because they are not states a page reaches.  Pass an
# object that responds to maketext($key, @args) as the "i18n" constructor
# argument to override them; it is called in preference to this table.
# ---------------------------------------------------------------------------

Readonly our %MESSAGES => (
	'error_map_geocoder_missing'		=> 'Geocoding a location column needs Geo::Coder::Free %s or later, and %s',
	'error_map_loc_column'			=> 'Column "%s" is not in this dataset, so there is nothing to geocode',
	'error_geocoder_interface'		=> 'Geocode: the geocoder must provide %s; Geo::Coder::Free %s or later does',
	'error_max_invalid'			=> 'Geocode: option "max" must be a positive integer, not "%s"',
	'error_values_arrayref'			=> 'Geocode: the values must be an arrayref, not "%s"',
	'error_rows_arrayref'			=> 'Geocode: the rows must be an arrayref, not "%s"',
	'error_column_required'			=> 'Geocode: the column name is required',
	'warn_map_rows_skipped'			=> 'Plotted %d of %d rows; %d hold no location that could be plotted (an empty cell, a bare number, or a place that could not be found)',
	'warn_map_geocode_capped'		=> 'Geocoded %d of the %d places that had not been looked up before; the rest are untouched, so open the data source again or run the geocode warm script to finish them',
	'warn_map_geocoder_unavailable_data'	=> 'The geocoder has no OpenAddresses data configured (OPENADDR_HOME), so places resolve only as coarsely as the bundled MaxMind data allows',
);

# _fmt($key [, @args]) -> $string
#
# Package-level i18n formatter, for the messages new() raises before the object
# exists.  Instance methods use _msg() so a caller-supplied i18n object can
# override the built-in strings.
sub _fmt {
	my ($key, @args) = @_;

	my $tmpl = $MESSAGES{$key} // "Internal error: unknown message key '$key'";

	return @args ? sprintf($tmpl, @args) : $tmpl;
}

# _msg($self, $key [, @args]) -> $string
sub _msg {
	my ($self, $key, @args) = @_;

	if (my $i18n = $self->{'_i18n'}) {
		return $i18n->maketext($key, @args);
	}

	return _fmt($key, @args);
}

# _message($self, $key [, @args]) -> { key => $key, text => $text }
#
# The form a message is reported in: the key lets a caller re-render it through
# its own i18n, and the text is what to show when it does not.
sub _message {
	my ($self, $key, @args) = @_;

	return { 'key' => $key, 'text' => $self->_msg($key, @args) };
}

=head1 NAME

Database::BI::Model::Geocode - Resolve a location column to coordinates, once per distinct value

=head1 VERSION

0.013.0

=head1 SYNOPSIS

B<Geocode a dataset's place column, with the counts a page needs:>

    use Database::BI::Model::Geocode;

    my $geocode = Database::BI::Model::Geocode->new();
    my $result  = $geocode->resolve_column($rows, 'place');

    for my $marker (@{ $result->{'markers'} }) {
        $map->add_marker([$marker->{'lat'}, $marker->{'lon'}], html => $popup);
    }

    my $counts = $result->{'counts'};
    # { rows => 401, plotted => 3, unusable => 398, distinct => 7, skipped => 4,
    #   cached => 1, attempted => 2, lookups => 2, resolved => 3, unresolved => 4,
    #   not_attempted => 0 }

    print "$_->{'text'}\n" for @{ $result->{'messages'} };

B<Remember the answers in the dataset's model store, so the next request is free:>

    my $spec  = 'table:sales|loc=place';
    my $cache = Database::BI::Model::Geocode->cache_from_models(\%models, $spec);
    my $result = $geocode->resolve_values(\@places, cache => $cache);

    my $models = Database::BI::Model::Geocode->models_with_cache(
        \%models, $spec, $result->{'cache'},
        backend => $result->{'backend'},
        built   => $now,
    );

B<Ask whether the panel should offer the option at all:>

    my ($available, $reason) = $geocode->geocoder_available();
    # (0, 'Geocoding a location column needs Geo::Coder::Free 0.47 or later, ...')

=head1 DESCRIPTION

C<Geo::Coder::Free> resolves a place to a C<Geo::Location::Point>.  A table column
holds something less tidy than a place: names repeated thousands of times, blank
cells, values that are not places at all.  This module does the three things the
column then needs:

=over 4

=item B<Ask once per distinct value.>

The column is reduced to a set first.  A repeated value costs one lookup, so a
100,000-row file holding a dozen places costs a dozen lookups, not 100,000.

=item B<Refuse a value that is not a location before any backend sees it.>

C<< $geocoder->valid_location($value) >> is the rule the guard inside C<geocode()>
and the backends themselves apply: false for C<undef>, the empty string, a
reference, and a string of digits only.  Answering it here means a bare number in
the wrong column is counted and reported rather than looked up, and the count of
lookups stays the count of work the request did.

=item B<Look the rest up without letting one value end the batch.>

The batch is made with C<< on_error => 'undef' >>.  A value the geocoder refuses
after the pre-filter is a miss; a backend that throws is still a throw, because
nothing here is wrapped in an C<eval>.

=back

The counts add up, in every path through the module: C<skipped + cached +
attempted + not_attempted == distinct>, and C<resolved + unresolved == cached +
attempted>.  C<lookups> is the count the geocoder itself reports for the batch,
which is C<attempted> unless the geocoder knows something finer.

=head2 The cache

A cache entry is a C<[lat, lon]> arrayref for a place that resolved, or C<0> for a
place that was looked up and not found - the shape section 6.3 gives the C<geo>
section of C<.bi/models.json>.  That C<0> is what stops a column of unresolvable
values from being retried on every request, and it is why C<unresolved> can be
reported when no lookup happened.

The cache is passed per call and returned per call; the caller's hashref is never
modified, so a request that dies half way through cannot leave a half-written
cache behind.  Persisting it is the controller's business, which keeps the
C<model_dir>-inside-C<data_dir> guard in the one place that already owns it
(section 7: no write to C<data_dir>, ever).  A cache that has been remembered is
also used when no geocoder can be loaded at all: the places already resolved are
still plotted, and only new lookups are unavailable.

=head2 Without the geocoder

C<Geo::Coder::Free> is a recommended dependency, not a required one, and it is
loaded when it is first needed rather than at compile time.  If it is missing, or
older than the floor, nothing is looked up and nothing croaks: C<available> is
false, C<error_map_geocoder_missing> says which version is needed and which is
installed, and the caller maps explicit coordinate columns instead.

=head1 CONSTRUCTOR

=head2 new

    my $geocode = Database::BI::Model::Geocode->new(%options);

=head3 API SPECIFICATION

=head4 INPUT

    geocoder             => object,   # optional; must provide valid_location() and geocode_many()
    openaddr             => string,   # optional; OpenAddresses data path (default: $ENV{OPENADDR_HOME})
    min_geocoder_version => string,   # optional; default 0.47
    i18n                 => object,   # optional; must implement maketext($key, @args)

C<geocoder> is the seam the tests use, and the only way to resolve with something
other than C<Geo::Coder::Free>.  An injected geocoder is used exactly as given -
it is not version-checked, which is what lets a stub stand in for the module.

C<min_geocoder_version> is injectable so a caller can pin the floor, and so the
too-old path can be tested on a machine that has the module installed.

Accepts a flat key/value list or a hashref, via C<Params::Get>.

=head4 OUTPUT

Returns C<$self>.  Croaks on an injected geocoder that cannot answer
C<valid_location()> or C<geocode_many()> (C<error_geocoder_interface>): a geocoder
that cannot answer the rule is a programming error, unlike a geocoder that is not
installed.

=head1 SUBROUTINES/METHODS

=head2 resolve_column

    my $result = $geocode->resolve_column($rows, $column, %options);

Resolve one column of a table: C<$rows> is an arrayref of hashrefs as the pipeline
produces them, and C<$column> names the one holding the places.

=head3 API SPECIFICATION

=head4 INPUT

    $rows    => arrayref of hashrefs, required
    $column  => string,   required
    cache    => hashref,  # optional; value => [lat, lon] | 0
    region   => string,   # optional; two-letter country hint for the geocoder
    max      => integer,  # optional; new lookups allowed, default 500

C<max> is C<map_geocode_max>: new lookups, not rows and not cached answers.  A
value already in C<cache> costs nothing and does not count against it.

C<region> is passed straight through; it is not derived from the request's
language, because a language is not a country.

=head4 OUTPUT

Returns a hashref:

    {
        available => 1,                    # 0 when no geocoder could be loaded
        points    => { $value => { lat, lon, rows, first_row, backend } },
        markers   => [ { value, lat, lon, rows, first_row } ],   # first-seen order
        counts    => { rows, plotted, unusable, distinct, skipped, cached,
                       attempted, lookups, resolved, unresolved, not_attempted },
        skipped        => [ $value ],      # not a location: never looked up
        unresolved     => [ $value ],      # looked up (now or before) and not found
        not_attempted  => [ $value ],      # held back by the cap
        messages  => [ { key, text } ],
        cache     => { $value => [lat, lon] | 0 },
        backends  => { 'OpenAddresses' => 3 },
        backend   => 'OpenAddresses',      # undef when nothing resolved
        capped    => 0,
    }

C<points> holds one entry per value that produced a position - whether it was
looked up now or remembered from an earlier request - and C<markers> is the same
in first-seen order, which is the order a map reads better in.  A value that was
plotted from the cache carries no C<backend>, because the cache remembers a
position and not which dataset gave it; only the places looked up in this request
name one.  C<rows> on an entry is how many rows of the column hold that value, so
an aggregated marker's popup can say how many events are at it without recounting;
C<first_row> is the index of the first of them.

A cell that is C<undef>, empty, or a reference is in C<skipped>: no module is
needed to know it is not a location.  A value the geocoder's C<valid_location()>
refused is in C<skipped> too, since that method is the rule.  C<unresolved> holds
the places that were looked up - now or in an earlier request, from the cache -
and found nothing; C<not_attempted> holds the ones the cap held back, which are
deliberately *not* recorded in the cache, so the next request or the warm script
picks them up.  When the geocoder is unavailable, every non-empty value is in
C<not_attempted>: nothing is refused on its behalf, and nothing is guessed at.

=head3 MESSAGES

    error_map_loc_column               -- the named column is in none of the rows
    error_map_geocoder_missing         -- no geocoder, or one older than the floor
    warn_map_rows_skipped              -- some rows have no plottable location
    warn_map_geocode_capped            -- the cap held some places back
    warn_map_geocoder_unavailable_data -- no OPENADDR_HOME, so coarse answers only

=head3 EXAMPLE

    my $result = $geocode->resolve_column($rows, 'place', region => 'GB', max => 500);

    for my $message (grep { $_->{'key'} eq 'warn_map_rows_skipped' } @{ $result->{'messages'} }) {
        warn $message->{'text'};
    }

=head2 resolve_values

    my $result = $geocode->resolve_values(\@values, %options);

The same resolution without rows: C<\@values> is a list of cell values, in any
order and with any repeats, and the returned hashref is the one
C<resolve_column()> is built on, without C<rows>/C<plotted>/C<unusable>, without
C<markers>, and without the row-level C<warn_map_rows_skipped> message.  This is
what a warming script wants: every distinct value of a column, resolved and
reported as counts.

=head2 geocoder_available

    my ($available, $reason) = $geocode->geocoder_available();

Whether this object can resolve anything new, and why not when it cannot.  It
loads the geocoder if that has not happened yet, and never croaks: a panel asks
this to decide whether to offer the location option at all, so the answer is a
sentence about the installed module rather than an exception.

=head2 cache_from_models

    my $cache = Database::BI::Model::Geocode->cache_from_models(\%models, $spec_key);

The remembered places of one dataset spec, as a copy, from a model store in the
shape C<_read_models()> returns.  An unknown spec, or one that has never been
geocoded, gives an empty hashref.

=head2 models_with_cache

    $models = Database::BI::Model::Geocode->models_with_cache(
        \%models, $spec_key, $cache, backend => 'OpenAddresses', built => $iso8601,
    );

A new model store in which those places are recorded under
C<< geo => { $spec_key => { places, backend, built } } >>, leaving every other key,
every other spec, and the caller's hashref untouched.  This module never writes
the file: it returns the structure for the controller to hand to
C<_write_models()>, which is where the writability and C<data_dir> guards live.
C<built> is passed in rather than taken from the clock, so a caller decides what
time it was.

=cut

sub new {
	# Strategy: normalise the argument list with Params::Get so a caller may pass
	# a hashref or a flat list interchangeably, then validate before using
	# anything.  An injected geocoder is checked for the methods this module asks
	# of one, rather than failing half way down a column.
	my $class = shift;
	my $raw   = Params::Get::get_params(undef, \@_) // {};

	my $args = validate_strict(
		schema => {
			geocoder             => { type => 'object',  optional => 1, default => undef },
			openaddr             => { type => 'string',  optional => 1, default => undef },
			min_geocoder_version => { type => 'string',  optional => 1, default => $MIN_GEOCODER_VERSION },
			i18n                 => { type => 'object',  optional => 1, default => undef, can => 'maketext' },
		},
		input => $raw,
	);

	my $self = bless {
		'_i18n'       => $args->{'i18n'},
		'openaddr'    => $args->{'openaddr'} // $ENV{'OPENADDR_HOME'},
		'min_version' => $args->{'min_geocoder_version'},
	}, $class;

	if (my $geocoder = $args->{'geocoder'}) {
		$self->_check_interface($geocoder);
		$self->{'_geocoder'} = $geocoder;
	}

	return $self;
}

# _check_interface($geocoder)
#
# A geocoder has to answer the two questions this module asks of one.  Checked
# here rather than half way through a column.
sub _check_interface {
	my ($self, $geocoder) = @_;

	for my $method (qw(valid_location geocode_many)) {
		next if $geocoder->can($method);
		croak(_fmt('error_geocoder_interface', $method . '()', $MIN_GEOCODER_VERSION));
	}

	return 1;
}

# _load_geocoder() -> geocoder object, or undef when there is not one to be had
#
# The real geocoder, loaded on demand so the application installs, starts and
# tests without it.  Returns nothing when the module is absent or older than the
# floor, and records which of the two it was for the message.
sub _load_geocoder {
	my $self = shift;

	my $ok = eval {
		require Geo::Coder::Free;
		Geo::Coder::Free->VERSION($self->{'min_version'});
		1;
	};

	unless ($ok) {
		my $error = $@;

		$self->{'_unavailable'} =
			($error =~ /Can't locate/)			? 'it is not installed'
			: (defined($Geo::Coder::Free::VERSION)		? "$Geo::Coder::Free::VERSION is installed"
			: 'it could not be loaded');

		return;
	}

	return Geo::Coder::Free->new(
		$self->{'openaddr'} ? (openaddr => $self->{'openaddr'}) : ()
	);
}

# _geocoder() -> geocoder object or undef
#
# Loaded once per object, so a missing module is not looked for on every value.
sub _geocoder {
	my $self = shift;

	if (!exists $self->{'_geocoder'}) {
		$self->{'_geocoder'} = $self->_load_geocoder();
	}

	return $self->{'_geocoder'};
}

# _coordinates($result) -> ($lat, $lon)
#
# The position out of a geocoder result, read through the accessors of a
# Geo::Location::Point and the keys of a plain hashref from another geocoder.
# 'lon' is only a third fallback, as in HTML::Genealogy::Map: it is not part of
# the point interface, and only one of Geo::Coder::Free's MaxMind shortcuts ever
# spells longitude that way.
sub _coordinates {
	my $point = shift;

	return unless ref($point) && (ref($point) ne 'ARRAY');

	if (blessed($point) && $point->can('latitude') && $point->can('longitude')) {
		return ($point->latitude(), $point->longitude());
	}

	if (ref($point) eq 'HASH') {
		return ($point->{'lat'}, $point->{'long'} // $point->{'lng'} // $point->{'lon'});
	}

	return;
}

# _backend_of($result) -> $name or undef
#
# Which database answered, as section 6.2 wants recorded and shown.  'database'
# names the backend and 'geocoder' the distribution; a result carrying neither is
# not guessed at.
sub _backend_of {
	my $point = shift;

	return unless ref($point) && (ref($point) ne 'ARRAY');

	for my $key (qw(database geocoder)) {
		my $value = (blessed($point) && $point->can($key)) ? $point->$key() : $point->{$key};
		return $value if defined($value) && length($value) && !ref($value);
	}

	return;
}

# _has_position($cache_entry)
#
# True for a remembered [lat, lon]; false for a remembered 0, which says "looked
# up and not found" and is a different thing from "never looked up".
sub _has_position {
	my $entry = shift;

	return 0 unless (ref($entry) eq 'ARRAY') && (@{ $entry } >= 2);

	return (defined($entry->[0]) && defined($entry->[1])) ? 1 : 0;
}

# _resolve($values, \%opts) -> \%result
#
# The whole of section 6.2 in one pass: classify every distinct value, apply the
# cap, make one batch, and count.  No rows and no row-level message.
sub _resolve {
	my ($self, $values, $opts) = @_;

	my $max    = $opts->{'max'};
	my $region = $opts->{'region'};

	my ($available, $reason) = $self->geocoder_available();
	my $geocoder = $self->_geocoder();

	# A working copy: a caller's cache is never modified, so a request that dies
	# half way through cannot leave a half-written one behind.
	my %cache = %{ $opts->{'cache'} // {} };

	my %seen;
	my (@skipped, @unresolved, @not_attempted, @pending);
	my ($distinct, $cached_resolved, $cached_unresolved) = (0, 0, 0);

	# The positions found, whether they were found now or in an earlier request.
	my %points;
	my %backends;

	# 1. Which values are worth asking about at all.
	for my $value (@{ $values // [] }) {
		my $key = (defined($value) && !ref($value)) ? $value : '';
		next if $seen{$key}++;
		$distinct++;

		# A cell with nothing in it is not a location under any reading, so it is
		# refused whether or not a geocoder is installed.
		if (!defined($value) || ref($value) || !length($key)) {
			push @skipped, $value;
			next;
		}

		# Remembered answers are used even when there is no geocoder: what has
		# been resolved before is still plottable.
		if (exists $cache{$key}) {
			if (_has_position($cache{$key})) {
				$cached_resolved++;

				# A remembered place is a place to plot.  The point is built here
				# rather than only for the values looked up below, so that a
				# request which asks the geocoder nothing - because it has
				# nothing new to ask it - is not a request that plots nothing.
				# No backend is claimed for it: the cache remembers a position,
				# not which dataset gave it.
				$points{$key} = {
					'lat' => $cache{$key}[0],
					'lon' => $cache{$key}[1],
				};
			} else {
				$cached_unresolved++;
				push @unresolved, $value;
			}
			next;
		}

		unless ($geocoder) {
			# No geocoder: the rule cannot be asked, so nothing is refused here
			# and nothing is looked up either.
			push @not_attempted, $value;
			next;
		}

		# The rule, asked of the module that would do the lookup.  A value it
		# refuses never reaches a backend, so it cannot croak there.
		unless ($geocoder->valid_location($key)) {
			push @skipped, $value;
			next;
		}

		push @pending, $value;
	}

	# 2. The cap, counted in new lookups: map_geocode_max in section 6.2.  Values
	# held back are left out of the cache, so the next request picks them up.
	my $wanted = scalar @pending;
	my @attempt = @pending;
	my $capped  = 0;

	if ($wanted > $max) {
		@attempt = @pending[0 .. $max - 1];
		push @not_attempted, @pending[$max .. $#pending];
		$capped = 1;
	}

	# 3. One batch, with the non-croaking mode and the region hint.
	my ($lookups, $resolved, $unresolved) = (0, 0, 0);

	if (@attempt) {
		my $batch = $geocoder->geocode_many(
			\@attempt,
			(defined($region) ? (region => $region) : ()),
			on_error => 'undef',
		);

		# The count the geocoder reports for the batch is the one a caller caps
		# its work by; a geocoder that reports none leaves the number of values
		# it was handed.
		$lookups = ((ref($batch) eq 'HASH') && defined($batch->{'lookups'}))
			? $batch->{'lookups'}
			: scalar @attempt;

		for my $value (@attempt) {
			my $point = (ref($batch) eq 'HASH') ? $batch->{$value} : undef;
			my ($lat, $lon) = _coordinates($point);

			if (defined($lat) && defined($lon)) {
				my $backend = _backend_of($point);

				$cache{$value} = [ $lat, $lon ];
				$points{$value} = {
					'lat' => $lat,
					'lon' => $lon,
					(defined($backend) ? ('backend' => $backend) : ()),
				};
				$backends{$backend}++ if defined($backend);
				$resolved++;

			} else {
				# Looked up and not found: recorded as tried, so the next request
				# over this column does not ask again.
				$cache{$value} = 0;
				push @unresolved, $value;
				$unresolved++;
			}
		}
	}

	# 4. What to tell the user.  Counts and keys, never a location value: a place
	# column in a personal dataset is personal data (section 7).
	my @messages;

	push @messages, $self->_message('error_map_geocoder_missing', $self->{'min_version'}, $reason)
		unless $available;

	push @messages, $self->_message('warn_map_geocode_capped', scalar @attempt, $wanted)
		if $capped;

	push @messages, $self->_message('warn_map_geocoder_unavailable_data')
		if @attempt && !$self->{'openaddr'};

	my @names = sort keys %backends;

	return {
		'available'	=> $available ? 1 : 0,
		'points'	=> \%points,
		'counts'	=> {
			'distinct'	=> $distinct,
			'skipped'	=> scalar @skipped,
			'cached'	=> $cached_resolved + $cached_unresolved,
			'attempted'	=> scalar @attempt,
			'lookups'	=> $lookups,
			'resolved'	=> $cached_resolved + $resolved,
			'unresolved'	=> $cached_unresolved + $unresolved,
			'not_attempted'	=> scalar @not_attempted,
		},
		'skipped'	=> \@skipped,
		'unresolved'	=> \@unresolved,
		'not_attempted'	=> \@not_attempted,
		'messages'	=> \@messages,
		'cache'		=> \%cache,
		'backends'	=> \%backends,
		'backend'	=> @names ? join(', ', @names) : undef,
		'capped'	=> $capped,
	};
}

# The options resolve_values() and resolve_column() share, validated once.
sub _options {
	my ($self, $opts) = @_;

	my $args = validate_strict(
		schema => {
			cache  => { type => 'hashref', optional => 1, default => undef },
			region => { type => 'string',  optional => 1, default => undef },
			max    => { type => 'scalar',  optional => 1, default => undef },
		},
		stack_trace => 1,
		input => $opts,
	);

	my $max = $DEFAULT_MAX;

	if (defined($args->{'max'})) {
		# A cap that is not a positive integer is a caller bug, not a location
		# that could not be resolved: it is refused rather than defaulted,
		# because defaulting would silently cap a request the caller meant to
		# raise, or raise one they meant to cap.
		croak(_fmt('error_max_invalid', $args->{'max'}))
			unless ($args->{'max'} =~ /\A\d+\z/) && ($args->{'max'} > 0);

		$max = $args->{'max'};
	}

	return {
		'cache'  => $args->{'cache'},
		'region' => $args->{'region'},
		'max'    => $max,
	};
}

=head2 resolve_values

=cut

sub resolve_values {
	my $self   = shift;
	my $values = shift;

	croak(_fmt('error_values_arrayref', defined($values) ? ref($values) || $values : 'undef'))
		unless ref($values) eq 'ARRAY';

	my $raw = Params::Get::get_params(undef, \@_) // {};

	return $self->_resolve($values, $self->_options($raw));
}

=head2 resolve_column

=cut

sub resolve_column {
	my $self   = shift;
	my $rows   = shift;
	my $column = shift;

	croak(_fmt('error_rows_arrayref', defined($rows) ? ref($rows) || $rows : 'undef'))
		unless ref($rows) eq 'ARRAY';

	croak(_fmt('error_column_required')) unless defined($column) && length($column);

	my $raw = Params::Get::get_params(undef, \@_) // {};

	# The cells in row order, and whether the column is there at all.  A row that
	# is not a hashref has no cell, which is one of the things that gets skipped
	# rather than a reason to stop.
	my @cells;
	my $found = 0;

	for my $row (@{ $rows }) {
		if (ref($row) eq 'HASH') {
			$found = 1 if exists $row->{$column};
			push @cells, $row->{$column};
			next;
		}

		push @cells, undef;
	}

	croak(_fmt('error_map_loc_column', $column)) if @{ $rows } && !$found;

	my $result = $self->_resolve(\@cells, $self->_options($raw));

	# How many rows hold each distinct value, and where the first of them is: what
	# an aggregated marker's popup and its draw order need.
	my (%row_count, %first_row);

	for my $index (0 .. $#cells) {
		my $key = (defined($cells[$index]) && !ref($cells[$index])) ? $cells[$index] : '';

		$row_count{$key}++;
		$first_row{$key} = $index unless exists $first_row{$key};
	}

	my $plotted = 0;

	for my $key (keys %{ $result->{'points'} }) {
		$result->{'points'}{$key}{'rows'}      = $row_count{$key};
		$result->{'points'}{$key}{'first_row'} = $first_row{$key};

		$plotted += $row_count{$key};
	}

	$result->{'markers'} = [
		map { { 'value' => $_, %{ $result->{'points'}{$_} } } }
		sort { $first_row{$a} <=> $first_row{$b} } keys %{ $result->{'points'} }
	];

	my $rows_total = scalar @cells;

	$result->{'counts'}{'rows'}     = $rows_total;
	$result->{'counts'}{'plotted'}  = $plotted;
	$result->{'counts'}{'unusable'} = $rows_total - $plotted;

	push @{ $result->{'messages'} }, $self->_message('warn_map_rows_skipped', $plotted, $rows_total, $rows_total - $plotted)
		if $plotted < $rows_total;

	return $result;
}

=head2 geocoder_available

=cut

sub geocoder_available {
	my $self = shift;

	return (1, undef) if $self->_geocoder();

	return (0, $self->_msg('error_map_geocoder_missing',
		$self->{'min_version'},
		$self->{'_unavailable'} // 'it is not installed'));
}

=head2 cache_from_models

=cut

sub cache_from_models {
	my ($class, $models, $spec_key) = @_;

	my $entry = (ref($models) eq 'HASH') ? $models->{'geo'}{$spec_key} : undef;

	return {} unless ref($entry) eq 'HASH' && (ref($entry->{'places'}) eq 'HASH');

	return { %{ $entry->{'places'} } };
}

=head2 models_with_cache

=cut

sub models_with_cache {
	my ($class, $models, $spec_key, $cache, %meta) = @_;

	my $spec = { %{ (ref($models) eq 'HASH') ? ($models->{'geo'}{$spec_key} // {}) : {} } };

	$spec->{'places'} = { %{ $cache // {} } };

	for my $key (qw(backend built)) {
		$spec->{$key} = $meta{$key} if defined($meta{$key});
	}

	my %updated = %{ (ref($models) eq 'HASH') ? $models : {} };

	$updated{'geo'} = { %{ $updated{'geo'} // {} }, $spec_key => $spec };

	return \%updated;
}

1;

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
