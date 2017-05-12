use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Carp;

$SIG{__DIE__} = sub { confess @_ };

BEGIN { plan tests => 7 }

use_ok('Cache::File');

my $tempdir = tempdir(CLEANUP => 1);

my %hash;
my $cache = tie %hash, 'Cache::File', { cache_root => $tempdir };

my $key = 'testkey';

$hash{$key} = 'test data';

ok($cache->exists($key), 'store worked');
is($hash{$key}, 'test data', 'fetch worked');

delete $hash{$key};

ok(!$cache->exists($key), 'delete worked');


{
	sub load_func {
		return "You requested ".$_[0]->key();
	}

	my %hash;
	my $cache = tie %hash, 'Cache::File',
		{ cache_root => $tempdir, load_callback => \&load_func };

	my $key = 'testkey';

	ok(!$cache->exists($key), 'key doesnt exist');
	is($hash{$key}, "You requested $key", 'load worked');

	delete $hash{$key};

	ok(!$cache->exists($key), 'delete worked');
}
