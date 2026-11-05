#!/usr/bin/env perl

# The geocoding chain: Geo::Coder::List asks Geo::Coder::Free's local data
# first and OpenStreetMap's Nominatim (Geo::Coder::OSM) for the places it does
# not know, through a LWP::UserAgent::Throttled that keeps Nominatim's one
# request a second.
#
# Nothing here reaches the network: BI::Test::Nominatim stands in for the
# local data and for Nominatim, and records every request that would have been
# sent.  What is pinned:
#
#   * a place the local data knows never goes online;
#   * a place it does not know is asked of Nominatim, found, remembered, and
#     credited to Geo::Coder::OSM;
#   * a place Nominatim does not know is remembered as not found;
#   * a Nominatim that fails is not taken to mean the place does not exist:
#     the place is held, not remembered, Nominatim is not asked again in that
#     request, and the page is told without being told the place;
#   * online_max holds the rest back once it is spent;
#   * online => 0, or no Geo::Coder::OSM, keeps every lookup local;
#   * a local geocoder that throws holds the place rather than losing it;
#   * the user agent names Database::BI and is throttled for Nominatim.
#
#   prove -l t/geocode-online.t

use strict;
use warnings;

use Test::Most;
use Test::Needs {
	'Geo::Coder::List'          => '0.39',
	'Geo::Coder::OSM'           => '0.03',
	'LWP::UserAgent::Throttled' => '0.14',
	'Geo::Location::Point'      => 0,	# what the stand-in local data answers with
};

use lib 't/lib';
use BI::Test::Nominatim qw(with_chain);
use Database::BI::Model::Geocode;
use Mojo::JSON qw(encode_json);
use File::Spec;
use File::Temp qw(tempdir);

my $G = 'Database::BI::Model::Geocode';

# No OPENADDR_HOME, so whether the coarse-data warning is given depends on the
# chain alone.
delete $ENV{OPENADDR_HOME};

sub keys_of {
	my ($result) = @_;
	return [ map { $_->{key} } @{ $result->{messages} } ];
}

sub text_of {
	my ($result, $key) = @_;
	my ($m) = grep { $_->{key} eq $key } @{ $result->{messages} };
	return $m ? $m->{text} : undef;
}

