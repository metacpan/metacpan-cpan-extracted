#!/usr/bin/env perl
# t/mmdb.t -- country() and time_zone() with a MaxMind GeoIP2 / GeoLite2
# database (.mmdb), read by IP::Geolocation::MMDB or MaxMind::DB::Reader.
#
# Real databases are licensed and large, so _write_mmdb() builds small ones
# in a temp directory: an IPv4 binary search tree with 24-bit records, the
# data section, and the metadata map, as in the MaxMind DB format
# specification (https://maxmind.github.io/MaxMind-DB/).  Each test runs
# once for every reader module that is installed.  All network look-ups are
# mocked.

use strict;
use warnings;

use CHI;
use File::Temp ();
use Readonly;
use Test::Mockingbird;
use Test::Most;

use CGI::Lingua;

Readonly my @READERS => ('IP::Geolocation::MMDB', 'MaxMind::DB::Reader');
Readonly my @INSTALLED => grep { eval { _require($_); 1 } } @READERS;

plan(skip_all => 'Neither IP::Geolocation::MMDB nor MaxMind::DB::Reader is installed') unless @INSTALLED;

Readonly my $GEO_ABSENT  => 0;
Readonly my $GEO_PRESENT => 1;
Readonly my $CACHE_NS    => 'CGI::Lingua:';

Readonly my %IP => (
	GB      => '81.2.69.160',	# City record with a time zone
	US      => '8.8.8.8',	# Country record: no location
	HK      => '4.4.4.4',	# legacy mapping hk -> cn applies
	HOSTILE => '1.1.1.1',	# bad iso_code and time_zone
	BADTYPE => '9.9.9.9',	# country is a string, not a map
	MISSING => '5.5.5.5',	# not in the database
	V6      => '2001:4860:4860::8888',	# the database is IPv4-only
);

# Record per network.  Values are what a real GeoIP2 database holds, plus
# hostile ones: the file may come from anywhere.
Readonly my %NETWORKS => (
	'81.2.69.0/24' => { country => { iso_code => 'GB' }, location => { time_zone => 'Europe/London' } },
	'8.8.8.0/24'   => { country => { iso_code => 'US' } },
	'4.4.4.0/24'   => { country => { iso_code => 'HK' }, location => { time_zone => 'Asia/Hong_Kong' } },
	'1.1.1.0/24'   => { country => { iso_code => 'G<' }, location => { time_zone => 'Europe/London<script>' } },
	'9.9.9.0/24'   => { country => 'GB', location => 'Europe/London' },
);

# Pre-require the modules that are mocked below, so a lazy require inside
# CGI::Lingua cannot overwrite the mocks.
my $HAS_LWP    = eval { require LWP::Simple::WithCache; 1 } ? 1 : 0;
my $HAS_LWP_SM = eval { require LWP::Simple; 1 } ? 1 : 0;

sub _block_network {
	local $SIG{__WARN__} = sub { };	# prototype mismatch on get($)
	Test::Mockingbird::mock('CGI::Lingua', '_resolve_country_via_whois', sub { });
	Test::Mockingbird::mock('LWP::Simple::WithCache', 'get', sub { undef }) if $HAS_LWP;
	Test::Mockingbird::mock('LWP::Simple', 'get', sub { undef }) if $HAS_LWP_SM;
}

sub _restore {
	local $SIG{__WARN__} = sub { };
	Test::Mockingbird::restore_all();
	_block_network();
}

_block_network();

sub _require {
	(my $pm = shift() . '.pm') =~ s{::}{/}g;
	return require $pm;
}

# -- A minimal MaxMind DB writer ----------------------------------------------

# Data types from the specification.  Numbers above 7 are "extended" types.
Readonly my %TYPE => (utf8 => 2, uint16 => 5, uint32 => 6, map => 7, uint64 => 9, array => 11);
Readonly my $METADATA_MARKER => "\xAB\xCD\xEFMaxMind.com";
Readonly my $RECORD_BYTES    => 3;	# 24-bit records
Readonly my $SEPARATOR       => "\0" x 16;

