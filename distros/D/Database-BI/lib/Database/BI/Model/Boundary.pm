package Database::BI::Model::Boundary;

# The outline of the area each map marker is in: its country, state or
# province, county, city, town or neighbourhood (the level).
#
# A map can draw the boundary of the area around each of its markers.  The
# outlines come from OpenStreetMap's Nominatim, through its reverse lookup:
# given a point and a zoom, it names the administrative area there and, with
# polygon_geojson, sends its shape.  Asking by point rather than by name means
# the same code serves coordinate columns and geocoded places, in any country,
# and needs no state or country column to tell one Richmond from another.
#
# Nominatim allows one request a second, so this module asks as little as it
# can:
#
#   1. Each point is rounded to 3 decimal places (about 110 m), which is also
#      all of it that leaves this machine, and remembered with the outline it
#      fell in (or with none, for a point at sea).
#   2. A point not remembered is first tested against the outlines already
#      known, through an index of their bounding boxes, so ten thousand shops
#      in one county cost one request, not ten thousand.
#   3. Only then is Nominatim asked, at most online_max times a call, and a
#      point it does not answer is left pending, not remembered as nowhere.
#
# The outlines are simplified by Nominatim (polygon_threshold), about 7 KB each,
# because they are written into the page.
#
# What Nominatim has at each level differs by country, and was probed in
# November 2026 (the points and what came back are in the comments at %LEVELS).
# A level is therefore a plan: a list of tries, each a reverse zoom and the
# place ranks an answer may have, taken in order until one gives an outline.
#
#   country        zoom 3, rank 4.
#   state          zoom 5, rank 8: a US or Indian state, a Canadian province, a
#                  New Zealand region, England or Scotland.
#   county         below, one rank a country.
#   city           zoom 10, ranks 12 to 16, an administrative area or a place
#                  mapped as an area: Toronto, Manchester, Canterbury (the
#                  district), Bristol.  Where zoom 10 gives only a point (York,
#                  Pune), zoom 8 at rank 12: the unitary authority or city
#                  district.  A point in no city gets its rank 12 area
#                  too (a US county): zoom 10 answers with it.  New Zealand's cities are its territorial
#                  authorities, rank 12 at zoom 8 (Hamilton City), or the region
#                  where that is one (Auckland).
#   town           zoom 12, ranks 13 to 18: Margate, a Toronto ward.  Then zoom
#                  14, ranks 19 and 20, administrative areas only: a town
#                  that is a civil parish (Westgate-on-Sea).
#   neighbourhood  zoom 14, ranks 17 to 20: a Toronto neighbourhood, an English
#                  civil parish (Westgate-on-Sea), a suburb mapped as an area
#                  (Manchester's City Centre).  Most suburbs are mapped as a
#                  point (Cliftonville, Garlinge), and those have no outline.
#
# The larger the area, the more its outline is simplified (the level's detail),
# or a country would be megabytes.  An outline is kept under its detail, so one
# relation drawn at two levels (Auckland, a state and a city) is kept twice.
#
# A "county" is the division of a country below its states.  Which
# of Nominatim's place ranks that is depends on the country, so %LEVELS gives a
# rank for most (12: a US county, an English county, a German Landkreis, a
# French departement, a Pakistani district) and the countries that differ (10:
# an Indian or Bangladeshi district, a Chinese prefecture, a Spanish province;
# 8: a Kenyan county), and config map_bounds_ranks can add more.  Each reply
# names its country, so a point is asked at the zoom of the last country seen,
# and again at its own country's zoom when that guess was wrong: one extra
# request at each border a map crosses.  The rank an outline was accepted at is
# kept with it, so a changed table asks again rather than draw the old level.
# The other levels do the same with their plans: a point is asked the first try
# of the last country's plan, and its own country's plan from there.

use strict;
use warnings;

use Carp			qw(croak);
use JSON::PP			();
use List::Util			qw(first);
use Params::Get			();
use Params::Validate::Strict	qw(validate_strict);
use Readonly;
use Scalar::Util		qw(blessed);
use URI				();

our $VERSION = '0.023.1';

