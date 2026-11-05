package BI::Test::Nominatim;

# A Geo::Coder::Free and a Nominatim that are not real, for the geocoding chain.
#
# Database::BI::Model::Geocode builds a Geo::Coder::List of Geo::Coder::Free
# and then Geo::Coder::OSM.  A test of that chain must not depend on what the
# machine's catalogues happen to know, and must never send a place to
# nominatim.openstreetmap.org.  with_chain() runs a block with both replaced:
#
#   * Geo::Coder::Free->new answers a stand-in whose valid_location(),
#     geocode() and geocode_many() read %local;
#   * LWP::UserAgent::get answers every request the way Nominatim would,
#     from %online, and records it.  Geo::Coder::OSM makes its requests with
#     get(), and LWP::UserAgent::Throttled inherits get() and throttles in
#     send_request(), which the stand-in never reaches: no request waits.
#
# The real Geo::Coder::List, Geo::Coder::OSM and LWP::UserAgent::Throttled are
# used, so the caller checks they are installed (see the floors below).
#
#   %local:  place => [lat, lon]   found in the local data
#            place => 'die'        the local geocoder throws
#   %online: place => [lat, lon]   Nominatim finds it ("51.33" strings, as it does)
#            place => 'none'       Nominatim answers 200 with no match
#            place => 503          Nominatim answers with that status
#            anything not listed   200 with no match
#
# Modules named in hide are made to look uninstalled for the block.

use strict;
use warnings;

use Exporter     qw(import);
use Geo::Location::Point ();
use HTTP::Response ();
use Mojo::JSON   qw(encode_json);
use URI          ();

our @EXPORT_OK = qw(with_chain $LIST_FLOOR $OSM_FLOOR $THROTTLED_FLOOR);

# The floors Database::BI::Model::Geocode asks for.  A test that skips names
# them, as t/recommended-versions.t requires.
our $LIST_FLOOR      = '0.39';
our $OSM_FLOOR       = '0.03';
our $THROTTLED_FLOOR = '0.14';

{
	package BI::Test::Nominatim::Local;

	sub new { my ($class, %a) = @_; return bless { %a, calls => [], regions => [] }, $class }

	sub valid_location {
		my ($self, $v) = @_;
		return 0 unless defined($v) && !ref($v) && length($v);
		return $v =~ /\A\d+\z/ ? 0 : 1;
	}

	sub _answer {
		my ($self, $v) = @_;
		push @{ $self->{calls} }, $v;
		my $known = $self->{places}{$v};
		die "local geocoder failed\n" if defined($known) && !ref($known) && $known eq 'die';
		return unless ref($known) eq 'ARRAY';

		# What the real one answers with, which Geo::Coder::List reads in its
		# own way: a plain hash of latitude and longitude is not the same test.
		# It needs its address too: a point without one prints as '', which
		# Geo::Coder::List takes for no answer and asks the next geocoder.
		return Geo::Location::Point->new(
			lat => $known->[0], long => $known->[1], location => $v, database => 'Fake',
		);
	}

	# Geo::Coder::List asks with geocode(location => $place).
	sub geocode {
		my ($self, %a) = @_;
		push @{ $self->{regions} }, $a{region};
		return $self->_answer($a{location});
	}

	sub geocode_many {
		my ($self, $values, %a) = @_;
		my %out = (lookups => scalar @{$values});
		$out{$_} = $self->_answer($_) for @{$values};
		return \%out;
	}

	sub ua { return }
}

# with_chain(local => \%local, online => \%online, hide => [modules], $code)
#     -> \%seen, after running $code->(\%seen)
#
# %seen holds requests (each { place, host, agent, uri }) and local (the
# stand-in Geo::Coder::Free, whose calls say what the local data was asked,
# and regions the region hint each geocode() was given).
sub with_chain {
	my $code = pop;
	my %arg  = @_;

	my $online = $arg{online} // {};
	my $local  = BI::Test::Nominatim::Local->new(places => $arg{local} // {});
	my %seen   = (requests => [], local => $local);

	my %hidden = map { (join('/', split /::/) . '.pm') => 1 } @{ $arg{hide} // [] };
	my $hook   = sub {
		my (undef, $file) = @_;
		die "Can't locate $file in \@INC (hidden by BI::Test::Nominatim)\n" if $hidden{$file};
		return;
	};

	no warnings qw(redefine once);
	local @INC = ($hook, @INC);
	delete local @INC{ keys %hidden } if %hidden;
	local $INC{'Geo/Coder/Free.pm'} = __FILE__;
	local $Geo::Coder::Free::VERSION = '99';
	local *Geo::Coder::Free::new = sub { return $local };

	require LWP::UserAgent;
	local *LWP::UserAgent::get = sub {
		my ($ua, $uri) = @_;
		$uri = URI->new("$uri");
		my %query = $uri->query_form;
		my $place = $query{q};
		utf8::decode($place) if defined $place;

		push @{ $seen{requests} }, {
			place => $place,
			host  => $uri->host,
			agent => $ua->agent,
			uri   => "$uri",
		};

		my $answer = defined($place) ? $online->{$place} : undef;
		if (defined($answer) && !ref($answer) && $answer =~ /\A\d{3}\z/) {
			return HTTP::Response->new($answer, 'Stand-in failure', [ 'Content-Type' => 'text/plain' ], 'failed');
		}

		my $body = ref($answer) eq 'ARRAY'
			? encode_json([ { lat => "$answer->[0]", lon => "$answer->[1]", display_name => $place } ])
			: '[]';
		return HTTP::Response->new(200, 'OK', [ 'Content-Type' => 'application/json' ], $body);
	};

	# Geo::Coder::List's process-wide default cache would carry a place found
	# in one block into the next, where it would be answered without asking
	# anyone.  Each block starts with it empty.
	require Database::BI::Model::Geocode;
	Database::BI::Model::Geocode::_default_cache()->clear();

	$code->(\%seen);

	return \%seen;
}

1;
