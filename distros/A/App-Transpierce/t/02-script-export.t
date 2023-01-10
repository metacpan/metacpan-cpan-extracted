use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Script;
use File::Path qw(rmtree);
use File::Copy qw(copy);

use lib 't/lib';
use FileTests;

# Keep this commented out to avoid wide character print warnings. The testing
# code seems to work properly anyway
# use utf8;

use constant SCRIPT_PATH => 'bin/transpierce';
use constant TESTDIR => 't/testdir';

my $output;

rmtree TESTDIR;
mkdir TESTDIR;

script_runs(
	[SCRIPT_PATH, '--self-export', TESTDIR], {
		stdout => \$output,
	},
	'script runs ok'
);

# no output in normal generation
ok !$output, 'output ok';

my %compare = (
	TESTDIR . '/transpierce' => SCRIPT_PATH,
);

for my $key (keys %compare) {
	my $value = $compare{$key};

	files_content_same($key, $value);
}

rmtree TESTDIR;

done_testing;

