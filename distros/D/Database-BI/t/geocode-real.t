#!/usr/bin/env perl

# The real Geo::Coder::Free behind Phase 6.2 of BI-Phase6.md, rather than the
# stub t/geocode.t drives it with: a dirty column is handed to
# resolve_column() with no injected geocoder, so the module's own loading path,
# the module's own valid_location() and a real batch are what is under test.
#
# No place name is hard-coded as expected to resolve.  The catalogues this
# machine has are asked which of a few places they can answer, and the
# assertions are about the places that did - a checkout with OpenAddresses data
# answers a street address, one with only the bundled MaxMind data answers a
# city, and a machine with neither skips.  The wiring is the same either way,
# which is the point: this test must not be a test of one machine's data.
#
#   prove -l t/geocode-real.t
#   PERL5LIB=../Geo-Coder-Free/lib prove -l t/geocode-real.t

use strict;
use warnings;

use Test::Most;
use Test::Needs { 'Geo::Coder::Free' => '0.47' };	# skips the file, as BI-Phase6.md section 11 asks
use Database::BI::Model::Geocode;

# Geo::Coder::Free is a recommends, not a prerequisite: 0.46 added
# valid_location() and 0.47 added geocode_many(), and the app installs, starts
# and tests without either.  Test::Needs above skips a machine without 0.47+;
# this catches the other case, a module that claims the version and does not
# answer the two questions this module asks of one.
for my $method (qw(valid_location geocode_many)) {
	plan skip_all => "Geo::Coder::Free $Geo::Coder::Free::VERSION has no $method()"
		unless Geo::Coder::Free->can($method);
}

# ---------------------------------------------------------------------------
# The values the column holds.  Places, the kind of thing a column-offset
# mistake puts in a place column, and one place that cannot be found - which is
# what on_error => 'undef' is for.
# ---------------------------------------------------------------------------

my $REGION  = 'US';			# what map_region would be configured to
my $UNKNOWN = 'Nowhere, Imaginary, ZZ';

my @CANDIDATES = (
	'1600 Pennsylvania Avenue NW, Washington DC',	# a street address: OpenAddresses
	'Springfield, IL',				# a city: MaxMind
	'Sittingbourne, Kent',
);

my @JUNK = ('0044', '12');	# bare numbers: never a location, whatever region

# Two numbers alike within a nanodegree: the geocoder is asked twice for the
# same place, and this is the comparison that says the answers agree.
sub same_number {
	my ($one, $two) = @_;

	return 0 unless defined($one) && defined($two);

	return (abs($one - $two) < 1e-9) ? 1 : 0;
}