# The place rank an answer must have at each level: rank for a country not
# listed, countries for those that differ, by ISO 3166-1 alpha-2 code.  Checked
# against Nominatim's reverse lookup in November 2026: rank 12
# at zoom 8 is the county level in the US, UK, Ireland, Germany, France, Italy,
# Pakistan, Mexico, Nigeria, South Africa, Russia, Indonesia and Canada.
# Australia, Brazil and Japan have nothing between their states and their
# towns, so a point there is nowhere.
#
# The other levels are plans: tries => [ { zoom, ranks => [low, high], places } ],
# with plans => { country => [ tries ] } for a country that differs.  places
# lets a try take a place mapped as an area (place=city, town, suburb; a
# relation or a closed way) as well as an administrative boundary.  detail is
# how far Nominatim may move an outline's edge to simplify it, in degrees, as
# text: it is stored with each outline and compared.  name and names are what
# the area is called, as a word a caller can name it by to its readers
# (name_for).  What the reverse lookup gave, November 2026 (zoom: rank, name):
#
#   Toronto         5: 8 Ontario; 8 and 10: 12 Toronto; 12: 18 Toronto Centre
#                   (ward); 14: 20 Financial District
#   Pune            5: 8 Maharashtra; 8: 12 Pune City Subdistrict; 10 and up:
#                   points only
#   Canterbury      8: 12 Kent; 10 and 12: 16 Canterbury (the district)
#   Manchester      8: 10 Greater Manchester; 10: 16 Manchester; 14: 19 City
#                   Centre (place=suburb, a way)
#   Bristol, York   8: 12, the unitary authority; 10: 16 Bristol (place=city, a
#                   relation), York a point
#   Hamilton NZ     5: 8 Waikato; 8, 10 and 12: 12 Hamilton City
#   Auckland        5 and 8: 8 Auckland; 10: 16 Waitemata (a local board)
#   Wellington      8: 12 Wellington City; 10: a point
#   Margate         10: 16 Thanet; 12: 18 Margate (place=town, a relation); 13
#                   and 14: points (Cliftonville, Westbrook, Garlinge)
#   Westgate-on-Sea 14: 20, the civil parish; 12: 18 Birchington, a point
Readonly my %LEVELS => (
	country => {
		name   => 'country',
		detail => '0.02',	# Canada 15 KB, India 29 KB
		tries  => [ { zoom => 3, ranks => [ 4, 4 ] } ],
	},
	state => {
		name   => 'state',
		names  => {
			ca => 'province', cn => 'province', es => 'region', fr => 'region',
			gb => 'country', it => 'region', jp => 'prefecture', nl => 'province',
			nz => 'region', pk => 'province', za => 'province',
		},
		detail => '0.01',	# Ontario 12 KB, Maharashtra 30 KB, England 7 KB
		tries  => [ { zoom => 5, ranks => [ 8, 8 ] } ],
	},
	county => {
		rank      => 12,
		countries => {
			bd => 10,	# district (zila); 12 is an upazila
			cn => 10,	# prefecture-level city; 12 is a district
			es => 10,	# province; Spain has no rank 12
			in => 10,	# district; 12 is a sub-district (tehsil, taluk)
			ke => 8,	# county; 12 is a sub-county
		},
		name  => 'county',
		names => {
			bd => 'district', cn => 'prefecture', de => 'district', es => 'province',
			fr => 'department', in => 'district', it => 'province',
		},
		# About 100 m.  Each outline is simplified alone, so neighbours' shared
		# borders differ by up to this, which shows as gaps and overlaps now
		# that each is drawn on its own side of the border; 0.005 (500 m, 2 KB
		# a county) was 7 pixels out at the zoom a county fills the map, this
		# (7 KB) under 2.
		detail => '0.001',
	},
	city => {
		name   => 'city',
		names  => { gb => 'district', nz => 'district' },
		detail => '0.0005',	# Thanet 4 KB
		tries  => [
			{ zoom => 10, ranks => [ 12, 16 ], places => 1 },
			{ zoom => 8,  ranks => [ 12, 12 ] },
		],
		plans  => {
			nz => [ { zoom => 8, ranks => [ 8, 12 ] } ],
		},
	},
	town => {
		name   => 'town',
		detail => '0.0002',
		tries  => [
			{ zoom => 12, ranks => [ 13, 18 ], places => 1 },
			# A parished English town is its civil parish, rank 20, and zoom
			# 12 there answers with the nearest town mapped as a point.
			{ zoom => 14, ranks => [ 19, 20 ] },
		],
	},
	neighbourhood => {
		name   => 'neighbourhood',
		detail => '0.0002',	# Westgate-on-Sea 1 KB
		tries  => [ { zoom => 14, ranks => [ 17, 20 ], places => 1 } ],
	},
);

# The levels, largest area first: the order a reader chooses from.
Readonly my @LEVEL_ORDER => qw(country state county city town neighbourhood);

# The reverse zoom that asks for each rank.  A zoom names the most detailed
# rank it may return, so a point with no area at that rank comes back as
# something larger (a state), which the rank check turns away rather than
# drawing.
Readonly my %ZOOM_FOR_RANK => (8 => 5, 10 => 6, 12 => 8);

Readonly my $REVERSE_URL    => 'https://nominatim.openstreetmap.org/reverse';
# The detail outlines had before levels did (the county's): an outline at it is
# kept under its plain key, so a cache from 0.023.0 is still read.
Readonly my $PLAIN_DETAIL   => '0.001';
Readonly my $DECIMALS       => 3;	# of a point, in its key and in what is sent
Readonly my $DEFAULT_MAX    => 20;	# Nominatim requests in one call, as map_geocode_online_max
Readonly my $CACHE_DIR      => 'boundary-cache';	# under model_dir, for file_cache()
Readonly my $CACHE_NAMESPACE => __PACKAGE__;
Readonly my $CACHE_MAX_SIZE => 8 * 1024 * 1024;	# bytes, for the process-wide default