sub _control {
	my ($type, $size) = @_;	# every size here is below 29: no size bytes
	return ($type <= $TYPE{map}) ? chr(($type << 5) | $size) : chr($size) . chr($type - $TYPE{map});
}

# A hashref is a map, an arrayref an array, [ uint16 => 24 ] (a ref to an
# array) an unsigned integer of that type, anything else a UTF-8 string.
sub _encode {
	my $value = shift;
	if(ref($value) eq 'HASH') {
		return _control($TYPE{map}, scalar(keys %{$value})) .
			join('', map { _encode($_) . _encode($value->{$_}) } sort keys %{$value});
	}
	if(ref($value) eq 'ARRAY') {
		return _control($TYPE{array}, scalar(@{$value})) . join('', map { _encode($_) } @{$value});
	}
	if(ref($value) eq 'REF') {
		my ($type, $n) = @{${$value}};
		my $bytes = '';
		while($n) {
			$bytes = chr($n & 0xff) . $bytes;
			$n >>= 8;
		}
		return _control($TYPE{$type}, length($bytes)) . $bytes;
	}
	return _control($TYPE{utf8}, length($value)) . $value;
}

sub _write_mmdb {
	my ($file, $networks, $type) = @_;

	my @nodes = ([undef, undef]);
	my $data = '';
	for my $net (sort keys %{$networks}) {
		my ($ip, $len) = split m{/}, $net;
		my $bits = unpack('B32', pack('C4', split(/\./, $ip)));
		my $offset = length($data);
		$data .= _encode($networks->{$net});
		my $node = 0;
		for my $i (0 .. $len - 1) {
			my $bit = substr($bits, $i, 1);
			if($i == $len - 1) {
				$nodes[$node][$bit] = { data => $offset };
				last;
			}
			unless(defined($nodes[$node][$bit])) {
				push @nodes, [undef, undef];
				$nodes[$node][$bit] = $#nodes;
			}
			$node = $nodes[$node][$bit];
		}
	}

	# A record is a node number, node_count for "no data", or a data offset
	my $count = scalar(@nodes);
	my $tree = '';
	for my $node (@nodes) {
		for my $r (@{$node}) {
			my $v = !defined($r) ? $count : ref($r) ? $count + length($SEPARATOR) + $r->{data} : $r;
			$tree .= substr(pack('N', $v), 4 - $RECORD_BYTES);
		}
	}

	my $metadata = _encode({
		node_count                  => \[ uint32 => $count ],
		record_size                 => \[ uint16 => $RECORD_BYTES * 8 ],
		ip_version                  => \[ uint16 => 4 ],
		database_type               => $type,
		languages                   => [ 'en' ],
		binary_format_major_version => \[ uint16 => 2 ],
		binary_format_minor_version => \[ uint16 => 0 ],
		build_epoch                 => \[ uint64 => 1_700_000_000 ],
		description                 => { en => 'CGI::Lingua test database' },
	});

	open(my $fh, '>:raw', $file) or die "$file: $!";
	print {$fh} $tree, $SEPARATOR, $data, $METADATA_MARKER, $metadata;
	close($fh) or die "$file: $!";
	return $file;
}

my $DIR = File::Temp::tempdir(CLEANUP => 1);
my $CITY = _write_mmdb("$DIR/GeoLite2-City.mmdb", \%NETWORKS, 'GeoLite2-City');
my $CORRUPT = "$DIR/GeoLite2-Country.mmdb";
{
	open(my $fh, '>', $CORRUPT) or die "$CORRUPT: $!";
	print {$fh} 'not a MaxMind database';
	close($fh) or die "$CORRUPT: $!";
}

# -- Helpers -------------------------------------------------------------------

