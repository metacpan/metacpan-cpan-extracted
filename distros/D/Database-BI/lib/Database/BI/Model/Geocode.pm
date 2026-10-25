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

use Carp			qw(croak carp);
use Readonly;
use Scalar::Util		qw(blessed);
use Params::Get			();
use Params::Validate::Strict	qw(validate_strict);

our $VERSION = '0.017.0';

# The version of Geo::Coder::Free this module asks for: 0.46 added valid_location()
# and on_error => 'undef', 0.47 added geocode_many(), and this module asks for both
# rather than reimplementing the rule or the batch loop it exists to use.
Readonly my $MIN_GEOCODER_VERSION => '0.47';

# The default for map_geocode_max (section 6.2): new lookups allowed in one
# request.  A crafted URL must not be able to turn one request into unbounded CPU.
Readonly my $DEFAULT_MAX => 500;

# The model store's shared place cache.  A place name means the same place
# whichever file's column holds it, so one answer serves every dataset: the
# second file that names Ramsgate plots it without asking the geocoder.  The
# key cannot collide with a per-dataset entry, which always starts with a spec
# scheme (path:, table:, url: or redis:).
Readonly my $SHARED_CACHE_KEY => 'shared';

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

	my $tmpl = (defined($key) ? $MESSAGES{$key} : undef)
	         // "Internal error: unknown message key '" . ($key // 'undef') . "'";

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

=encoding utf8

=head1 NAME

Database::BI::Model::Geocode - Resolve a location column to coordinates, once per distinct value

=head1 VERSION

0.013.0

=head1 SYNOPSIS

B<Geocode a table's place column and build map markers:>

    use Database::BI::Model::Geocode;

    my $geocode = Database::BI::Model::Geocode->new();
    my $result  = $geocode->resolve_column($rows, 'city');

    for my $marker (@{ $result->{'markers'} }) {
        printf "  %s: lat=%.4f lon=%.4f (%d rows)\n",
            $marker->{'value'}, $marker->{'lat'}, $marker->{'lon'},
            $marker->{'rows'};
    }

    my $c = $result->{'counts'};
    printf "Plotted %d of %d rows (%d skipped, %d unresolved)\n",
        $c->{'plotted'}, $c->{'rows'}, $c->{'skipped'}, $c->{'unresolved'};

B<Re-use remembered answers so the next request costs nothing:>

    # Load what was stored from a previous run.
    my $spec   = 'table:sales';
    my $models = decode_json(Mojo::File->new('.bi/models.json')->slurp);
    my $cache  = Database::BI::Model::Geocode->cache_from_models($models, $spec);

    # Resolve; cached values are used without asking the geocoder.
    my $result = $geocode->resolve_column($rows, 'city', cache => $cache);

    # Save the updated cache back to the models file.
    my $updated = Database::BI::Model::Geocode->models_with_cache(
        $models, $spec, $result->{'cache'},
        backend => $result->{'backend'},
        built   => '2026-10-18T12:00:00',
    );
    Mojo::File->new('.bi/models.json')->spew(encode_json($updated));

B<Warm the cache for a whole column without needing rows:>

    # Extract unique city values from your own data.
    my @cities = do { my %s; grep { !$s{$_}++ } map { $_->{'city'} } @{ $rows } };

    my $result = $geocode->resolve_values(\@cities,
        cache  => $cache,
        region => 'GB',
        max    => 1000,
    );

    printf "Resolved %d / %d new places\n",
        $result->{'counts'}{'resolved'}, $result->{'counts'}{'attempted'};

B<Ask whether the geocoder is available before offering it in the UI:>

    my $geocode = Database::BI::Model::Geocode->new();
    my ($ok, $why) = $geocode->geocoder_available();

    unless ($ok) {
        carp "Map panel disabled: $why";
    }

B<Inject a test double so geocoding works without a real geocoder:>

    package MyGeocoderStub;
    sub new            { bless {}, shift }
    sub valid_location { my ($self, $v) = @_; $v && $v !~ /\A\d+\z/ }
    sub geocode_many   {
        my ($self, $places, %opts) = @_;
        return { 'London' => { lat => 51.5, long => -0.12, database => 'stub' } };
    }

    my $geocode = Database::BI::Model::Geocode->new(geocoder => MyGeocoderStub->new);
    my $result  = $geocode->resolve_column($rows, 'city');

=head1 DESCRIPTION

C<Geo::Coder::Free> resolves a place name to a C<Geo::Location::Point>.  A table
column holds something less tidy: values repeated thousands of times, blank cells,
numbers that drifted in from an adjacent column.  This module does the three things
the column then needs.

=over 4

=item B<Ask once per distinct value.>

The column is reduced to a set before any lookup happens.  A repeated city name
costs one lookup, so a 100,000-row file with a dozen cities costs twelve lookups,
not 100,000.