my $json = JSON::PP->new->canonical->utf8;

=head1 NAME

Database::BI::Model::Boundary - The outline of the area around each map marker

=head1 VERSION

0.023.1

=head1 SYNOPSIS

    use Database::BI::Model::Boundary;

    my $boundary = Database::BI::Model::Boundary->new(
        cache  => Database::BI::Model::Boundary->file_cache('.bi'),
        online => 1,
        level  => 'state',    # country, state, county (default), city, town, neighbourhood
    );

    my $result = $boundary->outlines([ [ 39.09, -77.64 ], [ 38.85, -77.31 ] ]);
    $map->add_geojson(
        { type => 'FeatureCollection', features => $result->{features} },
        name => 'County boundaries',
    );

    # A point the map page listed as pending, looked up on its own
    my $answer = $boundary->lookup_point($result->{pending}[0]);

=head1 DESCRIPTION

Finds the area each point is in, at one level, and returns its outline as a GeoJSON
Feature, for L<HTML::OSM>'s C<add_geojson>.  The outlines come from
OpenStreetMap's Nominatim reverse lookup, through the same throttled user agent
as the geocoder (L<Database::BI::Model::Geocode/nominatim_ua>), so the two
together never ask more than once a second.

Only the point is sent, rounded to three decimal places (about 110 metres).
Every answer is cached: a point with the outline it is in, and the outline
itself.  A point inside an outline already known is matched here, without a
request, so many points in one county cost one lookup.

The levels, largest first:

=over 4

=item country

=item state

A US or Indian state, a Canadian province, a New Zealand region, England.

=item county

The default; see below.

=item city

A city or the district named after it: Toronto, Manchester, the district of
Canterbury, Hamilton City in New Zealand.  Where OpenStreetMap has no city round a point, or has the city only as a point
(York, Pune), the area at the county's rank there: the unitary authority, the
city district, or the county itself.

=item town

A town or city ward: Margate, Toronto Centre.  An English town that is a civil
parish (Westgate-on-Sea) is that parish.

=item neighbourhood

A neighbourhood, suburb or civil parish that OpenStreetMap has as an area.
Many suburbs are mapped only as a point, and those have no outline.

=back

Larger areas are simplified more, so an outline is a few kilobytes at any
level.

A county here is the division of a country below its states, whose place rank
in Nominatim depends on the country: 12 (a US county or independent city, an
English county, a German Landkreis, a French departement) unless the country is
listed otherwise: 10 for India, Bangladesh, China and Spain (district,
prefecture, province), 8 for Kenya.  C<ranks> adds or changes countries.
Anything else Nominatim answers is taken as "no county here" and remembered as
such.  A country with nothing at its rank (Australia, Brazil, Japan) gets no
outlines.

Each reply names the point's country, so a point is asked at the zoom of the
last country seen, and asked again when its own country wants another rank.
An outline is kept with the rank it was accepted at; when C<ranks> changes, the
points it covered are asked again.

=head1 METHODS

=head2 new

    my $boundary = Database::BI::Model::Boundary->new(%args);

=head3 API SPECIFICATION

=head4 INPUT

  cache      : object with get() and set() (CHI)  optional; default one
               CHI Memory cache for the process
  online     : boolean   optional, default 0: may Nominatim be asked
  online_max : integer   optional, default 20: requests in one outlines() call
  level      : string    optional, default 'county'; one of levels()
  ranks      : hashref   optional: { country code => place rank }, over the
               county level's own list; codes are two letters (any case),
               ranks 8, 10 or 12.  The other levels ignore it
  ua         : object with get()   optional: the user agent to ask with
               (tests); default Geocode::nominatim_ua()

=head4 OUTPUT

A Database::BI::Model::Boundary object.  Croaks on an unknown level, a cache
without get and set, or ranks that are not a hash of two-letter codes to 8, 10
or 12.

=cut

