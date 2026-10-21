#!/usr/bin/env perl

# Phase 6.2 of BI-Phase6.md: a location column is geocoded once per distinct
# value, with the dirty values in it skipped rather than fatal.
#
# The geocoder is a stub here, so the test needs no geocoder, no data and no
# network, and it can watch what the module asked: valid_location() for every
# distinct non-empty value, one geocode_many() per call, and - the point of the
# whole exercise - never a bare number, a blank cell or a reference.  A real
# Geo::Coder::Free is exercised separately in t/geocode-real.t.
#
#   prove -l t/geocode.t

use strict;
use warnings;

use Test::Most;
use Test::Without::Module;	# the "geocoder is not installed" path
use Database::BI::Model::Geocode;

# ---------------------------------------------------------------------------
# A stub geocoder: the two methods the module asks of one, recording everything
# it is asked, answering from a table of results, and refusing to be asked about
# the values section 6.2 says must never reach a backend.
# ---------------------------------------------------------------------------

{
	package Stub::Point;

	# A result shaped like a Geo::Location::Point: read through its accessors.
	sub new {
		my ($class, %args) = @_;
		return bless { %args }, $class;
	}
	sub latitude  { $_[0]{'latitude'} }
	sub longitude { $_[0]{'longitude'} }
	sub database  { $_[0]{'database'} }

	package Stub::Geocoder;

	sub new {
		my ($class, %args) = @_;
		return bless {
			'results' => $args{'results'} // {},
			'bomb'    => $args{'bomb'}    // {},	# value => die, a backend that breaks
			'asked'   => [],
			'calls'   => [],
		}, $class;
	}

	sub valid_location {
		my ($self, $value) = @_;
		push @{ $self->{'asked'} }, $value;

		return 0 unless defined($value) && !ref($value) && length($value);
		return ($value =~ /\D/) ? 1 : 0;
	}

	sub geocode_many {
		my ($self, $values, %opts) = @_;

		push @{ $self->{'calls'} }, { 'values' => [ @{ $values } ], 'opts' => { %opts } };

		for my $value (@{ $values }) {
			# A backend that dies on a value it should never have been asked
			# about, and one that dies for its own reasons: neither may be
			# swallowed by the caller.
			die "the backend was asked about '$value'\n" if $self->{'bomb'}{$value};
		}

		my %result = ('lookups' => scalar @{ $values }, 'resolved' => 0, 'unresolved' => 0, 'unresolved_values' => []);

		for my $value (@{ $values }) {
			my $point = $self->{'results'}{$value};

			$result{$value} = $point;
			if (defined($point)) {
				$result{'resolved'}++;
			} else {
				$result{'unresolved'}++;
				push @{ $result{'unresolved_values'} }, $value;
			}
		}

		return \%result;
	}
}