=item B<Refuse a value that is not a location before any backend sees it.>

C<< $geocoder->valid_location($value) >> is the gate the geocoder's own guard
applies before looking anything up.  This module asks the same question first, so
a pure-digit string (a row number that ended up in the wrong column), an empty
cell, or a Perl reference is counted and reported as skipped rather than sent to
a backend that would reject it anyway.

=item B<Look the rest up without letting one value end the batch.>

The batch is requested with C<< on_error => 'undef' >>.  A value the geocoder
refuses after the pre-filter is a miss; a backend that throws an exception is
still a throw, because nothing here wraps the geocoder in an C<eval>.

=back

The counts the module returns add up, always.

    skipped + cached + attempted + not_attempted  ==  distinct
    resolved + unresolved                         ==  cached + attempted

C<lookups> is the number the geocoder itself reports for the batch.  With
C<Geo::Coder::Free> 0.48 and later it may be lower than C<attempted>, because
the geocoder counts database reads and a value it answered from a warm process
cache costs zero reads.  It never exceeds C<attempted>.

=head2 The cache

A cache entry is a C<[lat, lon]> arrayref for a place that resolved, or the
scalar C<0> for a place that was looked up and not found.  That C<0> sentinel
prevents a column of unresolvable values from being retried on every page
request.

The cache is passed per call and returned per call.  The caller's hashref is
never modified: a request that dies part way through cannot leave a half-written
cache behind.  The controller is responsible for persisting the returned cache,
which keeps the C<model_dir>-inside-C<data_dir> guard in the one place that
already owns it.

A previously stored cache is used even when the geocoder is not available.
Places already resolved continue to be plotted; only new lookups are unavailable.

=head2 Without the geocoder

C<Geo::Coder::Free> is a recommended dependency, not a required one.  It is
loaded the first time it is needed, not at compile time.  When it is absent or
older than the minimum version:

=over 4

=item *

C<< $geocode->geocoder_available() >> returns C<(0, $reason)>.

=item *

C<resolve_column> and C<resolve_values> still return a complete result: all
values are placed in C<not_attempted>, cached answers are still plotted, and
the C<error_map_geocoder_missing> message explains the situation.

=item *

Nothing croaks.  The page renders with whatever the cache already holds.

=back

=head1 CONSTRUCTOR

=head2 new

    my $geocode = Database::BI::Model::Geocode->new(%options);
    my $geocode = Database::BI::Model::Geocode->new(\%options);  # hashref also accepted

Create a new resolver.  Accepts a flat key/value list or a hashref; both forms
are handled by C<Params::Get>.

=head3 API SPECIFICATION

=head4 INPUT

    geocoder             => object,   # optional; duck-typed: must provide valid_location() and geocode_many()
    openaddr             => string,   # optional; path to OpenAddresses data (default: $ENV{OPENADDR_HOME})
    min_geocoder_version => string,   # optional; minimum version to accept (default: '0.47')
    i18n                 => object,   # optional; must implement maketext($key, @args)

C<geocoder> is the injection seam for tests.  An injected geocoder is used
exactly as given: it is not version-checked, so any object that responds to
C<valid_location()> and C<geocode_many()> works.  A geocoder that fails either
C<can()> check causes an immediate C<croak> (C<error_geocoder_interface>), not
a silent degradation.

C<openaddr> overrides C<$ENV{OPENADDR_HOME}>.  It is forwarded to
C<< Geo::Coder::Free->new(openaddr => ...) >>.  When it is absent and the
environment variable is not set, the geocoder uses its built-in MaxMind data
only, which resolves city and country names but not street addresses.
C<warn_map_geocoder_unavailable_data> is emitted in that case.

C<min_geocoder_version> lets the caller pin the floor, or a test simulate
a too-old installation on a machine that has the current version.

C<i18n> is an optional object whose C<maketext($key, @args)> method is called
in place of the built-in C<%MESSAGES> table.  The key is one of the constants
defined in C<%MESSAGES>; the args are the same positional values C<sprintf>
would receive.

=head4 OUTPUT

Returns C<$self>.

Croaks with C<error_geocoder_interface> if the injected C<geocoder> does not
provide both C<valid_location()> and C<geocode_many()>.

Never croaks because the geocoder module is absent or too old: that is a
runtime condition reported by C<geocoder_available()>, not a constructor error.

=head1 SUBROUTINES/METHODS

=head2 resolve_column

    my $result = $geocode->resolve_column(\@rows, $column_name, %options);

Resolve one named column of a table.  C<\@rows> is an arrayref of hashrefs
(the records from the data pipeline), and C<$column_name> is the key to look
up in each row.