subtest 'the local data first, Nominatim for the rest' => sub {
	with_chain(
		local  => { 'Ramsgate' => [ 51.33, 1.42 ] },
		online => { 'Margate'  => [ 51.3878174, 1.3819699 ] },
		sub {
			my ($seen) = @_;
			my $r = $G->new->resolve_values([ 'Ramsgate', 'Margate' ]);

			is_deeply([ map { $_->{place} } @{ $seen->{requests} } ], ['Margate'],
				'only the place the local data does not know goes online');
			is($seen->{requests}[0]{host}, 'nominatim.openstreetmap.org', 'to Nominatim');
			like($seen->{requests}[0]{uri}, qr{\Ahttps://}, 'over https, not http and a redirect');
			like($seen->{requests}[0]{agent}, qr{\ADatabase-BI/\S+ \(\+https://metacpan\.org/dist/Database-BI\)\z},
				'from a client that says what it is');

			is_deeply($r->{cache}{Margate}, [ 51.3878174, 1.3819699 ], 'the answer is remembered');
			is(encode_json($r->{cache}{Margate}), '[51.3878174,1.3819699]',
				'as numbers, though Nominatim sends strings');
			is($r->{points}{Margate}{backend}, 'Geo::Coder::OSM', 'credited to Geo::Coder::OSM');
			is($r->{points}{Ramsgate}{backend}, 'Fake', 'and the local answer to the local data');
			is($r->{counts}{online}, 1, 'one lookup went online');
			is($r->{counts}{attempted}, 2, 'two were attempted');
			is($r->{counts}{resolved}, 2, 'both resolved');
			ok(!(grep { $_ eq 'warn_map_geocoder_unavailable_data' } @{ keys_of($r) }),
				'and the answers are not called coarse, since Nominatim was there');
		},
	);
};

subtest 'a place Nominatim does not know is remembered as not found' => sub {
	with_chain(online => { 'Nowhere Special' => 'none' }, sub {
		my ($seen) = @_;
		my $r = $G->new->resolve_values(['Nowhere Special']);
		is(scalar @{ $seen->{requests} }, 1, 'Nominatim was asked');
		is($r->{cache}{'Nowhere Special'}, 0, 'and its "no" is remembered');
		is($r->{counts}{unresolved}, 1, 'as unresolved');
		is($r->{counts}{not_attempted}, 0, 'not as left for later');
	});
};

subtest 'a Nominatim that fails does not lose the place' => sub {
	with_chain(
		local  => { 'Deal' => [ 51.22, 1.40 ] },
		online => { 'Sandwich' => 429 },
		sub {
			my ($seen) = @_;
			my $r = $G->new->resolve_values([ 'Sandwich', 'Walmer', 'Deal' ]);

			is_deeply([ map { $_->{place} } @{ $seen->{requests} } ], ['Sandwich'],
				'after one failure Nominatim is not asked again in the request');
			ok(!exists $r->{cache}{Sandwich}, 'the place it failed on is not remembered');
			ok(!exists $r->{cache}{Walmer}, 'nor one it was never asked about');
			is_deeply($r->{cache}{Deal}, [ 51.22, 1.40 ], 'the local data still answers the rest');
			is_deeply([ sort @{ $r->{not_attempted} } ], [ 'Sandwich', 'Walmer' ], 'the two are left for later');
			is($r->{counts}{attempted} + $r->{counts}{not_attempted} + $r->{counts}{skipped} + $r->{counts}{cached},
				$r->{counts}{distinct}, 'and the counts still add up');

			my $text = text_of($r, 'warn_map_geocoder_online_failed');
			like($text, qr/\b429\b/, 'the page is told what Nominatim answered');
			like($text, qr/\b2 places\b/, 'and how many places wait');
			unlike($text, qr/Sandwich|Walmer/, 'but not which places: they are the reader\'s data');
		},
	);
};

subtest 'online_max holds the rest back' => sub {
	with_chain(online => { A1 => [ 1, 1 ], B2 => [ 2, 2 ], C3 => [ 3, 3 ] }, sub {
		my ($seen) = @_;
		my $r = $G->new(online_max => 2)->resolve_values([qw(A1 B2 C3)]);
		is(scalar @{ $seen->{requests} }, 2, 'two places went online');
		is_deeply($r->{not_attempted}, ['C3'], 'the third waits');
		ok(!exists $r->{cache}{C3}, 'unremembered, so the next request asks');
		ok($r->{capped}, 'the result says it was capped');
		ok(text_of($r, 'warn_map_geocode_capped'), 'and so does the page');
	});

	with_chain(local => { Z9 => [ 9, 9 ] }, online => { A1 => [ 1, 1 ] }, sub {
		my ($seen) = @_;
		my $r = $G->new(online_max => 1)->resolve_values([qw(A1 Z9)]);
		is_deeply($r->{cache}{Z9}, [ 9, 9 ], 'a place the local data knows is still found once the budget is spent');
		ok(!$r->{capped}, 'and nothing is held back');
	});

	throws_ok { $G->new(online_max => 0) } qr/online_max.*positive integer/, 'a cap of 0 is refused';
	throws_ok { $G->new(online_max => 'lots') } qr/online_max.*positive integer/, 'as is one that is not a number';
};

subtest 'online => 0 keeps every lookup local' => sub {
	with_chain(online => { Margate => [ 1, 1 ] }, sub {
		my ($seen) = @_;
		my $r = $G->new(online => 0)->resolve_values(['Margate']);
		is(scalar @{ $seen->{requests} }, 0, 'nothing went online');
		is($r->{cache}{Margate}, 0, 'and the place is not found');
		ok((grep { $_ eq 'warn_map_geocoder_unavailable_data' } @{ keys_of($r) }),
			'the answers are called as coarse as the local data is');
		ok(!(grep { $_ eq 'warn_map_geocoder_local_only' } @{ keys_of($r) }),
			'but nothing is said to be missing: online lookups were turned off');
	});
};

subtest 'without Geo::Coder::OSM the local data is all there is' => sub {
	with_chain(hide => ['Geo::Coder::OSM'], online => { Margate => [ 1, 1 ] }, sub {
		my ($seen) = @_;
		my $geocode = $G->new;
		my ($available) = $geocode->geocoder_available;
		is($available, 1, 'the geocoder is still available');
		my $r = $geocode->resolve_values(['Margate']);
		is(scalar @{ $seen->{requests} }, 0, 'nothing went online');
		like(text_of($r, 'warn_map_geocoder_local_only') // '', qr/Geo::Coder::OSM 0\.03/,
			'and the page says what would find more');
	});
};

subtest 'without Geo::Coder::List there is no geocoder' => sub {
	with_chain(hide => ['Geo::Coder::List'], sub {
		my $geocode = $G->new;
		my ($available, $reason) = $geocode->geocoder_available;
		is($available, 0, 'it is unavailable');
		like($reason, qr/Geo::Coder::List 0\.39 or later, and it is not installed/, 'and says which module, and why');
		my $r = $geocode->resolve_values(['Margate']);
		is_deeply(keys_of($r), ['error_map_geocoder_list_missing'], 'the result carries the same key');
		is_deeply($r->{not_attempted}, ['Margate'], 'and nothing was looked up');
	});
};

subtest 'a local geocoder that throws holds the place' => sub {
	with_chain(local => { Boom => 'die', Fine => [ 5, 5 ] }, online => {}, sub {
		my ($seen) = @_;
		my $r = do {
			local $SIG{__WARN__} = sub { };	# Geo::Coder::List reports the throw
			$G->new->resolve_values([qw(Boom Fine)]);
		};
		ok(!exists $r->{cache}{Boom}, 'the place whose lookup threw is not remembered as not found');
		is_deeply($r->{not_attempted}, ['Boom'], 'it is left for later');
		is_deeply($r->{cache}{Fine}, [ 5, 5 ], 'and the next place is still looked up');
	});
};

subtest 'Geo::Coder::List is given the cache, and uses it' => sub {
	my %cache;
	with_chain(online => { Margate => [ 51.39, 1.38 ] }, sub {
		my ($seen) = @_;
		my $chain = $G->new(cache => \%cache)->_geocoder;
		is($chain->{cache}, \%cache, 'the chain holds the cache it was given');

		$G->new(cache => \%cache)->resolve_values(['Margate']);
		is(scalar @{ $seen->{requests} }, 1, 'the first object asks Nominatim');
		ok(scalar(keys %cache), 'and the answer is stored in the cache');

		my $again = $G->new(cache => \%cache)->resolve_values(['Margate']);
		is(scalar @{ $seen->{requests} }, 1, 'a second object, sharing the cache, asks nobody');
		is_deeply($again->{cache}{Margate}, [ 51.39, 1.38 ], 'and still has the answer');
		is($again->{counts}{lookups}, 0, 'which is not counted as a lookup');
		is($again->{counts}{online}, 0, 'nor against online_max');
	});

	with_chain(online => { Deal => [ 51.22, 1.40 ] }, sub {
		my ($seen) = @_;
		$G->new->resolve_values(['Deal']);
		$G->new->resolve_values(['Deal']);
		is(scalar @{ $seen->{requests} }, 1,
			'with no cache given, objects in one process share a default one');
	});

	my $dir = tempdir(CLEANUP => 1);
	with_chain(online => { Walmer => [ 51.20, 1.40 ] }, sub {
		my ($seen) = @_;
		$G->new(cache => $G->file_cache($dir))->resolve_values(['Walmer']);
		ok(-d File::Spec->catdir($dir, 'geocode-cache'), 'file_cache keeps its answers under the directory');

		# A new cache over the same directory, with its in-memory copy emptied,
		# stands for another worker or a restart.
		my $fresh = $G->file_cache($dir);
		$fresh->l1_cache->clear;
		my $r = $G->new(cache => $fresh)->resolve_values(['Walmer']);
		is(scalar @{ $seen->{requests} }, 1, 'which another process reads without asking Nominatim');
		is_deeply($r->{cache}{Walmer}, [ 51.20, 1.40 ], 'and gets the same answer');
	});

	# The local data alone goes through the cache as well: with Nominatim off,
	# and with it on for the places past online_max.
	my %offline;
	with_chain(local => { Ramsgate => [ 51.33, 1.42 ] }, sub {
		my ($seen) = @_;
		my $local = $seen->{local};

		my $first = $G->new(cache => \%offline, online => 0)->resolve_values(['Ramsgate'], { region => 'GB' });
		is_deeply($local->{calls}, ['Ramsgate'], 'offline, the local data is asked');
		is_deeply($local->{regions}, ['GB'], 'with the region hint');
		is($first->{counts}{lookups}, 1, 'which is a lookup');
		ok(scalar(keys %offline), 'and what it found is in the cache');

		my $again = $G->new(cache => \%offline, online => 0)->resolve_values(['Ramsgate']);
		is_deeply($local->{calls}, ['Ramsgate'], 'a second object answers from the cache without asking it');
		is_deeply($again->{cache}{Ramsgate}, [ 51.33, 1.42 ], 'with the same answer');
		is($again->{counts}{lookups}, 0, 'not counted as a lookup');
	});

	with_chain(online => { Deal => [ 51.22, 1.40 ] }, sub {
		my ($seen) = @_;
		$G->new(cache => \%offline)->resolve_values(['Deal'], { region => 'GB' });
		is_deeply($seen->{requests}[0]{uri} =~ /region/ ? ['region'] : [], [],
			'the region hint is not sent to Nominatim');

		my $r = $G->new(cache => \%offline, online => 0)->resolve_values(['Deal']);
		is_deeply($r->{cache}{Deal}, [ 51.22, 1.40 ], 'and offline, a place Nominatim found is answered from the cache');
	});

	with_chain(local => { Hythe => [ 51.07, 1.08 ] }, online => { Sandgate => [ 51.07, 1.15 ] }, sub {
		my ($seen) = @_;
		my %shared;
		$G->new(cache => \%shared, online => 0)->resolve_values(['Hythe']);
		my $calls = scalar @{ $seen->{local}{calls} };
		$G->new(cache => \%shared, online_max => 1)->resolve_values([qw(Sandgate Hythe)]);
		is(scalar @{ $seen->{local}{calls} }, $calls + 1,
			'past online_max the local data is asked only about what the cache does not know');
	});

	with_chain(local => { Boom => 'die', Fine => [ 5, 5 ] }, sub {
		my $r = do {
			local $SIG{__WARN__} = sub { };
			$G->new(online => 0)->resolve_values([qw(Boom Fine)]);
		};
		ok(!exists $r->{cache}{Boom}, 'offline, a lookup that threw is not remembered as not found');
		is_deeply($r->{not_attempted}, ['Boom'], 'it is left for later');
		is_deeply($r->{cache}{Fine}, [ 5, 5 ], 'and the next place is still looked up');
	});

	throws_ok { $G->file_cache(File::Spec->catdir($dir, 'not-there')) } qr/needs a directory that exists/,
		'file_cache refuses a directory that does not exist';
	throws_ok { $G->new(cache => bless {}, 'Local::NoGetSet') } qr/get\(\) and set\(\).*Local::NoGetSet/,
		'and new() a cache without get() and set()';
	throws_ok { $G->new(cache => 'a string') } qr/cache/, 'or one that is not a reference';
};

subtest 'the user agent keeps Nominatim\'s policy' => sub {
	with_chain(sub {
		my $osm = Database::BI::Model::Geocode::_online_geocoder();
		isa_ok($osm, 'Geo::Coder::OSM');
		my $ua = $osm->ua;
		isa_ok($ua, 'LWP::UserAgent::Throttled');
		is($ua->{throttle}{'nominatim.openstreetmap.org'}, 1, 'one request a second to Nominatim');
		cmp_ok($ua->timeout, '<=', 10, 'and a short time-out');
		is(Database::BI::Model::Geocode::_online_geocoder()->ua, $ua,
			'every lookup in the process shares it, so the gap holds across requests');
	});
};

done_testing();