{
	package Spy::Logger;
	sub new { return bless { calls => [] }, shift }
	for my $level (qw(debug info notice trace warn error)) {
		no strict 'refs';
		*{$level} = sub { push @{$_[0]{calls}}, [$level, $_[1]] };
	}
	sub messages {
		my ($self, $level) = @_;
		return map { $_->[1] } grep { $_->[0] eq $level } @{$self->{calls}};
	}

	# Local databases that must not answer unless a test says so
	package Fake::Source;
	sub new { my ($c, %a) = @_; return bless { %a }, $c }
	sub inet_atocc { return $_[0]{country} }	# IP::Country::Fast
	sub time_zone { return $_[0]{zone} }	# Geo::IP
}

# Make a require of each module in @hidden fail while $code runs, so the
# readers after them in @READERS are used.
sub _with_hidden {
	my ($hidden, $code) = @_;
	my %file = map { (my $f = "$_.pm") =~ s{::}{/}g; ($f => 1) } @{$hidden};
	delete local @INC{keys %file};
	local @INC = (sub { die "hidden by the test\n" if $file{$_[1]}; return }, @INC);
	return $code->();
}

# Run $code once for each installed reader, with the readers before it hidden
sub _each_reader {
	my $code = shift;
	for my $i (0 .. $#READERS) {
		my $reader = $READERS[$i];
		next unless grep { $_ eq $reader } @INSTALLED;
		subtest "with $reader" => sub {
			_with_hidden([ @READERS[0 .. $i - 1] ], sub { $code->($reader) });
		};
	}
}

# An object for $ip whose only local source is the .mmdb file(s) given
sub _obj {
	my ($ip, %args) = @_;
	local $ENV{REMOTE_ADDR} = $ip;
	my $l = CGI::Lingua->new(supported => ['en'], dont_use_ip => 1, %args);
	$l->{_have_ipcountry} = $l->{_have_geoip} = $l->{_have_geoipfree} = $GEO_ABSENT;
	my $spy = Spy::Logger->new();
	$l->{logger} = $spy;
	return ($l, $spy);
}

no warnings 'once';
local @CGI::Lingua::GEOIP2_MMDB = ($CITY);

# -- Tests ----------------------------------------------------------------------

subtest 'country: the GeoIP2 database answers in lower case' => sub {
	_each_reader(sub {
		my $reader = shift;
		local %ENV = (REMOTE_ADDR => $IP{GB});
		my ($l, $spy) = _obj($IP{GB});
		is($l->country(), 'gb', 'gb');
		is($l->{_have_mmdb}, $GEO_PRESENT, 'database in use');
		like(ref($l->{_mmdb}), qr/^\Q$reader\E(?:::|\z)/, "read by $reader");	# MaxMind::DB::Reader gives a ::PP or ::XS object
		is_deeply([ $spy->messages('warn') ], [], 'no warnings');
	});
};

subtest 'country: hk is returned as cn, as for every other source' => sub {
	_each_reader(sub {
		local %ENV = (REMOTE_ADDR => $IP{HK});
		my ($l) = _obj($IP{HK});
		is($l->country(), 'cn', 'cn');
	});
};

subtest 'country: the database is tried before IP::Country' => sub {
	_each_reader(sub {
		local %ENV = (REMOTE_ADDR => $IP{GB});
		my ($l) = _obj($IP{GB});
		$l->{_have_ipcountry} = $GEO_PRESENT;
		$l->{_ipcountry}      = Fake::Source->new(country => 'FR');
		is($l->country(), 'gb', 'database answer, not IP::Country');
	});
};

subtest 'country: falls through when the database has no answer' => sub {
	_each_reader(sub {
		for my $ip (@IP{qw(MISSING HOSTILE BADTYPE V6)}) {
			local %ENV = (REMOTE_ADDR => $ip);
			my ($l, $spy) = _obj($ip);
			$l->{_have_ipcountry} = $GEO_PRESENT;
			$l->{_ipcountry}      = Fake::Source->new(country => 'FR');
			my $cc;
			lives_ok { $cc = $l->country() } "lives for $ip";
			is($cc, 'fr', "IP::Country answers for $ip");
			is_deeply([ $spy->messages('warn') ], [], 'no warnings');
		}
	});
};

