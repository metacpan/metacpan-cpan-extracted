#! perl

use strict;
use warnings;

use Test::More;

use Crypt::Credentials;
use File::Slurper 'read_binary';
use File::Temp 'tempdir';

my $dir = tempdir(CLEANUP => 1);

my $credentials = Crypt::Credentials->new(
	keys => [ '0123456789ABCDEF' ],
	dir  => $dir,
);

is_deeply [$credentials->list], [], 'No entries yet';

my $original = { password => 'pass123' };
my $written = eval { $credentials->put_yaml('first', $original); 1 };
ok $written, 'Entry was written';

my $back = eval { $credentials->get_yaml('first') };
is_deeply($back, $original, 'Values roundtrip');

is_deeply [$credentials->list], ['first'], 'One entry';

my $file = File::Spec->catdir($dir, 'first.yml.enc');
ok -B $file, 'File is binary';

my $raw_before = read_binary($file);

$credentials->recode('FEDCBA9876543210');

my $raw_after = read_binary($file);

isnt($raw_after, $raw_before, 'File changed on recode');

my $credentials2 = Crypt::Credentials->new(
	keys => [ '0123456789ABCDEF', 'FEDCBA9876543210' ],
	dir  => $dir,
);

my $back2 = eval { $credentials2->get_yaml('first') };
is_deeply($back2, $original, 'Values roundtrip again');

done_testing;