This is the main entry point for the map controller.  It runs the same
resolution as L</resolve_values>, then adds per-marker row counts and the
C<markers> list that a map rendering loop needs.

=head3 API SPECIFICATION

=head4 INPUT

    \@rows          => arrayref of hashrefs, required
    $column_name    => non-empty string, required
    cache    => hashref,            # optional; { value => [lat, lon] | 0 }
    region   => two-letter string,  # optional; country hint for the geocoder (e.g. 'GB')
    max      => positive integer,   # optional; max new lookups; default 500

C<\@rows> is the full record set as returned by the pipeline.  Rows that are
not hashrefs produce an C<undef> cell, which is classified as skipped.

C<$column_name> must be a non-empty string.  It is used as a hash key; it is
not validated against a schema, so a column name with spaces or special
characters is accepted if the data uses one.

C<cache> holds the already-known answers for this column.  Entries are either
a C<[lat, lon]> arrayref (resolved) or C<0> (looked up and not found).  The
caller's hashref is never modified; the returned C<cache> key holds the
updated copy.

C<region> is passed straight through to the geocoder as a country hint.  It
is not derived from the Accept-Language header, because a language is not a
country.

C<max> is counted in new lookups, not rows.  A cached answer costs nothing
and does not count toward it.  Values held back by the cap go into
C<not_attempted> and are not stored in the cache, so the next request picks
them up.

=head4 OUTPUT

Returns a hashref:

    {
        available     => 1 | 0,
        points        => { $value => { lat => $n, lon => $n, rows => $n, first_row => $n, backend? => $s } },
        markers       => [ { value => $s, lat => $n, lon => $n, rows => $n, first_row => $n } ],
        counts        => {
            rows          => $n,   # total rows in \@rows
            plotted       => $n,   # rows whose value resolved to a point
            unusable      => $n,   # rows - plotted
            distinct      => $n,   # unique values seen
            skipped       => $n,   # refused before any lookup (empty, ref, digit-only)
            cached        => $n,   # found in the cache (resolved or not)
            attempted     => $n,   # sent to the geocoder this request
            lookups       => $n,   # lookups the geocoder reports (may be < attempted)
            resolved      => $n,   # total with a position (cache + new)
            unresolved    => $n,   # total without (cache + new)
            not_attempted => $n,   # held back by the cap, or skipped because no geocoder
        },
        skipped       => [ $value, ... ],   # values refused before lookup
        unresolved    => [ $value, ... ],   # values tried (now or before) and not found
        not_attempted => [ $value, ... ],   # held back by the cap
        messages      => [ { key => $k, text => $t }, ... ],
        cache         => { $value => [lat, lon] | 0 },   # updated copy; never the caller's hashref
        backends      => { $backend_name => $count },
        backend       => $backend_name | undef,          # undef when nothing resolved
        capped        => 0 | 1,
    }

C<points> holds one entry per value that produced a position, whether the
position came from the cache or from this request.  C<markers> is the same
data in first-seen row order, which reads better on a map than alphabetical
order.

C<backend> on a point entry is set only for values looked up in this request;
cached values do not carry one because the cache stores a position, not which
database gave it.  The top-level C<backend> is the name of the backend that
answered the most lookups this request.

The count invariant always holds:

    skipped + cached + attempted + not_attempted  ==  distinct

=head3 MESSAGES

    error_rows_arrayref                -- \@rows is not an arrayref
    error_column_required              -- $column_name is empty or undef
    error_map_loc_column               -- column not found in any row
    error_map_geocoder_missing         -- no geocoder, or version below the floor
    warn_map_rows_skipped              -- some rows could not be plotted
    warn_map_geocode_capped            -- the cap held some values back
    warn_map_geocoder_unavailable_data -- OPENADDR_HOME not set; coarse resolution only

=head3 EXAMPLE

    my $cache   = Database::BI::Model::Geocode->cache_from_models($models, $spec);
    my $result  = $geocode->resolve_column($rows, 'city',
        cache  => $cache,
        region => 'GB',
        max    => 200,
    );

    if ($result->{'capped'}) {
        carp "Some cities were not looked up; load the page again to finish them.";
    }

    for my $m (@{ $result->{'markers'} }) {
        printf "[%.4f, %.4f]  %s (%d rows)\n",
            $m->{'lat'}, $m->{'lon'}, $m->{'value'}, $m->{'rows'};
    }

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

	# geocoder_available() already returns the finished sentence, so it is used as
	# the text; formatting it again repeated the whole message.
	push @messages, {
		'key'  => 'error_map_geocoder_missing',
		'text' => defined($reason) ? $reason : $self->_msg('error_map_geocoder_missing', $self->{'min_version'}, 'it is not installed'),
	} unless $available;

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

    my $result = $geocode->resolve_values(\@values, %options);
    my $result = $geocode->resolve_values(\@values, \%options);