# The two places the stub knows, in the two result shapes a geocoder can give:
# an object read through latitude()/longitude(), and a plain hashref.
sub stub {
	my (%args) = @_;

	return Stub::Geocoder->new(
		results => {
			'Ramsgate, Kent' => Stub::Point->new(
				longitude => 1.43333, latitude => 51.33333, database => 'OpenAddresses',
			),
			'Sittingbourne' => { 'lat' => 51.33333, 'long' => 0.75, 'database' => 'MaxMind' },
			%{ $args{'results'} // {} },
		},
		%args,
	);
}

# A column with the things a real place column holds: places, a repeated place,
# a bare number in the wrong column, a shorter bare number, a blank cell, a
# missing cell, and a cell that is not a string at all.
sub dirty_column {
	my $not_a_place = { 'lat' => 'not', 'a' => 'place' };

	return [
		{ 'place' => 'Ramsgate, Kent' },
		{ 'place' => 'Sittingbourne' },
		{ 'place' => 'Ramsgate, Kent' },
		{ 'place' => '0044' },
		{ 'place' => '12' },
		{ 'place' => 'Ramsgate, Kent' },
		{ 'place' => '' },
		{ 'place' => undef },
		{ 'place' => $not_a_place },
		{ 'place' => 'Ramsgate, Kent' },
		{ 'place' => 'Ramsgate, Kent' },
		{ 'place' => 'Ramsgate, Kent' },
	];
}

# ---------------------------------------------------------------------------

subtest 'a dirty column is skipped end to end' => sub {
	my $geocoder = stub();
	# openaddr suppresses warn_map_geocoder_unavailable_data, which fires when
	# OPENADDR_HOME is not set in the environment (common in CI); the stub
	# geocoder ignores the path, so any truthy string is fine here.
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder, openaddr => 'test');

	my $cache  = {};
	my $result = $geocode->resolve_column(dirty_column(), 'place', cache => $cache, region => 'GB');

	is_deeply($result->{'counts'}, {
		'rows'          => 12,
		'plotted'       => 7,
		'unusable'      => 5,
		'distinct'      => 5,
		'skipped'       => 3,
		'cached'        => 0,
		'attempted'     => 2,
		'lookups'       => 2,
		'resolved'      => 2,
		'unresolved'    => 0,
		'not_attempted' => 0,
	}, 'the counts of a column holding six places, two bare numbers, a blank cell, a missing cell and a reference')
		or diag(explain($result->{'counts'}));

	is_deeply([ map { $_->{'key'} } @{ $result->{'messages'} } ],
		['warn_map_rows_skipped'],
		'and the page is told that some rows could not be plotted');

	like($result->{'messages'}[0]{'text'}, qr/Plotted 7 of 12 rows; 5 hold no location/,
		'with the numbers in the message');

	# The crux: nothing that is not a location reached the geocoder.  One batch,
	# two values, and the non-croaking mode.
	is(scalar @{ $geocoder->{'calls'} }, 1, 'the column was one batch');
	is_deeply($geocoder->{'calls'}[0]{'values'}, ['Ramsgate, Kent', 'Sittingbourne'],
		'holding the two distinct locations, and neither of the bare numbers')
		or diag(explain($geocoder->{'calls'}[0]{'values'}));
	is($geocoder->{'calls'}[0]{'opts'}{'on_error'}, 'undef',
		'and made with on_error => undef, so a value refused later is a miss rather than a death');
	is($geocoder->{'calls'}[0]{'opts'}{'region'}, 'GB', 'the region hint goes through');

	# What the renderer gets: one marker per place, in first-seen order, with the
	# row count an aggregated popup needs.
	is_deeply([ map { [ $_->{'value'}, $_->{'rows'}, $_->{'first_row'} ] } @{ $result->{'markers'} } ],
		[ [ 'Ramsgate, Kent', 6, 0 ], [ 'Sittingbourne', 1, 1 ] ],
		'markers in first-seen order, each knowing how many rows it stands for');

	is($result->{'markers'}[0]{'lat'}, 51.33333, 'read from the object result through its accessors');
	is($result->{'markers'}[1]{'lon'}, 0.75, "read from the hashref result through its 'long' key");
	is($result->{'backend'}, 'MaxMind, OpenAddresses', 'and the backends that answered are named');
	is_deeply($result->{'backends'}, { 'MaxMind' => 1, 'OpenAddresses' => 1 }, 'with their counts');

	# The cache is the section 6.3 shape: coordinates for what resolved, and no
	# entry at all for what was never a location.
	is_deeply($result->{'cache'}{'Ramsgate, Kent'}, [ 51.33333, 1.43333 ], 'a resolved place is remembered as [lat, lon]');
	is($result->{'cache'}{'Sittingbourne'}[1], 0.75, 'whatever spelling the result used');
	ok(!exists $result->{'cache'}{'0044'}, 'a bare number is not remembered: it was never looked up');
	ok(!exists $result->{'cache'}{''}, 'and neither is a blank cell');
	is_deeply($cache, {}, "the caller's cache hashref was not modified");
};