sub new {
	my $class = shift;
	my $raw   = Params::Get::get_params(undef, \@_) // {};

	my $args = validate_strict(
		schema => {
			cache      => { type => 'object',  optional => 1, default => undef },
			online     => { type => 'boolean', optional => 1, default => 0 },
			online_max => { type => 'integer', optional => 1, default => $DEFAULT_MAX, min => 0 },
			level      => { type => 'string',  optional => 1, default => 'county' },
			ua         => { type => 'object',  optional => 1, default => undef, can => 'get' },
			ranks      => { type => 'hashref', optional => 1, default => undef },
		},
		input => $raw,
	);

	my $level = $LEVELS{ $args->{level} }
		or croak "Unknown boundary level '$args->{level}'";
	croak 'The boundary cache needs get() and set()'
		if defined($args->{cache}) && !($args->{cache}->can('get') && $args->{cache}->can('set'));

	return bless {
		%{$args},
		ranks => { %{ $level->{countries} // {} }, %{ $class->check_ranks($args->{ranks} // {}) } },
		cache => $args->{cache} // _default_cache(),
	}, $class;
}

=head2 check_ranks

    my $ranks = Database::BI::Model::Boundary->check_ranks({ LK => 10 });    # { lk => 10 }

=head3 API SPECIFICATION

=head4 INPUT

  ranks : hashref of { country code => place rank }

=head4 OUTPUT

A new hashref with the codes in lower case and the ranks as numbers.  Croaks
on a value that is not a hashref, a key that is not a two-letter code, or a
rank that is not 8, 10 or 12, naming the entry.  Used by C<new> and by the
application's startup check of C<map_bounds_ranks>.

=cut

sub check_ranks {
	my (undef, $ranks) = @_;
	croak 'Boundary ranks must be a hash of country codes to place ranks'
		unless ref($ranks) eq 'HASH';
	my %checked;
	for my $code (sort keys %{$ranks}) {
		my $rank = $ranks->{$code};
		croak "'$code' is not a two-letter country code" unless $code =~ /\A[A-Za-z]{2}\z/;
		croak "the rank for '$code' must be one of " . join(', ', sort { $a <=> $b } keys %ZOOM_FOR_RANK)
			unless defined($rank) && !ref($rank) && $rank =~ /\A\d+\z/ && $ZOOM_FOR_RANK{$rank};
		croak "'$code' is given twice" if exists $checked{ lc $code };
		$checked{ lc $code } = $rank + 0;
	}
	return \%checked;
}

=head2 rank_for

    my $rank = $boundary->rank_for('in');    # 10

=head3 API SPECIFICATION

=head4 INPUT

  country : string, an ISO 3166-1 alpha-2 code in any case; undef or ''
            for a point in no country (the sea)

=head4 OUTPUT

The place rank an outline in that country must have at the county level: the
country's own, from C<ranks> or the built-in list, else 12.  At another level,
the most detailed rank its first try takes there.

=cut

sub rank_for {
	my ($self, $country) = @_;
	my $level = $LEVELS{ $self->{level} };
	return $self->_plan($country)->[0]{ranks}[1] unless defined $level->{rank};
	my $rank = (defined($country) && !ref($country) && length($country))
		? $self->{ranks}{ lc $country } : undef;
	return $rank // $level->{rank};
}

=head2 name_for

    my $word = $boundary->name_for('in');    # 'district'

What this object's level is called in a country, so a caller can say
"district" on a map of India rather than "county".

=head3 API SPECIFICATION

=head4 INPUT

  country : string, an ISO 3166-1 alpha-2 code in any case; undef or ''
            for a point in no country

=head4 OUTPUT

One lower-case English word: C<country>, C<state>, C<region>, C<province>,
C<prefecture>, C<county>, C<district>, C<department>, C<city>, C<town> or
C<neighbourhood>.  A country not listed gets the level's own name
(L</level_name>).  It is a word to look a translation up by, not text to show.
Called on the class, it answers for the county level.

=cut

sub name_for {
	my ($self, $country) = @_;
	my $level = $LEVELS{ ref($self) ? $self->{level} : 'county' };
	my $name  = (defined($country) && !ref($country) && length($country))
		? ($level->{names} // {})->{ lc $country } : undef;
	return $name // $level->{name};
}

=head2 level_name

    my $word = Database::BI::Model::Boundary->level_name('state');    # 'state'

=head3 API SPECIFICATION

=head4 INPUT

  level : string, one of levels()

=head4 OUTPUT

What the level's areas are called where no country says otherwise, as
L</name_for> gives it: the word to use before a point's country is known.
Undef for a level that is not one.

=cut

sub level_name {
	my (undef, $level) = @_;
	return unless defined($level) && !ref($level) && $LEVELS{$level};
	return $LEVELS{$level}{name};
}

=head2 levels

    my @levels = Database::BI::Model::Boundary->levels;
    # ('country', 'state', 'county', 'city', 'town', 'neighbourhood')

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

The names of the levels new() takes, the largest area first.

=cut

sub levels {
	return @LEVEL_ORDER;
}

=head2 point_key

    my $key = Database::BI::Model::Boundary->point_key(39.0901, -77.6402);    # '39.090,-77.640'

=head3 API SPECIFICATION

=head4 INPUT

  lat : number  -90 .. 90
  lon : number  -180 .. 180

=head4 OUTPUT

The point rounded to three decimal places, as C<"lat,lon">: what the cache is
keyed by and all of the point that is sent.  Undef for a point out of range.

=cut

sub point_key {
	my (undef, $lat, $lon) = @_;

	return unless defined($lat) && defined($lon)
		&& $lat =~ /\A-?\d+(?:\.\d+)?\z/ && $lon =~ /\A-?\d+(?:\.\d+)?\z/
		&& abs($lat) <= 90 && abs($lon) <= 180;

	my @parts = map {
		my $text = sprintf("%.${DECIMALS}f", $_);
		$text =~ s/\A-(?=0\.0+\z)//;	# no "-0.000", so a point has one key
		$text;
	} ($lat, $lon);
	return join(',', @parts);
}

=head2 outlines

    my $result = $boundary->outlines(\@points, lookup => 1);

=head3 API SPECIFICATION

=head4 INPUT

  points : arrayref of [lat, lon]
  lookup : boolean, default 1.  0 asks Nominatim nothing: the points not
           known yet come back in pending, for the caller to look up one at
           a time (lookup_point)

=head4 OUTPUT

  {
    features => [ GeoJSON Feature, ... ]   one per outline, in the order
                 their first point came; properties { name, osm, called }
                 (called: what the division is called there, as name_for)
    pending  => [ point_key, ... ]         points not known, not asked
    inside   => { point_key => osm, ... }  the outline each point drawn is in,
                 by the osm of its Feature (to total what is in each)
    counts   => { points, drawn, attempted, nowhere }
    offline  => 0|1   points were left because Nominatim may not be asked
    failed   => 0|1   Nominatim did not answer; the rest were left
  }

A point out of range is ignored.  A Feature's name is the place's name as
OpenStreetMap has it: text, not HTML.

=cut

sub outlines {
	my ($self, $points, @rest) = @_;
	croak 'outlines() needs an arrayref of [lat, lon]' unless ref($points) eq 'ARRAY';
	my %opt = @rest;
	my $lookup = exists($opt{lookup}) ? $opt{lookup} : 1;

	local ($@, $!);

	my (@keys, %seen);
	for my $point (@{$points}) {
		next unless ref($point) eq 'ARRAY';
		my $key = $self->point_key(@{$point}[0, 1]);
		push @keys, $key if defined($key) && !$seen{$key}++;
	}

	my %counts = (points => scalar(@keys), drawn => 0, attempted => 0, nowhere => 0);
	my (@order, %used, %inside, @pending, $failed, $offline);
	my $index = $self->_index;

	for my $key (@keys) {
		my ($osm, $status) = $self->_known($key, $index);
		if (!defined($status) && $lookup) {
			if (!$self->_can_ask) {
				$offline = 1;
			} elsif (!$failed && $counts{attempted} < $self->{online_max}) {
				$counts{attempted}++;
				($osm, $status) = $self->_ask($key, $index);
				$failed = 1 if $status eq 'failed';
			}
		}
		if (!defined($status) || $status eq 'failed') {
			push @pending, $key;
			next;
		}
		if ($status eq 'nowhere') {
			$counts{nowhere}++;
			next;
		}
		push @order, $osm unless $used{$osm}++;
		$inside{$key} = $osm;
	}

	my @features;
	for my $osm (@order) {
		my $outline = $self->_get($self->_outline_key($osm)) or next;
		push @features, {
			type       => 'Feature',
			properties => { name => $outline->{name}, osm => $osm,
				called => $self->name_for($outline->{country}) },
			geometry   => $outline->{geometry},
		};
	}
	$counts{drawn} = scalar @features;
	my %drawn = map { $_->{properties}{osm} => 1 } @features;
	delete @inside{ grep { !$drawn{ $inside{$_} } } keys %inside };

	return {
		features => \@features,
		pending  => \@pending,
		inside   => \%inside,
		counts   => \%counts,
		offline  => $offline ? 1 : 0,
		failed   => $failed  ? 1 : 0,
	};
}

=head2 lookup_point

    my $answer = $boundary->lookup_point('39.090,-77.640');

=head3 API SPECIFICATION

=head4 INPUT

  key : string, a point_key

=head4 OUTPUT

  { status => 'found' | 'nowhere' | 'held', name => string|undef, asked => 0|1 }

'found' and 'nowhere' are remembered.  'held' is a point that could not be
settled now - Nominatim did not answer, or may not be asked - and is asked
again next time.  asked says whether Nominatim was asked.  Croaks on a key
that is not a point_key.

=cut

sub lookup_point {
	my ($self, $key) = @_;

	croak 'lookup_point() needs a point key such as 39.090,-77.640'
		unless defined($key) && !ref($key)
		&& $key =~ /\A(-?\d{1,2}\.\d{$DECIMALS}),(-?\d{1,3}\.\d{$DECIMALS})\z/
		&& defined($self->point_key($1, $2)) && $self->point_key($1, $2) eq $key;

	local ($@, $!);

	my $index = $self->_index;
	my ($osm, $status) = $self->_known($key, $index);
	my $asked = 0;
	if (!defined($status) && $self->_can_ask) {
		$asked = 1;
		($osm, $status) = $self->_ask($key, $index);
	}

	return { status => 'held', name => undef, asked => $asked }
		if !defined($status) || $status eq 'failed';
	return { status => 'nowhere', name => undef, asked => $asked } if $status eq 'nowhere';

	my $outline = $self->_get($self->_outline_key($osm));
	return { status => 'found', name => ($outline ? $outline->{name} : undef), asked => $asked };
}

=head2 file_cache

    my $cache = Database::BI::Model::Boundary->file_cache($model_dir);

=head3 API SPECIFICATION

=head4 INPUT

  dir : string, an existing directory (model_dir)

=head4 OUTPUT

A CHI File cache under C<< <dir>/boundary-cache >>, with a copy of what it
reads in memory for as long as the cache object lives.  Croaks when dir is not a directory.

=cut

sub file_cache {
	my (undef, $dir) = @_;

	croak 'The boundary cache needs a directory, not ' . (defined($dir) ? $dir : 'undef')
		unless defined($dir) && !ref($dir) && -d $dir;

	require CHI;
	require File::Spec;
	return CHI->new(
		driver    => 'File',
		root_dir  => File::Spec->catdir($dir, $CACHE_DIR),
		namespace => $CACHE_NAMESPACE,
		# A copy in memory for this object, which a request makes afresh: it
		# saves reading the index and outlines again within the request.  Not
		# global, which would share it with every cache of this namespace in
		# the process, whatever its folder, and keep a worker from seeing
		# what another has added since.
		l1_cache  => { driver => 'RawMemory', global => 0, max_size => $CACHE_MAX_SIZE },
	);
}

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

my $default_cache;

sub _default_cache {
	require CHI;
	$default_cache //= CHI->new(
		driver    => 'Memory',
		global    => 1,
		namespace => $CACHE_NAMESPACE,
		max_size  => $CACHE_MAX_SIZE,
	);
	return $default_cache;
}

# _get($key) / _set($key, $value): the cache, under this level's prefix for a
# point and under _outline_key for an outline.  A cache that fails reads as empty and writes as nothing: the page
# still draws, and asks again next time.
sub _get {
	my ($self, $key) = @_;
	my $value = eval { $self->{cache}->get($key) };
	return $value;
}

sub _set {
	my ($self, $key, $value) = @_;
	return eval { $self->{cache}->set($key, $value, 'never'); 1 };
}

sub _point_cache_key {
	my ($self, $key) = @_;
	return "point:$self->{level}:$key";
}

# _detail() -> how far this level's outlines are simplified, as text
sub _detail {
	my $self = shift;
	return $LEVELS{ $self->{level} }{detail};
}

# _outline_key($osm) -> the cache key of an outline at this level's detail.
# One relation is one outline at every level of the same detail, and a copy
# apiece where they differ, so two levels never fetch over each other's.
sub _outline_key {
	my ($self, $osm) = @_;
	my $detail = $self->_detail;
	return $detail eq $PLAIN_DETAIL ? "outline:$osm" : "outline:$osm:$detail";
}

# _plan($country) -> arrayref of tries { zoom, ranks => [low, high], places }
#
# How this level is asked for in a country (undef or '' for none known): the
# county level's one rank at the zoom that asks for it, else the level's
# tries, or the country's own.
sub _plan {
	my ($self, $country) = @_;
	my $level = $LEVELS{ $self->{level} };
	$country = (defined($country) && !ref($country)) ? lc($country) : '';
	if (defined $level->{rank}) {
		my $rank = $self->{ranks}{$country} // $level->{rank};
		return [ { zoom => $ZOOM_FOR_RANK{$rank}, ranks => [ $rank, $rank ] } ];
	}
	return ($level->{plans} // {})->{$country} // $level->{tries};
}

# _plan_sig(\@plan) -> the plan as text, kept with a point found nowhere so a
# changed plan asks again.
sub _plan_sig {
	my $plan = shift;
	return join(';', map { "$_->{zoom}:$_->{ranks}[0]-$_->{ranks}[1]" . ($_->{places} ? ':p' : '') } @{$plan});
}

# _accepts(\@plan, $rank) -> 1 when some try of the plan takes that rank
sub _accepts {
	my ($plan, $rank) = @_;
	return (first { $rank >= $_->{ranks}[0] && $rank <= $_->{ranks}[1] } @{$plan}) ? 1 : 0;
}

# _index() -> arrayref of [osm, south, west, north, east]
#
# The bounding box of every outline this level has found, so a point can be
# tested against the few that could hold it.  Two processes adding at once can
# lose one's entry; that costs a request later, not a wrong answer.
sub _index {
	my $self = shift;
	my $index = $self->_get("index:$self->{level}");
	return ref($index) eq 'ARRAY' ? [ @{$index} ] : [];
}

# _known($key, \@index) -> ($osm, $status) or ()
#
# What is known of a point without asking: remembered with an outline or with
# none, or inside an outline the index holds (which is then remembered).
sub _known {
	my ($self, $key, $index) = @_;

	my $remembered = $self->_get($self->_point_cache_key($key));
	if (ref($remembered) eq 'HASH') {
		# Nowhere, by the plan its country had then.  0.023.0 kept the rank
		# alone, which names a county plan.
		my $sig = $remembered->{plan};
		$sig //= "$ZOOM_FOR_RANK{ $remembered->{rank} }:$remembered->{rank}-$remembered->{rank}"
			if defined($remembered->{rank}) && $ZOOM_FOR_RANK{ $remembered->{rank} };
		return (undef, 'nowhere')
			if defined($sig) && $sig eq _plan_sig($self->_plan($remembered->{country}));
	} elsif (defined($remembered) && length($remembered)) {
		return ($remembered, 'found') if $self->_current($self->_get($self->_outline_key($remembered)));
		# The outline has gone from the cache, or its country's rank changed.
	}
	# '' is nowhere from before ranks were kept: ask again.

	my ($lat, $lon) = split /,/, $key;
	for my $entry (@{$index}) {
		my ($osm, $south, $west, $north, $east) = @{$entry};
		next if $lat < $south || $lat > $north || $lon < $west || $lon > $east;
		my $outline = $self->_get($self->_outline_key($osm));
		next unless $self->_current($outline) && _contains($outline->{geometry}, $lat, $lon);
		$self->_set($self->_point_cache_key($key), $osm);
		return ($osm, 'found');
	}

	return;
}

# _current($outline) -> 1 when an outline was accepted at the rank its country
# wants now, and simplified as outlines are now.  One kept before ranks were
# (no rank), or at another level of detail, is not.
sub _current {
	my ($self, $outline) = @_;
	return 0 unless ref($outline) eq 'HASH' && defined($outline->{rank});
	return 0 unless ($outline->{detail} // '') eq $self->_detail;
	return _accepts($self->_plan($outline->{country}), $outline->{rank});
}

# _last_country() / _last_country($code): the country of the last reply at
# this level, whose rank the next point is asked at first.  Kept in the cache,
# so the first point of a later map is not asked twice.
sub _last_country {
	my ($self, @set) = @_;
	my $key = "country:$self->{level}";
	if (@set) {
		$self->{last_country} = $set[0];
		$self->_set($key, $set[0]) unless ($self->_get($key) // '') eq $set[0];
		return $set[0];
	}
	return $self->{last_country} //= $self->_get($key) // '';
}

sub _can_ask {
	my $self = shift;
	return 0 unless $self->{online};
	return 1 if $self->{ua};
	require Database::BI::Model::Geocode;
	return Database::BI::Model::Geocode::nominatim_ua() ? 1 : 0;
}

# _ask($key, \@index) -> ($osm, 'found') | (undef, 'nowhere') | (undef, 'failed')
#
# Reverse lookups down a plan.  The first is the first try of the plan of the
# last country seen; its reply names the point's country, whose plan is then
# followed from its start (a try at a zoom already asked uses that reply), to
# the first try that gives an outline.  A found outline is remembered with its
# country and rank, added to the index (and to @$index, so the caller's later
# points are tested against it), and the point remembered with it.  A point no
# try gives an outline for is remembered as nowhere, with its country and the
# plan.  A failure is remembered as nothing.
sub _ask {
	my ($self, $key, $index) = @_;
	my ($lat, $lon) = split /,/, $key;

	my %replies;	# by zoom
	my $reverse = sub {
		my $zoom = shift;
		return $replies{$zoom} //= $self->_reverse($lat, $lon, $zoom);
	};

	my $plan  = $self->_plan($self->_last_country);
	my $first = $reverse->($plan->[0]{zoom}) or return (undef, 'failed');

	my $country = ref($first->{address}) eq 'HASH' ? $first->{address}{country_code} : undef;
	$country = (defined($country) && !ref($country) && $country =~ /\A[A-Za-z]{2}\z/) ? lc($country) : '';
	if (length $country) {
		$self->_last_country($country);
		$plan = $self->_plan($country);
	}

	my ($reply, $osm);
	# "Unable to geocode" is the sea at any zoom: no try will do better.
	for my $try (defined($first->{error}) ? () : @{$plan}) {
		my $answer = $reverse->($try->{zoom}) or return (undef, 'failed');
		$osm = _outline_id($answer, $try) // next;
		$reply = $answer;
		last;
	}

	unless ($reply) {
		# The sea, and answers at other ranks or with no shape, alike.  rank is
		# what 0.023.0 kept, and reads back as the same county plan.
		$self->_set($self->_point_cache_key($key),
			{ country => $country, rank => $plan->[0]{ranks}[1], plan => _plan_sig($plan) });
		return (undef, 'nowhere');
	}

	my $geometry = $reply->{geojson};
	my $name = $reply->{name};
	$name = $reply->{display_name} unless defined($name) && length($name);
	$self->_set($self->_outline_key($osm), {
		name     => $name // $osm,
		geometry => $geometry,
		country  => $country,
		rank     => $reply->{place_rank} + 0,
		detail   => $self->_detail,
	});

	unless (grep { $_->[0] eq $osm } @{$index}) {
		my $box = _bounds($geometry);
		if ($box) {
			push @{$index}, [ $osm, @{$box} ];
			my $stored = $self->_index;
			push @{$stored}, [ $osm, @{$box} ] unless grep { $_->[0] eq $osm } @{$stored};
			$self->_set("index:$self->{level}", $stored);
		}
	}
	$self->_set($self->_point_cache_key($key), $osm);

	return ($osm, 'found');
}

# _outline_id($reply, $try) -> 'R<id>' or 'W<id>' when the reply is an outline
# the try takes, else undef.
#
# An outline is an area with a shape, at a rank in the try's range: an
# administrative boundary's relation, or, for a try that takes places, a place
# mapped as an area (place=city, town, suburb), which may be a closed way.  A
# place mapped as a point has no shape and is not one.
sub _outline_id {
	my ($reply, $try) = @_;

	my $geometry = $reply->{geojson};
	my $rank     = $reply->{place_rank};
	my $category = $reply->{category} // '';
	my $osm_type = $reply->{osm_type} // '';
	return unless defined($reply->{osm_id}) && $reply->{osm_id} =~ /\A\d+\z/
		&& defined($rank) && !ref($rank) && $rank =~ /\A\d+\z/
		&& $rank >= $try->{ranks}[0] && $rank <= $try->{ranks}[1]
		&& ref($geometry) eq 'HASH'
		&& ($geometry->{type} // '') =~ /\A(?:Multi)?Polygon\z/
		&& ref($geometry->{coordinates}) eq 'ARRAY';

	my $boundary = $category eq 'boundary' && ($reply->{type} // '') eq 'administrative'
		&& $osm_type eq 'relation';
	my $place = $try->{places} && $category eq 'place' && ($osm_type eq 'relation' || $osm_type eq 'way');
	return unless $boundary || $place;

	return ($osm_type eq 'way' ? 'W' : 'R') . $reply->{osm_id};
}

# _reverse($lat, $lon, $zoom) -> the decoded reply, or undef when Nominatim
# did not answer with JSON.
sub _reverse {
	my ($self, $lat, $lon, $zoom) = @_;

	my $uri = URI->new($REVERSE_URL);
	$uri->query_form(
		lat               => $lat,
		lon               => $lon,
		zoom              => $zoom,
		format            => 'jsonv2',
		polygon_geojson   => 1,
		polygon_threshold => $self->_detail,
		'accept-language' => 'en',
	);

	require Database::BI::Model::Geocode;
	my $ua  = $self->{ua} // Database::BI::Model::Geocode::nominatim_ua();
	my $res = eval { $ua->get($uri) };
	return unless blessed($res) && $res->can('is_success') && $res->is_success;

	my $reply = eval { $json->decode($res->decoded_content // '') };
	return ref($reply) eq 'HASH' ? $reply : undef;
}

# _polygons($geometry) -> list of polygons, each an arrayref of rings, each
# ring an arrayref of [lon, lat].
sub _polygons {
	my $geometry = shift;
	return () unless ref($geometry) eq 'HASH' && ref($geometry->{coordinates}) eq 'ARRAY';
	return ($geometry->{coordinates}) if ($geometry->{type} // '') eq 'Polygon';
	return @{ $geometry->{coordinates} } if ($geometry->{type} // '') eq 'MultiPolygon';
	return ();
}

# _bounds($geometry) -> [south, west, north, east], or undef with no points
sub _bounds {
	my $geometry = shift;
	my ($south, $west, $north, $east);
	for my $polygon (_polygons($geometry)) {
		for my $position (@{ $polygon->[0] // [] }) {
			my ($lon, $lat) = @{$position};
			$south = $lat if !defined($south) || $lat < $south;
			$north = $lat if !defined($north) || $lat > $north;
			$west  = $lon if !defined($west)  || $lon < $west;
			$east  = $lon if !defined($east)  || $lon > $east;
		}
	}
	return defined($south) ? [ $south, $west, $north, $east ] : undef;
}

# _contains($geometry, $lat, $lon) -> 1 when the point is inside a polygon's
# outer ring and none of its holes (Fairfax County's hole is the City of
# Fairfax).  Even-odd ray casting, with longitude as x.
sub _contains {
	my ($geometry, $lat, $lon) = @_;
	for my $polygon (_polygons($geometry)) {
		my ($outer, @holes) = @{$polygon};
		next unless _in_ring($outer, $lon, $lat);
		return 1 unless grep { _in_ring($_, $lon, $lat) } @holes;
	}
	return 0;
}

sub _in_ring {
	my ($ring, $x, $y) = @_;
	return 0 unless ref($ring) eq 'ARRAY' && @{$ring} >= 3;
	my $inside = 0;
	my ($px, $py) = @{ $ring->[-1] };
	for my $position (@{$ring}) {
		my ($qx, $qy) = @{$position};
		if ((($qy > $y) != ($py > $y))
				&& ($x < ($px - $qx) * ($y - $qy) / ($py - $qy) + $qx)) {
			$inside = !$inside;
		}
		($px, $py) = ($qx, $qy);
	}
	return $inside ? 1 : 0;
}

1;

__END__

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