subtest 'country: the answer from the database is cached' => sub {
	_each_reader(sub {
		local %ENV = (REMOTE_ADDR => $IP{GB});
		my $cache = CHI->new(driver => 'Memory', global => 0);
		my ($l) = _obj($IP{GB}, cache => $cache);
		is($l->country(), 'gb', 'gb');
		is($cache->get("${CACHE_NS}country:$IP{GB}"), 'gb', 'stored under the country key');
	});
};

subtest 'time_zone: a City database gives the zone' => sub {
	_each_reader(sub {
		local %ENV = (REMOTE_ADDR => $IP{GB});
		my ($l, $spy) = _obj($IP{GB});
		$l->{_have_geoip} = $GEO_PRESENT;
		$l->{_geoip}      = Fake::Source->new(zone => 'Europe/Paris');
		is($l->time_zone(), 'Europe/London', 'zone from the database, before Geo::IP');
		is_deeply([ $spy->messages('warn') ], [], 'no warnings');
	});
};

subtest 'time_zone: no zone in the record falls through to Geo::IP' => sub {
	_each_reader(sub {
		local %ENV = (REMOTE_ADDR => $IP{US});
		my ($l) = _obj($IP{US});
		$l->{_have_geoip} = $GEO_PRESENT;
		$l->{_geoip}      = Fake::Source->new(zone => 'America/New_York');
		is($l->time_zone(), 'America/New_York', 'Geo::IP answers');

		local $ENV{REMOTE_ADDR} = $IP{BADTYPE};
		($l) = _obj($IP{BADTYPE});
		$l->{_have_geoip} = $GEO_PRESENT;
		$l->{_geoip}      = Fake::Source->new(zone => 'America/New_York');
		is($l->time_zone(), 'America/New_York', 'a location that is not a map is ignored');
	});
};

subtest 'time_zone: a hostile zone in the database is discarded' => sub {
	_each_reader(sub {
		local %ENV = (REMOTE_ADDR => $IP{HOSTILE});
		my ($l, $spy) = _obj($IP{HOSTILE});
		my $tz;
		lives_ok { $tz = $l->time_zone() } 'lives';
		is($tz, undef, 'undef');
		ok((grep { /^Discarding malformed timezone 'Europe\/London<script>'$/ } $spy->messages('warn')), 'discarded with a warning');
	});
};

subtest 'a corrupt database is skipped with a warning' => sub {
	local @CGI::Lingua::GEOIP2_MMDB = ($CORRUPT, $CITY);	# the first readable file is used, even if bad
	local %ENV = (REMOTE_ADDR => $IP{GB});
	my ($l, $spy) = _obj($IP{GB});
	$l->{_have_ipcountry} = $GEO_PRESENT;
	$l->{_ipcountry}      = Fake::Source->new(country => 'FR');
	local $@ = 'caller-owned value';
	my $cc;
	lives_ok { $cc = $l->country() } 'lives';
	is($cc, 'fr', 'IP::Country answers instead');
	is($l->{_have_mmdb}, $GEO_ABSENT, 'database not used');
	is_deeply(
		[ $spy->messages('warn') ],
		[ "Can't open $CORRUPT with IP::Geolocation::MMDB or MaxMind::DB::Reader; not using it" ],
		'one exact warning, without the reader\'s stack trace'
	);

	# The answer is remembered: no second warning
	local $ENV{REMOTE_ADDR} = $IP{US};
	delete $l->{_country};
	$l->country();
	is(scalar(() = $spy->messages('warn')), 1, 'not reopened on the next look-up');
};

subtest 'country() and time_zone() leave $@ and $! alone' => sub {
	local %ENV = (REMOTE_ADDR => $IP{V6});	# IP::Geolocation::MMDB dies on IPv6 in an IPv4 database
	my ($l) = _obj($IP{V6});
	local $@ = 'caller error';
	local $! = 2;
	my $errno = $! + 0;
	$l->country();
	$l->time_zone();
	is($@, 'caller error', '$@');
	is($! + 0, $errno, '$!');
};

_restore();
Test::Mockingbird::restore_all();

done_testing();