subtest 'the rule is asked of the geocoder, once per distinct non-empty value' => sub {
	my $geocoder = stub();
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder);

	$geocode->resolve_column(dirty_column(), 'place');

	is_deeply($geocoder->{'asked'}, [ 'Ramsgate, Kent', 'Sittingbourne', '0044', '12' ],
		'the rule saw the distinct values, in first-seen order, however often the column repeats one')
		or diag(explain($geocoder->{'asked'}));

	ok(!grep { !defined($_) || !length($_) || ref($_) } @{ $geocoder->{'asked'} },
		'a blank cell, a missing cell and a reference are refused without asking the rule');
};

subtest 'one lookup per distinct value, however often the column repeats' => sub {
	my $geocoder = stub();
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder);

	my @rows = (
		(map { { 'place' => 'Ramsgate, Kent' } } 1 .. 397),
		{ 'place' => 'Sittingbourne' }, { 'place' => '0044' }, { 'place' => 'Nowhere, Imaginary, ZZ' },
	);

	my $result = $geocode->resolve_column(\@rows, 'place');

	is($result->{'counts'}{'rows'}, 400, '400 rows');
	is($result->{'counts'}{'distinct'}, 4, 'holding four distinct values');
	is($result->{'counts'}{'skipped'}, 1, 'one of which is not a location');
	is($result->{'counts'}{'attempted'}, 3, 'so three are looked up');
	is($result->{'counts'}{'lookups'}, 3, 'and the geocoder was asked about three, not 400');
	is($result->{'counts'}{'resolved'}, 2, 'two resolved');
	is($result->{'counts'}{'unresolved'}, 1, 'one was looked up and not found');
	is($result->{'counts'}{'plotted'}, 398, 'and 398 rows are plottable');
};

subtest 'a place that is looked up and not found is remembered as tried' => sub {
	my $geocoder = stub();
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder);

	my @column = ({ 'place' => 'Nowhere, Imaginary, ZZ' }, { 'place' => 'Ramsgate, Kent' });

	my $first = $geocode->resolve_column(\@column, 'place');
	is($first->{'cache'}{'Nowhere, Imaginary, ZZ'}, 0, 'the miss is cached as 0, the tried-and-unresolved marker');
	is_deeply($first->{'unresolved'}, ['Nowhere, Imaginary, ZZ'], 'and reported as unresolved');

	# The second request over the same column: the answers are remembered, so the
	# geocoder is not asked anything at all - and the miss is still reported.
	my $calls = scalar @{ $geocoder->{'calls'} };
	my $second = $geocode->resolve_column(\@column, 'place', cache => $first->{'cache'});

	is(scalar @{ $geocoder->{'calls'} }, $calls, 'the second request asked the geocoder nothing');
	is($second->{'counts'}{'lookups'}, 0, 'no lookups');
	is($second->{'counts'}{'cached'}, 2, 'both distinct values came from the cache');
	is($second->{'counts'}{'resolved'}, 1, 'one resolved, from the cache');
	is($second->{'counts'}{'unresolved'}, 1, 'and the miss is still counted as unresolved');
	is_deeply($second->{'unresolved'}, ['Nowhere, Imaginary, ZZ'], 'and still named');
	is($second->{'counts'}{'plotted'}, 1, 'so the page says the same thing as the first request');
};

subtest 'a cached column still plots when no new lookup is possible' => sub {
	my $geocoder = stub();
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder);

	my $first = $geocode->resolve_column([ { 'place' => 'Ramsgate, Kent' } ], 'place');

	# The same column, with no geocoder to load and no injected one.
	local $ENV{'OPENADDR_HOME'};
	my $without = Database::BI::Model::Geocode->new(geocoder => undef, min_geocoder_version => '99.0');
	my $result  = $without->resolve_column([ { 'place' => 'Ramsgate, Kent' }, { 'place' => 'Nowhere' } ], 'place',
		cache => $first->{'cache'});

	is($result->{'available'}, 0, 'the geocoder is not available');
	is($result->{'counts'}{'resolved'}, 1, 'but the place remembered from the earlier request is plotted');
	is($result->{'counts'}{'not_attempted'}, 1, 'and the one that was never looked up is left for later');
	is_deeply($result->{'points'}{'Ramsgate, Kent'}{'lat'}, 51.33333, 'at the coordinates that were remembered');
};

