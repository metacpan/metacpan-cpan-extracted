#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Test::More tests => 41;

use_ok('App::Hashl');

my $IGNORED = '// ignored';

my $hashl = App::Hashl->new();
isa_ok($hashl, 'App::Hashl');

is($hashl->read_size(), (2 ** 20) * 4, 'default read size');

$hashl = App::Hashl->new(read_size => 512);

is($hashl->read_size(), 512, 'Custom read size set');

is($hashl->si_size(1023), '1023.0 ', 'si_size 1023 = 1023');
is($hashl->si_size(1024), '   1.0k', 'si_size 1024 = 1k');
is($hashl->si_size(2048), '   2.0k', 'si_size 2048 = 2k');

is($hashl->si_size(1024 * 1024), '   1.0M', 'si_size 1024^2 = 1M');
is($hashl->si_size(0),   'infinite', 'si_size    0 = infinite');


is($hashl->hash_in_db('123'), undef, 'hash not in db');
is($hashl->file_in_db('t/in/4'), undef, 'file not in db');
is_deeply([$hashl->files()], [], 'no files in empty db');
is_deeply([$hashl->ignored()], [], 'no ignored files in empty db');

my $test_hash = $hashl->hash_file('t/in/4');
my ($test_size, $test_mtime) = (stat('t/in/4'))[7,9];
ok($hashl->add_file(
		file => 't/in/4',
		path => 't/in/4',
	),
	'Add new file'
);
is_deeply($hashl->file('t/in/4'),
	{
		hash => $test_hash,
		size => $test_size,
		mtime => $test_mtime,
	},
	'hashl->file okay'
);

ok($hashl->file_in_db('t/in/4'), 'file is now in db');
ok($hashl->hash_in_db($test_hash), 'hash is in db');

ok($hashl->add_file(
		file => 't/in/1k',
		path => 't/in/1k',
	),
	'Add another file'
);
is_deeply([sort $hashl->files()], [qw[t/in/1k t/in/4]], 'Both files in list');
ok($hashl->file_in_db('t/in/1k'), 'file in db');
ok($hashl->file_in_db('t/in/4'), 'other file in db');

ok($hashl->ignore('t/in/4', 't/in/4'), 'ignore file');
is($hashl->file_in_db('t/in/4'), $IGNORED, 'file no longer in db');

is_deeply([$hashl->ignored()], [$test_hash], 'file is ignored');

ok($hashl->ignore('t/in/1k', 't/in/1k'), 'ignore other file as well');
is($hashl->file_in_db('t/in/1k'), $IGNORED, 'file ignored');

ok($hashl->save('t/in/hashl.db'), 'save db');

undef $hashl;

$hashl = App::Hashl->new_from_file('t/in/hashl.db');
isa_ok($hashl, 'App::Hashl');
unlink('t/in/hashl.db');

is($hashl->file_in_db('t/in/4'), $IGNORED, 'file still ignored');
is_deeply([$hashl->files()], [], 'no files in db');

$hashl->add_file(
	file => 't/in/1k',
	path => 't/in/1k',
);

is_deeply([$hashl->files()], [], 'ignored file not added');

$hashl->unignore($hashl->hash_file('t/in/1k'));
is_deeply([$hashl->ignored()], [$test_hash], 'unignore worked');

ok(
	$hashl->add_file(
		file => 't/in/4',
		path => 't/in/4',
		unignore => 1,
	),
	'Forcefully re-add file to db (unignore => 1)'
);
is_deeply([$hashl->ignored()], [], 'add(unignore => 1) unignore worked');
is_deeply([$hashl->files()], ['t/in/4'], 'add(unignore => 1) add worked');

ok(
	$hashl->add_file(
		file => 't/in/1k',
		path => 't/in/1k',
	),
	'Re-add file to database',
);

ok($hashl->file_in_db('t/in/1k'), 'file in db again');

undef $hashl;

my $hash_512 = App::Hashl->new(read_size =>  512)->hash_file('t/in/1k');
my $hash_1k  = App::Hashl->new(read_size => 1024)->hash_file('t/in/1k');
my $hash_2k  = App::Hashl->new(read_size => 2048)->hash_file('t/in/1k');
my $hash_inf = App::Hashl->new(read_size =>    0)->hash_file('t/in/1k');

my $hash_1k_half = App::Hashl->new()->hash_file('t/in/1k-firsthalf');

is($hash_1k, $hash_2k,
	'Same hash for read_size > filesize and read_size == file_size');
is($hash_1k, $hash_inf,
	'Same hash for read_size == inf and read_size == file_size');
isnt($hash_512, $hash_1k, 'Partial hashing does not hash full file');
is($hash_512, $hash_1k_half, 'Partial hashing produces correct hash');