Resolve a flat list of cell values, without the context of any row structure.
Use this when you want to warm the cache for a column's distinct values, or
when you have already extracted the values yourself and do not need per-marker
row counts.

The returned hashref is identical to L</resolve_column>'s, except that
C<counts.rows>, C<counts.plotted>, C<counts.unusable>, and C<markers> are
absent, and C<warn_map_rows_skipped> is never emitted.

=head3 API SPECIFICATION

=head4 INPUT

    \@values => arrayref, required;  elements may be any scalar or undef
    cache    => hashref,             # optional; { value => [lat, lon] | 0 }
    region   => string,              # optional; two-letter country hint
    max      => positive integer,    # optional; new lookups allowed; default 500

Duplicate values in C<\@values> cost one lookup each.  C<undef>, references,
empty strings, and pure-digit strings are refused before any lookup and counted
as C<skipped>.

=head4 OUTPUT

Returns a hashref (same shape as L</resolve_column> but without C<markers>,
C<counts.rows>, C<counts.plotted>, and C<counts.unusable>):

    {
        available     => 1 | 0,
        points        => { $value => { lat => $n, lon => $n, backend? => $s } },
        counts        => {
            distinct      => $n,
            skipped       => $n,
            cached        => $n,
            attempted     => $n,
            lookups       => $n,
            resolved      => $n,
            unresolved    => $n,
            not_attempted => $n,
        },
        skipped       => [ $value, ... ],
        unresolved    => [ $value, ... ],
        not_attempted => [ $value, ... ],
        messages      => [ { key => $k, text => $t }, ... ],
        cache         => { $value => [lat, lon] | 0 },
        backends      => { $name => $count },
        backend       => $name | undef,
        capped        => 0 | 1,
    }

Croaks with C<error_values_arrayref> if C<\@values> is not an arrayref.

=head3 EXAMPLE

    # Build the distinct-value list yourself and warm the cache offline.
    my %seen;
    my @cities = grep { defined($_) && !$seen{$_}++ } map { $_->{'city'} } @{ $rows };

    my $result = $geocode->resolve_values(\@cities,
        cache  => $cache,
        region => 'GB',
        max    => 2000,
    );

    printf "New lookups: %d  Resolved: %d  Unresolved: %d\n",
        $result->{'counts'}{'attempted'},
        $result->{'counts'}{'resolved'},
        $result->{'counts'}{'unresolved'};

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

See full documentation above, in L</SUBROUTINES/METHODS>.

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

    my ($is_available, $reason) = $geocode->geocoder_available();

Ask whether this object can make new geocoder lookups.  Returns a list of two
values: a boolean (C<1> or C<0>) and a human-readable reason string when the
answer is no.

Loads C<Geo::Coder::Free> lazily on the first call if it has not been loaded
yet.  Never croaks: a panel uses this to decide whether to show the location
option, so the answer must always be a string, not an exception.

=head3 API SPECIFICATION

=head4 INPUT

None.  (No arguments accepted.)

=head4 OUTPUT

    ($available, $reason)

    $available => 1      # geocoder is ready
    $available => 0      # geocoder is not available
    $reason    => undef  # when $available is 1
    $reason    => string # error_map_geocoder_missing text; when $available is 0

=head3 EXAMPLE

    my ($ok, $reason) = $geocode->geocoder_available();

    if (!$ok) {
        # Disable the "Map by location column" panel option.
        $stash->{'map_loc_disabled'} = 1;
        $stash->{'map_loc_disabled_reason'} = $reason;
    }

=cut