subtest 'a backend exception is still an exception' => sub {
	my $geocoder = stub(bomb => { 'Sittingbourne' => 1 });
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder);

	my $cache  = {};
	my $result = eval { $geocode->resolve_column([ { 'place' => 'Ramsgate, Kent' }, { 'place' => 'Sittingbourne' } ], 'place', cache => $cache); };

	is($result, undef, 'the call did not return');
	like($@, qr/the backend was asked about 'Sittingbourne'/,
		'nothing is wrapped in an eval, so a backend that breaks on a real place breaks the request');
	is_deeply($cache, {}, "and the caller's cache is untouched: a request that dies cannot half-write it");
};

subtest 'the cap counts new lookups, and holds the rest back for the next request' => sub {
	my $geocoder = stub();
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder, openaddr => 'test');

	my @column = map { { 'place' => $_ } }
		('Ramsgate, Kent', 'Sittingbourne', 'Canterbury', 'Dover', 'Margate');

	my $first = $geocode->resolve_column(\@column, 'place', max => 2);

	is($first->{'counts'}{'attempted'}, 2, 'two of the five new places were looked up');
	is($first->{'counts'}{'lookups'}, 2, 'so two lookups');
	is($first->{'counts'}{'not_attempted'}, 3, 'the other three were held back');
	is($first->{'capped'}, 1, 'and the cap is reported');
	is_deeply($first->{'not_attempted'}, [ 'Canterbury', 'Dover', 'Margate' ], 'in first-seen order');
	is(scalar @{ $geocoder->{'calls'} }, 1, 'one batch, not two');
	is_deeply([ map { $_->{'key'} } @{ $first->{'messages'} } ],
		['warn_map_geocode_capped', 'warn_map_rows_skipped'], 'with a message that says so');
	like($first->{'messages'}[0]{'text'}, qr/Geocoded 2 of the 5 places/,
		'that counts what was left for the warm script');

	# Held back means not written down: the next request has to be able to finish
	# them, which it cannot do if they were recorded as tried.
	ok(!exists $first->{'cache'}{'Canterbury'}, 'a value the cap held back is not cached as tried');

	my $second = $geocode->resolve_column(\@column, 'place', max => 2, cache => $first->{'cache'});
	is($second->{'counts'}{'attempted'}, 2, 'the next request picks up two more');
	is($second->{'counts'}{'cached'}, 2, 'the two from before come from the cache');
	is($second->{'counts'}{'not_attempted'}, 1, 'and one is left');

	my $third = $geocode->resolve_column(\@column, 'place', max => 2, cache => $second->{'cache'});
	is($third->{'counts'}{'attempted'}, 1, 'the request after that picks up the last one');
	is($third->{'counts'}{'not_attempted'}, 0, 'and nothing is left behind');
	is($third->{'capped'}, 0, 'with the cap no longer binding');

	# A cached answer costs nothing, so it cannot consume the cap.
	my $fourth = $geocode->resolve_column(\@column, 'place', max => 1, cache => $third->{'cache'});
	is($fourth->{'counts'}{'attempted'}, 0, 'a column that is all cached performs no lookups, whatever the cap is');
	is($fourth->{'counts'}{'cached'}, 5, 'all five come from the cache');
	is($fourth->{'messages'}[0]{'key'}, 'warn_map_rows_skipped', 'and the only thing left to report is the rows');
};