sub rows_for {
	my ($places) = @_;

	return [
		(map { { 'place' => $places->[0] } } 1 .. 3),	# a place repeated
		(map { { 'place' => $_ } } @JUNK),
		{ 'place' => '' },				# a blank cell
		{ 'place' => undef },				# a missing cell
		{ 'place' => { 'lat' => 'not', 'a' => 'place' } },	# not a string at all
		{ 'place' => $UNKNOWN },			# a place with no answer
		(map { { 'place' => $_ } } @{ $places }[1 .. $#{ $places }]),
	];
}

# ---------------------------------------------------------------------------
# Ask the installed catalogues what they can answer before asserting anything
# about the answers.
# ---------------------------------------------------------------------------

my $geocode = Database::BI::Model::Geocode->new();	# no injected geocoder: the real one

my ($available, $reason) = $geocode->geocoder_available();
plan skip_all => "no usable geocoder: $reason" unless $available;

my $probe = $geocode->resolve_values([@CANDIDATES], region => $REGION);

my @places = grep { $probe->{'points'}{$_} } @CANDIDATES;

plan skip_all => 'the installed geocoder has no data for any of the probe places ('
	. join(', ', @CANDIDATES) . ')'
	unless @places;

# What the real geocoder answered in the probe, to check the module's cache and
# markers against the numbers the geocoder itself handed back.
my %probe_point = map { $_ => $probe->{'points'}{$_} } @places;

# Filled in by the first subtest, so the second one does not look the same
# column up a second time merely to have an answer to compare against.
my $dirty;

subtest 'the rule is the installed module\'s own, not a second copy of it' => sub {
	my $real = Geo::Coder::Free->new();

	ok($real->valid_location($places[0]), "the module accepts a place: '$places[0]'");
	ok(!$real->valid_location($JUNK[0]), "and refuses a bare number: '$JUNK[0]'");
	ok(!$real->valid_location(''), 'and refuses a blank cell');

	# What the module's counts rely on: a value the rule refuses is not a lookup.
	my $refused = $real->geocode_many([@JUNK], region => $REGION, on_error => 'undef');

	is($refused->{'lookups'}, 0, 'a refused value is not a lookup');
	is($refused->{'unresolved'}, 2, 'and is unresolved rather than an answer');

	# 0.48 counts the reads the backends made, so a value answered from a cache
	# is not a lookup at all: a value no catalogue has been asked about yet is
	# one read, and asking for it again in the same process is none.  This is
	# the finer count the module's own documentation promises when it says
	# lookups is C<attempted> unless the geocoder knows better.
	my $fresh = $real->geocode_many(['Nowhere Else, Imaginary, ZZ'], region => $REGION, on_error => 'undef');

	is($fresh->{'lookups'}, 1, 'a value no backend has been asked about costs one lookup');
	is($real->geocode_many(['Nowhere Else, Imaginary, ZZ'], region => $REGION, on_error => 'undef')->{'lookups'}, 0,
		'and the same batch again is answered from the cache, at no cost');

	# The trap the module exists to avoid: the same batch with the geocoder's own
	# default dies on the dirty column instead of skipping it.
	throws_ok { $real->geocode_many([@JUNK], region => $REGION) }
		qr/invalid location to geocode\(\)/,
		'a batch made without the rule dies on the first bare number, which is why the rule is asked first';

	done_testing();
};

# ---------------------------------------------------------------------------
# The dirty column, end to end.
# ---------------------------------------------------------------------------

subtest 'a dirty column comes back with the places plotted and the junk counted' => sub {
	my @column = @{ rows_for(\@places) };

	$dirty = $geocode->resolve_column(\@column, 'place', region => $REGION);

	is($dirty->{'available'}, 1, 'the real geocoder was used');
	is_deeply($dirty->{'not_attempted'}, [], 'and nothing was held back: the cap is 500 by default');

	# The junk is refused by the module's own copy of the rule, so it is counted
	# and dropped rather than looked up.  '' is one distinct value even though the
	# column spells it three ways.
	is($dirty->{'counts'}{'skipped'}, @JUNK + 1, 'the two bare numbers and the empty cell are skipped');
	is($dirty->{'counts'}{'distinct'}, @places + @JUNK + 2, 'the distinct values are the places, the junk, the empty cell and the unknown place');
	is($dirty->{'counts'}{'attempted'}, @places + 1, 'so one batch holds the places and the unresolvable one');

	# The probe above has already asked the geocoder for the places, so this
	# batch reads for fewer of them than it was handed: the count is the reads
	# made, never more than the values attempted, and the value no catalogue had
	# been asked about is one of them.
	cmp_ok($dirty->{'counts'}{'lookups'}, '<=', @places + 1,
		'the geocoder reports no more lookups than the values it was handed');
	cmp_ok($dirty->{'counts'}{'lookups'}, '>', 0,
		'and the value no cache had seen cost a read');
	is($dirty->{'counts'}{'resolved'}, @places, 'every probe place resolved again');
	is($dirty->{'counts'}{'unresolved'}, 1, 'and the place with no answer is a miss rather than a death');

	# Which values are which: the crux of section 6.2.
	is_deeply($dirty->{'unresolved'}, [$UNKNOWN], 'the miss is named');
	is_deeply([sort keys %{ $dirty->{'cache'} }], [sort(@places, $UNKNOWN)],
		'only the values that were looked up are remembered');

	for my $value (@JUNK) {
		ok(!exists $dirty->{'cache'}{$value}, "a bare number ('$value') was never looked up");
		ok(!exists $dirty->{'points'}{$value}, 'and is nowhere near the map');
	}

	ok(!exists $dirty->{'cache'}{''}, 'and neither was the empty cell the column spells three ways');

	# What the renderer gets: markers holding numbers the real point objects gave.
	my %marker = map { $_->{'value'} => $_ } @{ $dirty->{'markers'} };

	is_deeply([map { $_->{'value'} } @{ $dirty->{'markers'} }],
		[sort { $marker{$a}{'first_row'} <=> $marker{$b}{'first_row'} } @places],
		'one marker per place, in first-seen order');

	is($marker{ $places[0] }{'rows'}, 3, 'the repeated place knows how many rows it stands for');

	for my $value (@places) {
		my $point = $marker{$value};

		ok(defined($point), "'$value' has a marker");
		ok(same_number($point->{'lat'}, $probe_point{$value}{'lat'}),
			"at the latitude the geocoder gave for it: " . ($point->{'lat'} // 'undef'));
		ok(same_number($point->{'lon'}, $probe_point{$value}{'lon'}),
			'and that longitude');

		ok(defined($point->{'backend'}) && length($point->{'backend'}),
			'and says which dataset answered: ' . ($point->{'backend'} // 'undef'));

		# Section 6.2's other requirement: numbers, not strings, reach the map.
		ok($point->{'lat'} =~ /\A-?[0-9.]+\z/ && $point->{'lat'} >= -90 && $point->{'lat'} <= 90,
			"the latitude for '$value' is a number in range");
		ok($point->{'lon'} =~ /\A-?[0-9.]+\z/ && $point->{'lon'} >= -180 && $point->{'lon'} <= 180,
			'and so is the longitude');
	}

	my $plottable = 3 + @places - 1;

	is($dirty->{'counts'}{'rows'}, scalar @column, 'every row was looked at');
	is($dirty->{'counts'}{'plotted'}, $plottable, 'and the rows holding a place are plotted');
	is($dirty->{'counts'}{'unusable'}, scalar(@column) - $plottable, 'the rest are reported, not hidden');

	# Section 6.3's cache shape, holding the real geocoder's own numbers.
	for my $value (@places) {
		ok(same_number($dirty->{'cache'}{$value}[0], $probe_point{$value}{'lat'}),
			"'$value' is remembered as [lat, lon]");
		ok(same_number($dirty->{'cache'}{$value}[1], $probe_point{$value}{'lon'}),
			'with the longitude the geocoder gave');
	}

	is($dirty->{'cache'}{$UNKNOWN}, 0, 'and the miss is remembered as tried, so it is not retried');

	done_testing();
};

subtest 'a second request over the same column asks the geocoder nothing' => sub {
	my @column = @{ rows_for(\@places) };

	my $again = $geocode->resolve_column(\@column, 'place', region => $REGION, cache => $dirty->{'cache'});

	is($again->{'counts'}{'lookups'}, 0, 'no lookups the second time');
	is($again->{'counts'}{'attempted'}, 0, 'because every distinct value had been answered already');
	is($again->{'counts'}{'cached'}, @places + 1, 'all of them from the cache');
	is($again->{'counts'}{'resolved'}, @places, 'the places are still resolved');
	is($again->{'counts'}{'unresolved'}, 1, 'and the miss is still a miss');
	is($again->{'counts'}{'plotted'}, $dirty->{'counts'}{'plotted'}, 'the page says the same thing as the first request');
	is($again->{'counts'}{'unusable'}, $dirty->{'counts'}{'unusable'}, 'about the same rows');
	# Section 6.3 remembers a position for a place, not which dataset gave it - that
	# is the spec's single 'backend' key, so a remembered place claims none.
	my $remembered = $again->{'points'}{ $places[0] };

	ok(same_number($remembered->{'lat'}, $dirty->{'points'}{ $places[0] }{'lat'}),
		'a remembered place is plotted at the latitude it resolved to');
	ok(same_number($remembered->{'lon'}, $dirty->{'points'}{ $places[0] }{'lon'}),
		'and at that longitude');
	ok(!exists $remembered->{'backend'},
		'and claims no backend of its own, which the cache does not carry');
	is($again->{'counts'}{'skipped'}, @JUNK + 1, 'and the junk is skipped exactly as before');

	done_testing();
};

done_testing();