sub geocoder_available {
	my $self = shift;

	return (1, undef) if $self->_geocoder();

	return (0, $self->_msg('error_map_geocoder_missing',
		$self->{'min_version'},
		$self->{'_unavailable'} // 'it is not installed'));
}

=head2 cache_from_models

    my $cache = Database::BI::Model::Geocode->cache_from_models(\%models, $spec_key);

Extract the geocode cache for one dataset spec from a model store.  Returns a
B<copy> of the stored places hashref so the caller cannot accidentally modify
the model store.

This is a B<class method>: call it on the package name, or on an instance if
you prefer; either way the invocant is ignored.

=head3 API SPECIFICATION

=head4 INPUT

    \%models  => hashref, required;  the structure returned by _read_models()
    $spec_key => string, required;   the dataset spec (e.g. 'table:sales')

=head4 OUTPUT

Returns a plain hashref:

    { $place_name => [lat, lon] | 0, ... }

Returns an empty hashref C<{}> for an unknown spec, a spec that has never
been geocoded, or a C<\%models> argument that is not a hashref.  Never
croaks.

=head3 EXAMPLE

    my $models = decode_json(Mojo::File->new($model_path)->slurp);
    my $cache  = Database::BI::Model::Geocode->cache_from_models(
        $models, 'table:sales'
    );

    # $cache is now { 'Ramsgate' => [51.336, 1.416], 'Paris' => 0, ... }

=cut

sub cache_from_models {
	my ($class, $models, $spec_key) = @_;

	my $entry = (ref($models) eq 'HASH') ? $models->{'geo'}{$spec_key} : undef;

	return {} unless ref($entry) eq 'HASH' && (ref($entry->{'places'}) eq 'HASH');

	return { %{ $entry->{'places'} } };
}

=head2 models_with_cache

    my $updated_models = Database::BI::Model::Geocode->models_with_cache(
        \%models, $spec_key, \%cache,
        backend => 'OpenAddresses',
        built   => '2026-10-18T12:00:00',
    );

Produce a new model store in which the geocode cache for C<$spec_key> is
replaced with C<\%cache>.  Every other key in the model store, and every
other spec's geocode data, is carried over unchanged.

This is a B<class method>; the invocant is ignored.

This module never writes the file.  The caller is responsible for passing
C<$updated_models> to C<_write_models()> or its equivalent, which is where
the writability and C<data_dir> guards live.  The separation keeps those
guards in the one place that already owns them (section 7 of the phase spec).

=head3 API SPECIFICATION

=head4 INPUT

    \%models  => hashref, required;  the existing model store (not modified)
    $spec_key => string, required;   the dataset spec to update
    \%cache   => hashref, required;  { place => [lat, lon] | 0 }
    backend   => string, optional;   name of the geocoder backend that resolved
    built     => string, optional;   ISO-8601 timestamp of when the cache was built

=head4 OUTPUT

Returns a new hashref.  The caller's C<\%models> is never modified.

    {
        ...all existing model keys...,
        geo => {
            ...all existing geo specs...,
            $spec_key => {
                places  => \%cache,
                backend => $backend,  # if supplied
                built   => $built,    # if supplied
            },
        },
    }

=head3 EXAMPLE

    my $updated = Database::BI::Model::Geocode->models_with_cache(
        $models,
        'path:/data/sales.csv',
        $result->{'cache'},
        backend => $result->{'backend'},
        built   => '2026-10-18T09:15:42',
    );

    # Now write the updated store to disk.
    Mojo::File->new($model_path)->spew(encode_json($updated));

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

=head2 shared_cache_from_models

    my $cache = Database::BI::Model::Geocode->shared_cache_from_models(\%models);

Extract the place answers every dataset shares, as a B<copy> the caller may
modify.  This is the cache a map request should pass to C<resolve_column>:
a place geocoded for one file is then plotted for every other file that names
it, without a second lookup.

A model store written before the cache was shared has no shared entry; this
returns C<{}> and the per-dataset caches remain readable with
C<cache_from_models>.  A caller that reads both gets the old answers once and
writes them back to the shared entry (see C<models_with_shared_cache>).

This is a B<class method>; the invocant is ignored.

=head3 API SPECIFICATION

=head4 INPUT

    \%models  => hashref, required;  the structure returned by _read_models()

=head4 OUTPUT

    { $place_name => [lat, lon] | 0, ... }

Returns an empty hashref for a store with no shared cache, for a malformed
entry, or for a C<\%models> argument that is not a hashref.  Never croaks.

=head3 EXAMPLE

    my $models = decode_json(Mojo::File->new($model_path)->slurp);
    my $cache  = Database::BI::Model::Geocode->shared_cache_from_models($models);

    # $cache is now { 'Ramsgate' => [51.336, 1.416], 'Paris' => 0, ... }

=cut

sub shared_cache_from_models {
	my ($class, $models) = @_;

	my $entry = (ref($models) eq 'HASH') ? $models->{'geo'}{$SHARED_CACHE_KEY} : undef;

	return {} unless ref($entry) eq 'HASH' && (ref($entry->{'places'}) eq 'HASH');

	return { %{ $entry->{'places'} } };
}

=head2 models_with_shared_cache

    my $updated_models = Database::BI::Model::Geocode->models_with_shared_cache(
        \%models, \%cache,
        backend => 'OpenAddresses',
        built   => '2026-10-18T12:00:00',
    );

Produce a new model store in which the shared place cache holds C<\%cache>.
The cache is B<merged>, not replaced: a request writes back every place it
saw, and another request may have answered a different place since this one
read the store.  Other model keys, and every per-dataset C<geo> entry, are
carried over unchanged.

This module never writes the file, and does not add a per-dataset entry.  The
caller passes the result to C<_write_models()> or its equivalent, where the
writability and C<data_dir> guards live.

=head3 API SPECIFICATION

=head4 INPUT

    \%models => hashref, required;  the existing model store (not modified)
    \%cache  => hashref, required;  { place => [lat, lon] | 0 }
    backend  => string, optional;   name of the geocoder backend that resolved
    built    => string, optional;   ISO-8601 timestamp of the cache update

=head4 OUTPUT

Returns a new hashref.  The caller's C<\%models> is never modified.

    {
        ...all existing model keys...,
        geo => {
            ...all existing per-dataset entries...,
            shared => {
                places  => \%merged_cache,
                backend => $backend,  # if supplied
                built   => $built,    # if supplied
            },
        },
    }

=head3 EXAMPLE

    my $updated = Database::BI::Model::Geocode->models_with_shared_cache(
        $models,
        $result->{'cache'},
        backend => $result->{'backend'},
        built   => '2026-10-18T09:15:42',
    );

    Mojo::File->new($model_path)->spew(encode_json($updated));

=cut

sub models_with_shared_cache {
	my ($class, $models, $cache, %meta) = @_;

	# Merge over what is already shared: the request may have read the store
	# before another one resolved a place, and replacing the entry would lose
	# that answer for every dataset rather than just this request.
	my %places = (
		%{ $class->shared_cache_from_models($models) },
		%{ (ref($cache) eq 'HASH') ? $cache : {} },
	);

	my $spec = { %{ (ref($models) eq 'HASH') ? ($models->{'geo'}{$SHARED_CACHE_KEY} // {}) : {} } };

	$spec->{'places'} = \%places;

	for my $key (qw(backend built)) {
		$spec->{$key} = $meta{$key} if defined($meta{$key});
	}

	my %updated = %{ (ref($models) eq 'HASH') ? $models : {} };

	$updated{'geo'} = { %{ $updated{'geo'} // {} }, $SHARED_CACHE_KEY => $spec };

	return \%updated;
}

1;

=head1 COMMON PITFALLS

=over 4

=item B<The cache sentinel 0 is not "false -- never looked up".>

A cache entry of C<0> means the place was looked up and not found.  An absent
key means it has never been attempted.  The module treats these two states
differently: a C<0> entry contributes to C<counts.unresolved> without
triggering a new lookup; an absent key enters the classification loop and may
reach the geocoder.

    # WRONG -- checking definedness misses the 0 sentinel.
    my $resolved = defined($cache{$place});

    # CORRECT -- use the internal _has_position logic.
    my $resolved = (ref($cache{$place}) eq 'ARRAY');

=item B<Pure-digit strings are skipped, not attempted.>

A value like C<'42'> fails C<valid_location()> and goes into C<@skipped>.  It
is never stored in the cache.  This is the correct behaviour for a row number
that ended up in the wrong column, but it surprises callers who expect every
non-empty value to be attempted.

=item B<The returned cache is a copy; the caller's hashref is never modified.>

Do not compare C<$cache_you_passed_in> with C<$result->{'cache'}> expecting
them to be the same reference.  The update is in C<$result->{'cache'}>.

=item B<resolve_column croaks when the column is absent; resolve_values does not.>

C<resolve_column> checks that the named column appears in at least one row.
If it does not, it croaks with C<error_map_loc_column>.  C<resolve_values>
does not do this check, because it receives values, not rows.

=item B<max counts new lookups, not rows or distinct values.>

A value already in C<cache> does not count toward C<max>, even if it was
looked up in a previous request.  A value skipped by C<valid_location()> does
not count either.

=item B<new() always succeeds; geocoder load failure is not a constructor error.>

You can always call C<new()> without checking whether C<Geo::Coder::Free> is
installed.  The load failure is deferred to the first call that needs the
geocoder, and is reported through C<geocoder_available()> and the
C<messages> array in the result, not through an exception.

=item B<cache_from_models and models_with_cache are class methods.>

You may call them on an instance for convenience, but the invocant is not used.
The pattern C<< Database::BI::Model::Geocode->cache_from_models(...) >> is
clearer.

=item B<The geocoder batch receives on_error => 'undef'.>

A value the geocoder rejects after the C<valid_location()> pre-filter is
returned as C<undef> from the batch; it does not croak.  A backend that throws
an exception (a real database error, a network failure) still propagates
upward, because nothing here wraps the geocoder in an C<eval>.

=back

=head1 ENCODING

=over 4

=item B<Place names (values in the location column)>

Passed to the geocoder as byte strings.  UTF-8 place names such as
"Koeln" or "Beijing" are supported if the geocoder backend handles them.
The internal code does not re-encode or validate the bytes; it compares them
as opaque strings for deduplication and caching.

=item B<Column names>

Matched against row hash keys with a string equality test.  The column name
must be byte-for-byte identical to the key in the row hashrefs.  Column names
with non-ASCII bytes are accepted.

=item B<Spec keys (the $spec_key argument)>

Used as hash keys in the model store.  Any byte sequence is safe; UTF-8 spec
keys are stored and retrieved without modification.

=item B<Message strings>

The built-in C<%MESSAGES> table contains ASCII-only text.  If your application
needs non-ASCII messages (for example, a French translation), supply an C<i18n>
object to C<new()> whose C<maketext> method renders the key in the desired
locale.

=item B<Geocoder result strings (backend names)>

Stored and reported as returned by the geocoder.  The module does not impose
any encoding on them.

=back

=head1 DIAGNOSTICS

All user-visible messages are keyed in C<%Database::BI::Model::Geocode::MESSAGES>.

=over 4

=item C<error_map_geocoder_missing>

    Geocoding a location column needs Geo::Coder::Free %s or later, and %s

The geocoder module is not installed (the second C<%s> is "it is not
installed") or is too old (the second C<%s> is the installed version number).
Install or upgrade C<Geo::Coder::Free>.

=item C<error_map_loc_column>

    Column "%s" is not in this dataset, so there is nothing to geocode

The C<$column_name> argument to C<resolve_column()> did not appear as a key in
any row.  Check the column name, including case and any spaces.

=item C<error_geocoder_interface>

    Geocode: the geocoder must provide %s; Geo::Coder::Free %s or later does

An injected C<geocoder> object does not respond to C<valid_location()> or
C<geocode_many()>.  Either use the real C<Geo::Coder::Free> or add the missing
method to your stub.

=item C<error_max_invalid>

    Geocode: option "max" must be a positive integer, not "%s"

The C<max> option was supplied but is not a positive integer string.  Passing
C<max => 0> and C<max => 'all'> both trigger this error.

=item C<error_values_arrayref>

    Geocode: the values must be an arrayref, not "%s"

The first argument to C<resolve_values()> is not an arrayref.  Pass
C<\@values> (a reference), not C<@values> (a flat list).

=item C<error_rows_arrayref>

    Geocode: the rows must be an arrayref, not "%s"

The first argument to C<resolve_column()> is not an arrayref.

=item C<error_column_required>

    Geocode: the column name is required

The C<$column_name> argument to C<resolve_column()> is C<undef> or an empty
string.

=item C<warn_map_rows_skipped>

    Plotted %d of %d rows; %d hold no location that could be plotted ...

Some rows in the input had a cell that was empty, a bare number, or a place
that the geocoder could not find.  The count of plotted rows is less than the
total.  Not an error: the map renders with the rows that could be resolved.

=item C<warn_map_geocode_capped>

    Geocoded %d of the %d places that had not been looked up before; ...

The C<max> cap prevented all pending values from being looked up in this
request.  The un-looked-up values are in C<not_attempted> and are not stored
in the cache, so the next request picks them up.

=item C<warn_map_geocoder_unavailable_data>

    The geocoder has no OpenAddresses data configured (OPENADDR_HOME), ...

The geocoder was loaded successfully but C<OPENADDR_HOME> is not set and
C<openaddr> was not passed to C<new()>.  Resolution will succeed for broad
place names (cities, countries) but will fail for street-level addresses.
Set the environment variable or pass C<openaddr => $path> to C<new()>.

=back

=head1 FORMAL SPECIFICATION

The following sections use Z calculus notation to describe the exact state
transitions and invariants of each public operation.  Notation: ∈ (member of),
∉ (not member of), ⊆ (subset), ∪ (union), ∩ (intersection), ∧ (and), ∨ (or),
¬ (not), ∀ (for all), ∃ (there exists), → (maps to), ≤ (less than or equal),
≠ (not equal).

=head3 FORMAL SPECIFICATION

State transitions and invariants for each operation are described below.

=head2 _resolve -- value classification and batch geocoding

Let V be the multiset of input values.

Define the following disjoint sets that partition distinct(V):

    SKIPPED          = { v | v = undef, ref(v), or len(v) = 0,
                             or geocoder.valid_location(v) = false }
    CACHED_RESOLVED  = { v | v in dom(CACHE) and _has_position(CACHE(v)) }
    CACHED_UNRESOLVED = { v | v in dom(CACHE) and not _has_position(CACHE(v)) }
    NOT_ATTEMPTED    = { v | geocoder unavailable } (excludes SKIPPED and CACHED)
    PENDING          = distinct(V) \ (SKIPPED ∪ CACHED_RESOLVED ∪ CACHED_UNRESOLVED
                                      ∪ NOT_ATTEMPTED)

Partition invariant:

    |SKIPPED| + |CACHED_RESOLVED| + |CACHED_UNRESOLVED|
        + |NOT_ATTEMPTED| + |PENDING| = |distinct(V)|

Cap application (MAX = the max option, default 500):

    ATTEMPT        = PENDING[0 .. min(MAX, |PENDING|) - 1]
    CAPPED         = |PENDING| > MAX
    NOT_ATTEMPTED' = NOT_ATTEMPTED ∪ PENDING[MAX .. |PENDING| - 1]   (when CAPPED)

Geocoding step -- for each v in ATTEMPT:

    BATCH = geocoder.geocode_many(ATTEMPT, on_error => 'undef')

    for v in ATTEMPT:
        (lat, lon) = coordinates(BATCH(v))
        if defined(lat) and defined(lon):
            CACHE'(v)  = [lat, lon]
            POINTS'(v) = { lat, lon, backend? }
        else:
            CACHE'(v)  = 0
            UNRESOLVED_NEW += {v}

Count invariants (always hold):

    skipped + cached + attempted + not_attempted = distinct(V)
    resolved + unresolved = cached + attempted
    resolved  = |CACHED_RESOLVED| + |ATTEMPT ∩ POINTS'|
    unresolved = |CACHED_UNRESOLVED| + |ATTEMPT \ POINTS'|
    lookups   <= attempted

Cache monotonicity:

    dom(CACHE') ⊇ dom(CACHE)
    For all v in dom(CACHE): CACHE'(v) = CACHE(v)  (existing entries not modified)

=head2 resolve_column -- row augmentation

Given the output R of _resolve applied to the column's cell sequence CELLS:

    row_count  : Value -> N   where row_count(v) = |{ i | CELLS[i] = v }|
    first_row  : Value -> N   where first_row(v)  = min{ i | CELLS[i] = v }

    For each v in dom(R.points):
        R.points(v).rows      = row_count(v)
        R.points(v).first_row = first_row(v)

    R.markers = [ { value: v, ...R.points(v) }
                  | v <- sort_by(first_row, dom(R.points)) ]

    R.counts.rows     = |CELLS|
    R.counts.plotted  = sum{ row_count(v) | v in dom(R.points) }
    R.counts.unusable = R.counts.rows - R.counts.plotted

=head2 cache_from_models -- safe extraction

    cache_from_models(models, spec)
        = if ref(models) = HASH and ref(models.geo.spec) = HASH
                                and ref(models.geo.spec.places) = HASH
            then copy(models.geo.spec.places)
            else {}

The result is a shallow copy: the caller cannot modify the model store by
modifying the returned hashref, but values inside the cache (the [lat, lon]
arrayrefs) are shared references.

=head2 models_with_cache -- safe merge

    models_with_cache(models, spec, cache, backend?, built?)
        = { ...models,
            geo: { ...models.geo,
                   spec: { ...models.geo.spec,
                            places:  copy(cache),
                            backend: backend (if defined),
                            built:   built   (if defined) } } }

The caller's models hashref is never modified; a new top-level hashref is
returned.

=head1 STATE DIAGRAM

The object transitions through three states based on whether the geocoder
has been loaded yet.

    new()
      |
      v
  +-------------------+
  |    CONSTRUCTED    |  Geocoder not yet lazy-loaded.
  |  _geocoder not    |  resolve_*() and geocoder_available()
  |  yet called       |  may trigger a load on first call.
  +-------------------+
       |          |
  first call,     first call,
  module OK       module absent or too old
       |          |
       v          v
  +---------+  +------------+
  |  READY  |  | UNAVAILABLE|
  |         |  |            |
  | Geocoder|  | No lookups |
  | loaded  |  | possible.  |
  | and     |  | Cache still|
  | working.|  | served.    |
  +---------+  +------------+
       |          |
  resolve_*()  resolve_*()
  geocodes +   cache only;
  cache        not_attempted
       |          |
       v          v
  +---------+  +------------+
  |  READY  |  | UNAVAILABLE|
  | (no     |  | (no        |
  | change) |  | change)    |
  +---------+  +------------+

Resolution itself is stateless: the object's geocoder-load state does not
change after the first load attempt.  All state is in the result hashref and
the cache the caller manages.

Value-level state transitions within a single resolve_* call:

    RECEIVED
       |
       +--[undef / ref / empty]-----------> SKIPPED
       |
       +--[in cache, has position]---------> CACHED_RESOLVED --> POINTS
       |
       +--[in cache, no position (= 0)]----> CACHED_UNRESOLVED --> UNRESOLVED
       |
       +--[geocoder unavailable]-----------> NOT_ATTEMPTED
       |
       +--[valid_location() = false]-------> SKIPPED
       |
       +--[within cap]--------------------> ATTEMPT
       |                                        |
       |                                        +--[geocoder returns position]--> RESOLVED_NEW --> POINTS, CACHE==[lat,lon]
       |                                        |
       |                                        +--[geocoder returns undef]-----> UNRESOLVED_NEW, CACHE==0
       |
       +--[beyond cap]-------------------> NOT_ATTEMPTED

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