subtest 'the counts add up, in every state' => sub {
	my $geocoder = stub();
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder);

	my @cases = (
		{ 'name' => 'a dirty column',     'rows' => dirty_column() },
		{ 'name' => 'nothing at all',     'rows' => [ { 'place' => undef }, { 'place' => '' }, { 'place' => '0044' } ] },
		{ 'name' => 'no rows',            'rows' => [] },
	);

	for my $case (@cases) {
		my $result = $geocode->resolve_column($case->{'rows'}, 'place');
		my $c = $result->{'counts'};

		is($c->{'skipped'} + $c->{'cached'} + $c->{'attempted'} + $c->{'not_attempted'}, $c->{'distinct'},
			"$case->{'name'}: every distinct value is skipped, cached, attempted or held back");
		is($c->{'resolved'} + $c->{'unresolved'}, $c->{'cached'} + $c->{'attempted'},
			"$case->{'name'}: every value with an answer is either resolved or unresolved");
		is($c->{'plotted'} + $c->{'unusable'}, $c->{'rows'},
			"$case->{'name'}: every row is plotted or unusable");
	}
};

subtest 'nothing to plot is not an error' => sub {
	my $geocoder = stub();
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder);

	my $result = $geocode->resolve_column([ { 'place' => '0044' }, { 'place' => '' } ], 'place');

	is($result->{'counts'}{'rows'}, 2, 'two rows were looked at');
	is($result->{'counts'}{'plotted'}, 0, 'none of them hold a location');
	is_deeply($result->{'markers'}, [], 'so there are no markers');
	is(scalar @{ $geocoder->{'calls'} }, 0, 'and the geocoder was not asked anything');

	my $empty = $geocode->resolve_column([], 'place');
	is_deeply($empty->{'counts'}, {
		'rows' => 0, 'plotted' => 0, 'unusable' => 0, 'distinct' => 0, 'skipped' => 0,
		'cached' => 0, 'attempted' => 0, 'lookups' => 0, 'resolved' => 0, 'unresolved' => 0,
		'not_attempted' => 0,
	}, 'and a dataset with no rows gives counts of zero rather than a message');
	is_deeply($empty->{'messages'}, [], 'with nothing to say');
};

subtest 'the region hint is passed through and never invented' => sub {
	my $geocoder = stub();
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder);

	$geocode->resolve_values(['Ramsgate, Kent'], region => 'US');
	is($geocoder->{'calls'}[-1]{'opts'}{'region'}, 'US', 'the region a caller gave is passed through');

	$geocode->resolve_values(['Ramsgate, Kent']);
	ok(!exists $geocoder->{'calls'}[-1]{'opts'}{'region'},
		'and no region is passed at all when none was configured: a language is not a country');
};

subtest 'the geocoder without OpenAddresses data is reported, not hidden' => sub {
	my $geocoder = stub();

	local $ENV{'OPENADDR_HOME'};
	my $bare = Database::BI::Model::Geocode->new(geocoder => $geocoder);
	my $without_data = $bare->resolve_values(['Ramsgate, Kent']);

	ok((grep { $_->{'key'} eq 'warn_map_geocoder_unavailable_data' } @{ $without_data->{'messages'} }),
		'a lookup with no OPENADDR_HOME says the answers are only as good as MaxMind');

	my $with = Database::BI::Model::Geocode->new(geocoder => $geocoder, openaddr => '/somewhere/openaddr');
	my $with_data = $with->resolve_values(['Ramsgate, Kent']);

	ok(!(grep { $_->{'key'} eq 'warn_map_geocoder_unavailable_data' } @{ $with_data->{'messages'} }),
		'and does not say it when openaddr data is configured');

	my $cached = $with->resolve_values(['Ramsgate, Kent'], cache => $with_data->{'cache'});
	ok(!(grep { $_->{'key'} eq 'warn_map_geocoder_unavailable_data' } @{ $cached->{'messages'} }),
		'nor when no lookup is needed in the first place');
};

