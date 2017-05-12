#!perl -T

use Test::More tests => 269;
use Carp();

our $w = '';
no warnings 'redefine';
local *Carp::carp = sub { $main::w .= @_ };

BEGIN {
	use_ok( 'Cache::Benchmark' );
}
{
	 package Fukurama::Testcache;
	 sub new {
	 	my $s = bless({}, $_[0]);
	 	$s->{cache} = {};
	 	$s->{purge} = 0;
	 	$s->{get} = {};
	 	$s->{set} = {};
	 	return $s;
	 }
	 sub set {
	 	my $s = $_[0];
	 	my $k = $_[1];
	 	$s->{cache}->{$k} = $_[2];
	 	++$s->{set}->{$k};
	 }
	 sub get {
	 	my $s = $_[0];
	 	my $k = $_[1];
	 	++$s->{get}->{$k};
	 	$s->{cache}->{$k};
	 }
	 sub purge {
	 	my $s = $_[0];
	 	++$s->{purge};
	 	return 1;
	 }
}

my $cache = new Fukurama::Testcache();
is($cache->set(2, 3), 1, 'set');
is($cache->get(2), 3, 'get');
is($cache->purge(), 1, 'purge');

my $new_cache = new Fukurama::Testcache();
my $test = new Cache::Benchmark();

$w = '';
#my $w = '';
#is(close(STDERR), 1, 'close STDERR');
#is(open(STDERR, ">", \$w), 1, 'reopen STDERR');

is($test->init( abc => 1), 0, 'init with unknown parameters');
is(length($w) > 0, 1, 'warnings after failed init');

$w = '';
#is(close(STDERR), 1, 'close STDERR');
#is(open(STDERR, ">", \$w), 1, 'reopen STDERR');

is($test->init( keys => 100, access_counter => 1000, test_type => 'plain', min_key_length => 5 ), 1, 'init cache');
is($test->run($new_cache, 1), 1, 'run test');

my $set = $new_cache->{set};
is(scalar(keys(%$set)), 100, 'all is set');
foreach(0..99) {
	is($set->{sprintf("%05d", $_)}, 1, 'check single set');
}

my $get = $new_cache->{get};
is(scalar(keys(%$get)), 100, 'all is get');
foreach(0..99) {
	is($get->{sprintf("%05d", $_)}, 9, 'check single get');
}

is($new_cache->{purge}, 1000, 'check purge');


is($w, '', 'check warnings');

$new_cache = new Fukurama::Testcache();
is($test->init( keys => 10, access_counter => 100_000, test_type => 'random', min_key_length => 5 ), 1, 'init cache');
is($test->run($new_cache, 0), 1, 'run test');

$set = $new_cache->{set};
is(scalar(keys(%$set)), 10, 'all is set');
foreach(0..9) {
	is($set->{sprintf("%05d", $_)}, 1, 'check single set');
}

$get = $new_cache->{get};
is(scalar(keys(%$get)), 10, 'all is get');
foreach(0..9) {
	is($get->{sprintf("%05d", $_)} > 0, 1, 'check single get');
}

is($new_cache->{purge}, 0, 'check purge');


is($w, '', 'check warnings');

$new_cache = new Fukurama::Testcache();
is($test->init( keys => 10, access_counter => 1000, test_type => 'weighted', min_key_length => 5, weighted_key_config => { 10 => 100_000 } ), 1, 'init cache');

is($test->run($new_cache, 0), 1, 'run test');


$get = $new_cache->{get};
is($get->{"00000"} > 500, 1, 'check heigh weighted get');
my $two = exists($get->{"00001"}) ? $get->{"00001"} : 0;
is($two < 500, 1, 'check low weighted get');

is($w, '', 'check warnings');

#->eigene accesslist testen
$new_cache = new Fukurama::Testcache();
is($test->init( accesslist => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9] ), 1, 'init cache');

is($test->run($new_cache, 1), 1, 'run test');

$set = $new_cache->{set};
is(scalar(keys(%$set)), 10, 'all is set');
foreach(0..9) {
	is($set->{$_}, 1, 'check single set');
}

$get = $new_cache->{get};
is(scalar(keys(%$get)), 10, 'all is get');
foreach(0..9) {
	is($get->{$_}, 1, 'check single get');
}

is($new_cache->{purge}, 20, 'check purge');

is($w, '', 'check warnings');