subtest 'a geocoder that cannot answer the rule is refused at the door' => sub {
	my $without_many = bless {}, 'Stub::Geocode::OnlyGeocode';
	{
		no strict 'refs';
		# Everything a geocoder needs except the batch method, so that the
		# method this module reports missing is the one that is missing.
		*{'Stub::Geocode::OnlyGeocode::geocode'}       = sub { };
		*{'Stub::Geocode::OnlyGeocode::valid_location'} = sub { 1 };
	}

	throws_ok { Database::BI::Model::Geocode->new(geocoder => $without_many) }
		qr/must provide geocode_many\(\)/,
		'a geocoder with no geocode_many() is a programming error, not a missing dependency';

	my $without_rule = bless {}, 'Stub::Geocode::NoRule';
	{
		no strict 'refs';
		*{'Stub::Geocode::NoRule::geocode_many'} = sub { };
	}

	throws_ok { Database::BI::Model::Geocode->new(geocoder => $without_rule) }
		qr/must provide valid_location\(\)/,
		'and so is one that cannot answer the location rule';
};

subtest 'argument errors are refused by name' => sub {
	my $geocoder = stub();
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder);

	throws_ok { $geocode->resolve_values('Ramsgate, Kent') } qr/the values must be an arrayref/,
		'values that are not an arrayref';
	throws_ok { $geocode->resolve_column('rows', 'place') } qr/the rows must be an arrayref/,
		'rows that are not an arrayref';
	throws_ok { $geocode->resolve_column([], undef) } qr/the column name is required/,
		'a column with no name';
	throws_ok { $geocode->resolve_column([ { 'other' => 1 } ], 'place') } qr/Column "place" is not in this dataset/,
		'a column that is in none of the rows';

	for my $bad (0, -1, 'lots') {
		throws_ok { $geocode->resolve_column([ { 'place' => 'Ramsgate, Kent' } ], 'place', max => $bad) }
			qr/option "max" must be a positive integer/,
			"a cap of '$bad' is a caller bug rather than a cap";
	}

	my $ok = $geocode->resolve_column([ { 'place' => 'Ramsgate, Kent' } ], 'place', max => '10');
	is($ok->{'counts'}{'attempted'}, 1, 'and a cap written as a string of digits is accepted');
};

subtest 'a row that is not a hashref is skipped, not fatal' => sub {
	my $geocoder = stub();
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder);

	my $result = $geocode->resolve_column([ { 'place' => 'Ramsgate, Kent' }, 'not a row', undef ], 'place');

	is($result->{'counts'}{'rows'}, 3, 'the rows are counted');
	is($result->{'counts'}{'plotted'}, 1, 'the one that held a place is plotted');
	is($result->{'counts'}{'unusable'}, 2, 'and the two that were not rows are not');
};

subtest 'the model store keeps the answers, and this module never writes it' => sub {
	my $geocoder = stub();
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder);

	my $models = { 'fields' => { 'keep' => 'me' }, 'geo' => { 'table:other|loc=town' => { 'places' => { 'Elsewhere' => [ 1, 2 ] } } } };

	is_deeply(Database::BI::Model::Geocode->cache_from_models($models, 'table:sales|loc=place'), {},
		'a spec that has never been geocoded has an empty cache');

	my $result = $geocode->resolve_column([ { 'place' => 'Ramsgate, Kent' }, { 'place' => 'Nowhere' } ], 'place');

	my $updated = Database::BI::Model::Geocode->models_with_cache($models, 'table:sales|loc=place', $result->{'cache'},
		backend => $result->{'backend'}, built => '2026-10-16T12:00:00Z');

	is_deeply($updated->{'fields'}, { 'keep' => 'me' }, 'the other keys of the store are left alone');
	is_deeply($updated->{'geo'}{'table:other|loc=town'}, { 'places' => { 'Elsewhere' => [ 1, 2 ] } },
		'and so is another spec that has been geocoded');
	is_deeply($updated->{'geo'}{'table:sales|loc=place'}{'places'}, $result->{'cache'},
		'this spec holds the answers, tried-and-unresolved included');
	is($updated->{'geo'}{'table:sales|loc=place'}{'backend'}, $result->{'backend'}, 'with the backend that answered');
	is($updated->{'geo'}{'table:sales|loc=place'}{'built'}, '2026-10-16T12:00:00Z', 'and when');
	is_deeply($models->{'geo'}{'table:sales|loc=place'}, undef, "the store the caller passed was not modified");

	is_deeply(Database::BI::Model::Geocode->cache_from_models($updated, 'table:sales|loc=place'),
		$result->{'cache'}, 'and reading it back gives what the next request needs');
};

subtest 'one place answer serves every dataset' => sub {
	my $geocoder = stub();
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder);

	my $models = {
		'fields' => { 'keep' => 'me' },
		'geo'    => { 'table:old|loc=town' => { 'places' => { 'Elsewhere' => [ 1, 2 ] } } },
	};

	is_deeply(Database::BI::Model::Geocode->shared_cache_from_models($models), {},
		'a store written before sharing has no shared cache');
	is_deeply(Database::BI::Model::Geocode->shared_cache_from_models(undef), {},
		'and an absent store is not an error');

	my $result = $geocode->resolve_column(
		[ { 'place' => 'Ramsgate, Kent' }, { 'place' => 'Nowhere' } ], 'place',
		cache => Database::BI::Model::Geocode->cache_from_models($models, 'table:old|loc=town'),
	);

	my $updated = Database::BI::Model::Geocode->models_with_shared_cache(
		$models, $result->{'cache'},
		backend => $result->{'backend'}, built => '2026-10-17T09:00:00Z',
	);

	is_deeply($updated->{'fields'}, { 'keep' => 'me' }, 'the other keys of the store are left alone');
	is_deeply($updated->{'geo'}{'table:old|loc=town'}, { 'places' => { 'Elsewhere' => [ 1, 2 ] } },
		'the older per-dataset entry is left alone');
	is_deeply($updated->{'geo'}{'shared'}{'places'}, {
		'Elsewhere'      => [ 1, 2 ],
		'Ramsgate, Kent' => [ 51.33333, 1.43333 ],
		'Nowhere'        => 0,
	}, 'the shared entry holds the old and the new answers, misses included');
	is($updated->{'geo'}{'shared'}{'backend'}, $result->{'backend'}, 'with the backend that answered');
	is($updated->{'geo'}{'shared'}{'built'}, '2026-10-17T09:00:00Z', 'and when');
	is_deeply($models->{'geo'}{'shared'}, undef, 'the store the caller passed was not modified');

	my $more = Database::BI::Model::Geocode->models_with_shared_cache(
		$updated, { 'Paris' => [ 48.85, 2.35 ] },
	);
	is_deeply($more->{'geo'}{'shared'}{'places'}{'Paris'}, [ 48.85, 2.35 ],
		'a later write adds a place');
	is_deeply($more->{'geo'}{'shared'}{'places'}{'Ramsgate, Kent'}, [ 51.33333, 1.43333 ],
		'without dropping a place another request answered');
	is_deeply($updated->{'geo'}{'shared'}{'places'}{'Paris'}, undef,
		'and the store passed in is not modified');

	my $copy = Database::BI::Model::Geocode->shared_cache_from_models($more);
	is_deeply($copy, $more->{'geo'}{'shared'}{'places'},
		'reading the shared cache gives what the next request needs');
	$copy->{'New'} = [ 0, 0 ];
	ok(!exists $more->{'geo'}{'shared'}{'places'}{'New'},
		'and the copy is the caller\'s to modify');
};

subtest 'without the module there is a sentence, not an exception' => sub {
	# Test::Without::Module cannot un-load a module already in %INC (see CLAUDE.md).
	# If an earlier subtest loaded Geo::Coder::Free, we cannot simulate its absence.
	if (exists $INC{'Geo/Coder/Free.pm'}) {
		plan skip_all => 'Geo::Coder::Free already loaded; cannot simulate absence in this process';
	}

	Test::Without::Module->import('Geo::Coder::Free');

	my $geocode = Database::BI::Model::Geocode->new();

	my ($available, $reason) = $geocode->geocoder_available();
	is($available, 0, 'the geocoder is not available');
	like($reason, qr/Geo::Coder::Free 0\.47 or later/, 'and the reason names the version this module needs');
	like($reason, qr/not installed/, 'and says that it is not installed');

	my $result = $geocode->resolve_column(dirty_column(), 'place');

	is($result->{'available'}, 0, 'the request still answers');
	is($result->{'counts'}{'lookups'}, 0, 'with no lookups');
	# A blank cell, a missing cell and a reference are one distinct value - the one
	# with nothing in it - and it is refused without a geocoder to ask.
	is($result->{'counts'}{'distinct'}, 5, 'the column holds five distinct values');
	is($result->{'counts'}{'skipped'}, 1, 'and the cell with nothing in it is refused');
	is_deeply($result->{'not_attempted'}, [ 'Ramsgate, Kent', 'Sittingbourne', '0044', '12' ],
		'while the four values that could be looked up are held back rather than guessed at');
	is_deeply($result->{'markers'}, [], 'so there is nothing to plot');
	is_deeply([ map { $_->{'key'} } @{ $result->{'messages'} } ],
		['error_map_geocoder_missing', 'warn_map_rows_skipped'],
		'and the page is told why, before it is told about the rows');

	my ($missing) = grep { $_->{'key'} eq 'error_map_geocoder_missing' } @{ $result->{'messages'} };
	my @mentions = ($missing->{'text'} =~ /Geo::Coder::Free/g);
	is(scalar @mentions, 1,
		'and says it once: the finished sentence is not formatted a second time');
};

subtest 'an installed module older than the floor is the same state' => sub {
	local $ENV{'OPENADDR_HOME'};

	my $geocode = Database::BI::Model::Geocode->new(geocoder => undef, min_geocoder_version => '99.0');

	my ($available, $reason) = $geocode->geocoder_available();
	is($available, 0, 'a geocoder below the floor is not used');
	like($reason, qr/99\.0/, 'the reason names the floor');
	like($reason, qr/installed|could not be loaded/, 'and says what is installed instead');
};

subtest 'every message this module produces is in its dictionary' => sub {
	my $geocoder = stub();
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder);

	my $result = $geocode->resolve_column([ { 'place' => '0044' } ], 'place');

	ok((scalar keys %Database::BI::Model::Geocode::MESSAGES) >= 10, 'the dictionary is populated');

	for my $message (@{ $result->{'messages'} }) {
		ok($Database::BI::Model::Geocode::MESSAGES{ $message->{'key'} }, "$message->{'key'} is a defined key");
		ok(defined($message->{'text'}) && length($message->{'text'}), 'and has text');
		unlike($message->{'text'}, qr/Internal error/,
			'and never falls back to the unknown-key text');
	}

	# Section 7: the diagnostics carry no data.  The value in the column is a
	# location, which in a personal dataset is personal information.
	unlike(join(' ', map { $_->{'text'} } @{ $result->{'messages'} }), qr/0044/,
		'no message repeats a location value from the column');
};

subtest 'the diagnostics can be rendered by the caller' => sub {
	my %seen;
	my $i18n = bless {}, 'Stub::I18n';
	{
		no strict 'refs';
		*{'Stub::I18n::maketext'} = sub { $seen{ $_[1] }++; return "translated: $_[1]" };
	}

	my $geocode = Database::BI::Model::Geocode->new(geocoder => stub(), i18n => $i18n);
	my $result  = $geocode->resolve_column([ { 'place' => '0044' } ], 'place');

	is($result->{'messages'}[0]{'text'}, 'translated: warn_map_rows_skipped',
		'a caller-supplied i18n object renders the text');
	is($result->{'messages'}[0]{'key'}, 'warn_map_rows_skipped',
		'and the key travels with it, so it can be re-rendered');
	ok($seen{'warn_map_rows_skipped'}, 'the object was asked for that key');
};

done_testing();
